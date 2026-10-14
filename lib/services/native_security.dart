import 'package:flutter/services.dart';

class NativeSecurity {
  static const _channel = MethodChannel('securevault/security');

  /// اكتب هنا هاش الـ signature بعد أول build.
  /// سيبها فاضية في أول build عشان تولّد الـ APK، بعدين خد الهاش من اللوج وحطه هنا.
  static const String expectedSignatureHash = '';

  static Future<String> getSignatureHash() async {
    try {
      return await _channel.invokeMethod<String>('getSignatureHash') ?? '';
    } catch (_) { return ''; }
  }

  static Future<bool> isSignatureValid() async {
    if (expectedSignatureHash.isEmpty) return true;
    try {
      final actual = await getSignatureHash();
      return actual == expectedSignatureHash;
    } catch (_) { return false; }
  }

  static Future<bool> isDebuggerAttached() async {
    try { return await _channel.invokeMethod<bool>('checkDebugger') ?? false; }
    catch (_) { return false; }
  }

  static Future<bool> isFridaPresent() async {
    try { return await _channel.invokeMethod<bool>('checkFrida') ?? false; }
    catch (_) { return false; }
  }

  static Future<bool> isRooted() async {
    try { return await _channel.invokeMethod<bool>('checkRoot') ?? false; }
    catch (_) { return false; }
  }

  static Future<List<String>> runAllChecks() async {
    final issues = <String>[];
    if (!await isSignatureValid()) issues.add('signature');
    if (await isDebuggerAttached()) issues.add('debugger');
    if (await isFridaPresent()) issues.add('frida');
    if (await isRooted()) issues.add('root');
    return issues;
  }
}
