import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _key = 'output_dir';
  static const String folderName = 'Ali';

  /// بترجّع المجلد المحفوظ
  static Future<String?> getOutputDir() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && await Directory(saved).exists()) return saved;

    // الافتراضي: Documents/Ali
    try {
      final docs = Directory('/storage/emulated/0/Documents');
      if (await docs.exists()) {
        final dir = Directory('${docs.path}/$folderName');
        if (!await dir.exists()) await dir.create(recursive: true);
        await prefs.setString(_key, dir.path);
        return dir.path;
      }
    } catch (_) {}

    return null;
  }
}
