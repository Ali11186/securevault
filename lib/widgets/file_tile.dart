import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class FileTile extends StatelessWidget {
  final FileTask task;
  final VoidCallback onRemove;

  const FileTile({super.key, required this.task, required this.onRemove});

  @override
  Widget build(BuildContext context) {
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

    return Slidable(
      key: ValueKey(task.path + task.name),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onRemove(),
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            borderRadius: BorderRadius.circular(14),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _size(task.size) + (task.message.isEmpty ? '' : '  ·  ${task.message}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _size(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
