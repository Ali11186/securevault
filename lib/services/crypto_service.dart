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
  static const int _pbkdf2Iterations = 250000;
  static const int _keyBits = 256;

  // علامة سرية في آخر الملف — مش تجارية
  static const List<int> _magic = [0x56, 0x4C, 0x54, 0x31]; // "VLT1"
  static const int _version = 1;

  static Future<void> encryptFile({
    required File input,
    required File output,
    required String originalName,
    required String password,
  }) async {
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

    final trailer = BytesBuilder();
    trailer.add(salt);
    trailer.add(iv);
    trailer.add([(nameBytes.length >> 8) & 0xFF, nameBytes.length & 0xFF]);
    trailer.add(nameBytes);
    trailer.add([_version]);
    trailer.add(_magic);

    final out = BytesBuilder();
    out.add(encrypted);
    out.add(trailer.toBytes());

    File(job.outputPath).writeAsBytesSync(out.toBytes(), flush: true);
  }

  static String _decryptSync(_DecryptJob job) {
    final bytes = File(job.inputPath).readAsBytesSync();

    if (bytes.length < 16 + _saltLen + _ivLen + 2 + 1 + 1 + 4) {
      throw Exception('الملف صغير جدًا أو تالف');
    }

    final magicStart = bytes.length - 4;
    for (var i = 0; i < 4; i++) {
      if (bytes[magicStart + i] != _magic[i]) {
        throw Exception('الملف ده مش ملف مشفّر صالح');
      }
    }

    var cursor = bytes.length - 4;
    cursor -= 1;
    if (bytes[cursor] != _version) throw Exception('نسخة غير مدعومة');

    cursor -= 2;
    final nameLen = (bytes[cursor] << 8) | bytes[cursor + 1];
    if (nameLen < 1 || nameLen > 0xFFFF) throw Exception('اسم ملف غير صالح');

    cursor -= nameLen;
    final originalName = String.fromCharCodes(bytes.sublist(cursor, cursor + nameLen));

    cursor -= _ivLen;
    final iv = bytes.sublist(cursor, cursor + _ivLen);

    cursor -= _saltLen;
    final salt = bytes.sublist(cursor, cursor + _saltLen);

    final ciphertext = bytes.sublist(0, cursor);

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
