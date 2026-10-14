import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class _EncryptJob {
  final String inputPath;
  final String outputPath;
  final String originalName;
  final String password;
  _EncryptJob(this.inputPath, this.outputPath, this.originalName, this.password);
}

class _DecryptJob {
  final String inputPath;
  final String outputPath;
  final String password;
  _DecryptJob(this.inputPath, this.outputPath, this.password);
}

class CryptoService {
  static const int _saltLen = 16;
  static const int _ivLen = 12;
  static const int _tagBits = 128;
  static const int _pbkdf2Iterations = 200000;
  static const int _keyBits = 256;

  static Future<void> encryptFile({
    required File input,
    required File output,
    required String originalName,
    required String password,
  }) async {
    // شغل الـ isolate في الخلفية — لا يسخّن الجهاز
    await Isolate.run(() => _encryptSync(
      _EncryptJob(input.path, output.path, originalName, password),
    ));
  }

  static Future<String> decryptFile({
    required File input,
    required File output,
    required String password,
  }) async {
    return await Isolate.run(() => _decryptSync(
      _DecryptJob(input.path, output.path, password),
    ));
  }

  static void _encryptSync(_EncryptJob job) {
    final plain = File(job.inputPath).readAsBytesSync();
    final salt = _randomBytes(_saltLen);
    final iv = _randomBytes(_ivLen);
    final key = _deriveKey(job.password, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), _tagBits, iv, Uint8List(0)));

    final encrypted = cipher.process(plain);

    final nameBytes = Uint8List.fromList(job.originalName.codeUnits);
    if (nameBytes.length > 0xFFFF) throw Exception('اسم الملف طويل جدًا');

    final header = BytesBuilder();
    header.add([0x45, 0x4E, 0x43, 0x46]);
    header.addByte(1);
    header.add(salt);
    header.add(iv);
    header.add([(nameBytes.length >> 8) & 0xFF, nameBytes.length & 0xFF]);
    header.add(nameBytes);
    header.add(encrypted);

    File(job.outputPath).writeAsBytesSync(header.toBytes(), flush: true);
  }

  static String _decryptSync(_DecryptJob job) {
    final bytes = File(job.inputPath).readAsBytesSync();
    if (bytes.length < 4 + 1 + _saltLen + _ivLen + 2 + 16) {
      throw Exception('الملف صغير جدًا');
    }
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'ENCF') {
      throw Exception('الملف ده مش ملف مشفّر بـ SecureVault');
    }
    if (bytes[4] != 1) throw Exception('نسخة غير مدعومة');

    final salt = bytes.sublist(5, 5 + _saltLen);
    final iv = bytes.sublist(5 + _saltLen, 5 + _saltLen + _ivLen);
    final nameLenOff = 5 + _saltLen + _ivLen;
    final nameLen = (bytes[nameLenOff] << 8) | bytes[nameLenOff + 1];
    if (nameLen < 1 || nameLen > 0xFFFF) throw Exception('اسم ملف غير صالح');

    final nameStart = nameLenOff + 2;
    final originalName = String.fromCharCodes(bytes.sublist(nameStart, nameStart + nameLen));
    final ciphertext = bytes.sublist(nameStart + nameLen);

    final key = _deriveKey(job.password, salt);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), _tagBits, iv, Uint8List(0)));

    final plain = cipher.process(ciphertext);
    File(job.outputPath).writeAsBytesSync(plain, flush: true);
    return _sanitize(originalName);
  }

  static final Random _rng = Random.secure();

  static Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyBits ~/ 8));
    return pbkdf2.process(Uint8List.fromList(password.codeUnits));
  }

  static Uint8List _randomBytes(int len) {
    final bytes = Uint8List(len);
    for (var i = 0; i < len; i++) {
      bytes[i] = _rng.nextInt(256);
    }
    return bytes;
  }

  static String _sanitize(String name) {
    final base = name.split('/').last.split('\\').last;
    var clean = base.replaceAll(RegExp(r'[<>:"|?*\x00-\x1F]'), '_').trim();
    if (clean.isEmpty || clean == '.' || clean == '..') {
      clean = 'ملف_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }
}
