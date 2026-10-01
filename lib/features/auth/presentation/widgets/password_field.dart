import 'package:flutter/material.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_icon.dart';

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    this.label = 'Mot de passe',
    required this.controller,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppPalette.textDark,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppPalette.textDark,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AuthIcon(
                  asset: 'assets/icons/lock-keyhole.svg',
                  color: AppPalette.primary,
                  size: 18,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              maxWidth: 40,
              minHeight: 52,
              maxHeight: 52,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureText = !_obscureText),
              child: Align(
                alignment: Alignment.center,
                child: AuthIcon(
                  asset: _obscureText
                      ? 'assets/icons/eye-off.svg'
                      : 'assets/icons/eye.svg',
                  color: AppPalette.textMuted,
                  size: 18,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              maxWidth: 40,
              minHeight: 52,
              maxHeight: 52,
            ),
          ),
        ),
      ],
    );
  }
}
