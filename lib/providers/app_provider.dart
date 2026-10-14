import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../services/crypto_service.dart';
import '../services/native_security.dart';
import '../services/storage_service.dart';

enum TaskStatus { pending, running, done, failed }
enum AppMode { encrypt, decrypt }

class FileTask {
  final String name;
  final String path;
  final int size;
  TaskStatus status = TaskStatus.pending;
  String message = '';

  FileTask(this.name, this.path, this.size);
}

class AppProvider extends ChangeNotifier {
  AppMode mode = AppMode.encrypt;
  List<FileTask> tasks = [];
  bool busy = false;
  String? outputDirPath;
  List<String> securityIssues = [];

  void setMode(AppMode m) {
    mode = m;
    tasks.clear();
    notifyListeners();
  }

  Future<void> pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res == null) return;
    tasks = res.files
        .where((f) => f.path != null)
        .map((f) => FileTask(f.name, f.path!, f.size))
        .toList();
    notifyListeners();
  }

  void removeTask(FileTask t) {
    tasks.remove(t);
    notifyListeners();
  }

  Future<void> prepareOutputDir() async {
    try {
      final path = await StorageService.getOutputDir();
      outputDirPath = path;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> runAll(String password) async {
    if (tasks.isEmpty || outputDirPath == null || busy) return;
    busy = true;
    notifyListeners();

    for (final t in tasks) {
      t.status = TaskStatus.running;
      t.message = '';
      notifyListeners();

      try {
        if (t.path.isEmpty) throw Exception('ملف غير موجود');
        final input = File(t.path);
        if (!await input.exists()) throw Exception('ملف غير موجود');

        if (mode == AppMode.encrypt) {
          final out = File('$outputDirPath/${t.name}.encf');
          await CryptoService.encryptFile(
            input: input,
            output: out,
            originalName: t.name,
            password: password,
          );
          t.message = 'اتحفظ';
        } else {
          final tmp = File('$outputDirPath/.dec_${DateTime.now().microsecondsSinceEpoch}');
          final name = await CryptoService.decryptFile(
            input: input,
            output: tmp,
            password: password,
          );
          final finalOut = File('$outputDirPath/$name');
          if (await finalOut.exists()) await finalOut.delete();
          await tmp.rename(finalOut.path);
          t.message = '→ $name';
        }
        t.status = TaskStatus.done;
      } catch (e) {
        t.status = TaskStatus.failed;
        var msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.length > 60) msg = '${msg.substring(0, 60)}…';
        t.message = msg;
      }
      notifyListeners();

      // وقفة صغيرة بين الملفات عشان الجهاز مايسخنش
      await Future.delayed(const Duration(milliseconds: 120));
    }

    busy = false;
    notifyListeners();
  }

  Future<void> runSecurityChecks() async {
    securityIssues = await NativeSecurity.runAllChecks();
    notifyListeners();
  }
}
