import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  const PasswordField({super.key, required this.controller, this.enabled = true});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      style: const TextStyle(color: AppTheme.text),
      decoration: InputDecoration(
        hintText: 'Password (min 8 chars)',
        hintStyle: const TextStyle(color: AppTheme.muted),
        prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.muted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppTheme.muted,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
