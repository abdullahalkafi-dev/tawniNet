import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../values/app_colors.dart';
import '../values/app_styles.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool isPassword;
  final bool? isVisible;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.isPassword = false,
    this.isVisible,
    this.onToggleVisibility,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !(isVisible ?? false),
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onChanged: onChanged,
          maxLines: isPassword ? 1 : maxLines,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            filled: true,
            fillColor: context.inputFillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefix: prefix,
            prefixIcon: prefixIcon,
            suffix: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isVisible ?? false) ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.textSecondaryColor,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
