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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Help Center',
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
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
                      'FAQ',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyLarge.copyWith(
                        color: selectedTab == 0 ? AppColors.primary : Colors.grey,
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
                      'Contact us',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyLarge.copyWith(
                        color: selectedTab == 1 ? AppColors.primary : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: selectedTab == 0 ? _buildFaqTab() : _buildContactTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frequently Asked Questions', style: AppStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'This FAQ\'s last updated was 16 January 2026',
            style: AppStyles.bodyMedium.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...faqs.asMap().entries.map((entry) {
            final faq = entry.value;
            final isExpanded = faq['expanded'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isExpanded ? AppColors.primary.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpanded ? AppColors.primary.withOpacity(0.2) : const Color(0xFFF3F4F6),
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                initiallyExpanded: isExpanded,
                title: Text(
                  faq['question'] as String,
                  style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
                onExpansionChanged: (expanded) {
                  setState(() => faq['expanded'] = expanded);
                },
                children: [
                  Text(
                    faq['answer'] as String,
                    style: AppStyles.bodyMedium.copyWith(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  'Support Chat',
                  '24x7 Online Support',
                  Icons.chat_bubble_outline,
                  AppColors.primary,
                  onTap: () => Get.toNamed(Routes.customerService),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContactCard(
                  'Email',
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

  Widget _buildContactCard(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
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
            Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppStyles.bodyMedium.copyWith(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
