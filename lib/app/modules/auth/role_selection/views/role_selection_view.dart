import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/role_selection_controller.dart';
import '../../../../core/values/app_assets.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/theme_toggle_icon_button.dart';

class RoleSelectionView extends GetView<RoleSelectionController> {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.topRight,
                          child: ThemeToggleIconButton(),
                        ),
                        const SizedBox(height: 12),
                        Image.asset(
                          AppAssets.selectRole,
                          height: constraints.maxHeight * 0.32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 30),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppStyles.h2.copyWith(fontSize: 30, color: context.textPrimaryColor),
                            children: [
                              TextSpan(text: 'role_select'.tr),
                              TextSpan(
                                text: 'role_your_role'.tr,
                                style: const TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'role_subtitle'.tr,
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 15),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'role_user'.tr,
                          onPressed: controller.selectUser,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'role_helper'.tr,
                          onPressed: controller.selectHelper,
                          isOutlined: true,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
