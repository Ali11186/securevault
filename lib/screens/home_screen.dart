import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/file_tile.dart';
import '../widgets/password_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pw = TextEditingController();

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
                  child: p.tasks.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: p.tasks.length,
                        itemBuilder: (_, i) => FileTile(
                          task: p.tasks[i],
                          onRemove: () => p.removeTask(p.tasks[i]),
                        ),
                      ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accent2]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('SecureVault',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 18),
          _segmented(p),
          const SizedBox(height: 14),
          if (p.securityIssues.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Environment: ${p.securityIssues.join(", ")}',
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                )),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _segmented(AppProvider p) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segBtn('Encrypt', AppMode.encrypt, p),
          _segBtn('Decrypt', AppMode.decrypt, p),
        ],
      ),
    );
  }

  Widget _segBtn(String label, AppMode m, AppProvider p) {
    final sel = p.mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: p.busy ? null : () => p.setMode(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: sel
              ? const LinearGradient(colors: [AppTheme.accent, AppTheme.accent2])
              : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppTheme.muted.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No files yet', style: TextStyle(color: AppTheme.muted.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text('Tap "Pick files" to start',
            style: TextStyle(color: AppTheme.muted.withOpacity(0.5), fontSize: 12)),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _footer(AppProvider p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        children: [
          PasswordField(controller: _pw, enabled: !p.busy),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.busy ? null : () => p.pickFiles(),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Pick files'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppTheme.muted, width: 0.5),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Icon(p.mode == AppMode.encrypt ? Icons.lock : Icons.lock_open, size: 18),
                  label: Text(p.busy
                    ? 'Working...'
                    : (p.mode == AppMode.encrypt ? 'Encrypt' : 'Decrypt')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: p.mode == AppMode.encrypt
                      ? AppTheme.accent
                      : AppTheme.accent2,
                  ),
                ),
              ),
            ],
          ),
          if (p.outputDirPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Output: SecureVault/',
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _run(AppProvider p) async {
    final pw = _pw.text;
    if (pw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')));
      return;
    }
    await p.runAll(pw);
    if (!mounted) return;
    final ok = p.tasks.where((t) => t.status == TaskStatus.done).length;
    final fail = p.tasks.where((t) => t.status == TaskStatus.failed).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Done. $ok ok, $fail failed.')));
  }
}
