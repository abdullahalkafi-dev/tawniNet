import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../values/app_colors.dart';
import '../values/app_styles.dart';

class MoroccoPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const MoroccoPhoneField({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? 'Moroccan Mobile Phone',
          style: AppStyles.bodyMediumOf(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null ? Colors.redAccent : context.borderSecondary,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // 🇲🇦 Country Code Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: context.cardColor.withOpacity(0.4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇲🇦', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '+212',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 22,
                      color: context.borderSecondary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
              // Phone Input Field
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimaryColor,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '6 12 34 56 78',
                    hintStyle: AppStyles.bodyMedium.copyWith(
                      color: context.textHintColor,
                      letterSpacing: 1.2,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.mark_chat_unread_outlined, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              'WhatsApp OTP verification (06 / 07 mobile)',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            ),
          ],
        ),
      ],
    );
  }
}
