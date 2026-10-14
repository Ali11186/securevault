import 'dart:io';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class CryptoService {
  static const int _saltLen = 16;
  static const int _ivLen = 12;
  static const int _tagBits = 128;
  static const int _pbkdf2Iterations = 200000;
  static const int _keyBits = 256;

  static final SecureRandom _rng = SecureRandom();

  static Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyBits ~/ 8));
    return pbkdf2.process(Uint8List.fromList(password.codeUnits));
  }

  static Uint8List _randomBytes(int len) {
    final bytes = Uint8List(len);
    _rng.nextBytes(bytes);
    return bytes;
  }

  static Future<void> encryptFile({
    required File input,
    required File output,
    required String originalName,
    required String password,
  }) async {
    final plain = await input.readAsBytes();
    final salt = _randomBytes(_saltLen);
    final iv = _randomBytes(_ivLen);
    final key = _deriveKey(password, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), _tagBits, iv, Uint8List(0)));

    final encrypted = cipher.process(Uint8List.fromList(plain));

    final nameBytes = Uint8List.fromList(originalName.codeUnits);
    if (nameBytes.length > 0xFFFF) throw Exception('File name too long');

    final header = BytesBuilder();
    header.add([0x45, 0x4E, 0x43, 0x46]);            // "ENCF"
    header.addByte(1);                                // version
    header.add(salt);
    header.add(iv);
    header.add([(nameBytes.length >> 8) & 0xFF, nameBytes.length & 0xFF]);
    header.add(nameBytes);
    header.add(encrypted);

    await output.writeAsBytes(header.toBytes(), flush: true);
  }

  static Future<String> decryptFile({
    required File input,
    required File output,
    required String password,
  }) async {
    final bytes = await input.readAsBytes();
    if (bytes.length < 4 + 1 + _saltLen + _ivLen + 2 + 16) {
      throw Exception('File too small');
    }
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'ENCF') {
      throw Exception('Not an ENCF file');
    }
    if (bytes[4] != 1) throw Exception('Unsupported version');

    final salt = bytes.sublist(5, 5 + _saltLen);
    final iv = bytes.sublist(5 + _saltLen, 5 + _saltLen + _ivLen);
    final nameLenOff = 5 + _saltLen + _ivLen;
    final nameLen = (bytes[nameLenOff] << 8) | bytes[nameLenOff + 1];
    if (nameLen < 1 || nameLen > 0xFFFF) throw Exception('Bad name length');

    final nameStart = nameLenOff + 2;
    final originalName = String.fromCharCodes(bytes.sublist(nameStart, nameStart + nameLen));
    final ciphertext = bytes.sublist(nameStart + nameLen);

    final key = _deriveKey(password, salt);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), _tagBits, iv, Uint8List(0)));

    final plain = cipher.process(ciphertext);
    await output.writeAsBytes(plain, flush: true);
    return _sanitize(originalName);
  }

  static String _sanitize(String name) {
    final base = name.split('/').last.split('\\').last;
    var clean = base.replaceAll(RegExp(r'[<>:"|?*\x00-\x1F]'), '_').trim();
    if (clean.isEmpty || clean == '.' || clean == '..') {
      clean = 'decrypted_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }
}
