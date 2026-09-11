import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpCenterView extends StatefulWidget {
  const HelpCenterView({super.key});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends State<HelpCenterView> {
  int selectedTab = 0;
  final List<Map<String, dynamic>> faqs = [
    {'question': 'How do I place an order?', 'answer': 'Simply browse the products, select the variant (size, color, etc.), tap "Add to Cart", and proceed to checkout. You\'ll be guided step-by-step to complete your purchase.', 'expanded': true},
    {'question': 'What payment methods are accepted?', 'answer': 'We accept all major credit cards, debit cards, and digital wallets.', 'expanded': false},
    {'question': 'How do I track my order?', 'answer': 'You can track your order from the Orders section in your profile.', 'expanded': false},
    {'question': 'How do I track my order?', 'answer': 'You can track your order from the Orders section in your profile.', 'expanded': false},
    {'question': 'Can I cancel or change my order?', 'answer': 'You can cancel or change your order within 24 hours of placing it.', 'expanded': false},
    {'question': 'How long does shipping take?', 'answer': 'Standard shipping takes 3-5 business days. Express shipping takes 1-2 business days.', 'expanded': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings_help_center'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedTab == 0 ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'settings_faq'.tr,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyLarge.copyWith(
                        color: selectedTab == 0 ? AppColors.primary : context.textHintColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedTab == 1 ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'settings_contact_us'.tr,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyLarge.copyWith(
                        color: selectedTab == 1 ? AppColors.primary : context.textHintColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: selectedTab == 0 ? _buildFaqTab(context) : _buildContactTab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('settings_faq_title'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'settings_faq_updated'.tr,
            style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 20),
          ...faqs.asMap().entries.map((entry) {
            final faq = entry.value;
            final isExpanded = faq['expanded'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isExpanded ? AppColors.primary.withOpacity(0.08) : context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpanded ? AppColors.primary.withOpacity(0.3) : context.borderSubtle,
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                initiallyExpanded: isExpanded,
                title: Text(
                  faq['question'] as String,
                  style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: context.textSecondaryColor,
                ),
                onExpansionChanged: (expanded) {
                  setState(() => faq['expanded'] = expanded);
                },
                children: [
                  Text(
                    faq['answer'] as String,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14, height: 1.5, color: context.textSecondaryColor),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  context,
                  'settings_support_chat'.tr,
                  'settings_24x7_support'.tr,
                  Icons.chat_bubble_outline,
                  AppColors.primary,
                  onTap: () => Get.toNamed(Routes.supportTicketList),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContactCard(
                  context,
                  'settings_email'.tr,
                  'admin@shifty.com',
                  Icons.email_outlined,
                  Colors.purple,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textSecondaryColor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
