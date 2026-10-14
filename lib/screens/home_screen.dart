import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pw = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, p, _) {
            return Column(
              children: [
                _header(p),
                Expanded(
                  child: p.tasks.isEmpty ? _empty() : _list(p),
                ),
                _footer(p),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent2],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الخزنة',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  Text('حماية ملفاتك بتشفير AES-256',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted.withOpacity(0.9))),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08),
          const SizedBox(height: 20),
          _segmented(p),
          if (p.securityIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _securityBanner(p.securityIssues),
          ],
        ],
      ),
    );
  }

  Widget _segmented(AppProvider p) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _segBtn('تشفير', Icons.lock, AppMode.encrypt, p),
          _segBtn('فك التشفير', Icons.lock_open, AppMode.decrypt, p),
        ],
      ),
    );
  }

  Widget _segBtn(String label, IconData icon, AppMode m, AppProvider p) {
    final sel = p.mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: p.busy ? null : () => p.setMode(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent2],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: sel ? Colors.white : AppTheme.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? Colors.white : AppTheme.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _securityBanner(List<String> issues) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warn.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warn.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.warn, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'تنبيه أمني: ${issues.join("، ")}',
            style: const TextStyle(color: AppTheme.warn, fontSize: 12),
          )),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.folder_open_outlined,
              size: 48, color: AppTheme.muted.withOpacity(0.6)),
          ),
          const SizedBox(height: 18),
          const Text('مفيش ملفات لسه',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('اضغط "اختر ملفات" عشان تبدأ',
            style: TextStyle(color: AppTheme.muted.withOpacity(0.7), fontSize: 13)),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _list(AppProvider p) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: p.tasks.length,
      itemBuilder: (_, i) => _fileTile(p.tasks[i], p),
    );
  }

  Widget _fileTile(FileTask task, AppProvider p) {
    final color = switch (task.status) {
      TaskStatus.pending => AppTheme.muted,
      TaskStatus.running => AppTheme.accent,
      TaskStatus.done    => AppTheme.success,
      TaskStatus.failed  => AppTheme.danger,
    };
    final icon = switch (task.status) {
      TaskStatus.pending => Icons.insert_drive_file_outlined,
      TaskStatus.running => Icons.hourglass_top_rounded,
      TaskStatus.done    => Icons.check_circle_outline,
      TaskStatus.failed  => Icons.error_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  _size(task.size) + (task.message.isEmpty ? '' : '  ·  ${task.message}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.muted.withOpacity(0.85), fontSize: 11),
                ),
              ],
            ),
          ),
          if (!p.busy)
            IconButton(
              onPressed: () => p.removeTask(task),
              icon: const Icon(Icons.close, size: 18, color: AppTheme.muted),
            ),
        ],
      ),
    );
  }

  Widget _footer(AppProvider p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _pw,
            obscureText: _obscure,
            enabled: !p.busy,
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: AppTheme.text),
            decoration: InputDecoration(
              hintText: 'كلمة السر (8 حروف على الأقل)',
              hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 13),
              filled: true,
              fillColor: AppTheme.surface,
              prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.muted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.muted, size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.busy ? null : () => p.pickFiles(),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('اختر ملفات'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppTheme.muted.withOpacity(0.4), width: 1),
                    foregroundColor: AppTheme.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: (!p.busy && p.tasks.isNotEmpty) ? () => _run(p) : null,
                  icon: p.busy
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(p.mode == AppMode.encrypt ? Icons.lock : Icons.lock_open, size: 18),
                  label: Text(
                    p.busy
                        ? 'جاري العمل…'
                        : (p.mode == AppMode.encrypt ? 'شفّر' : 'افك التشفير'),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: p.mode == AppMode.encrypt ? AppTheme.accent : AppTheme.accent2,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (p.outputDirPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_outlined, size: 13, color: AppTheme.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'المجلد: ${_shortPath(p.outputDirPath!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _shortPath(String p) {
    return p.replaceFirst('/storage/emulated/0/', '');
  }

  static String _size(int b) {
    if (b < 1024) return '$b بايت';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} ك.ب';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} م.ب';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} ج.ب';
  }

  Future<void> _run(AppProvider p) async {
    final pw = _pw.text;
    if (pw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة السر لازم 8 حروف على الأقل')));
      return;
    }
    await p.runAll(pw);
    if (!mounted) return;
    final ok = p.tasks.where((t) => t.status == TaskStatus.done).length;
    final fail = p.tasks.where((t) => t.status == TaskStatus.failed).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خلصنا. $ok ناجح، $fail فشل')));
  }
}
