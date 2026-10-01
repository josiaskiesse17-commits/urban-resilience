import 'package:flutter/material.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';

class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefix;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.prefix,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppPalette.textDark,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppPalette.textDark,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            prefixIcon: _prefix,
            prefixIconConstraints: const BoxConstraints(
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

  Widget? get _prefix {
    final icon = prefix ??
        (prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 19, color: AppPalette.primary));

    if (icon == null) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: icon,
      ),
    );
  }
}
