import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'About Us',
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, '1. Introduction', 'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum. Lorem quam vitae mus metus tortor turpis at. Cras accumsan pharetra odio euismod metus leo neque dui.'),
            _buildSection(context, '2. Mission Statement', 'Lorem ipsum dolor sit amet consectetur. Mattis et commodo lacus nisl vitae id. Fames egestas etiam risus ultrices risus. Porta nisl commodo sit id purus senectus ultrices.'),
            _buildSection(context, '3. Core Values', 'Lorem ipsum dolor sit amet consectetur. Elementum amet netus magna justo duis netus. Porttitor nulla erat sodales faucibus. Massa turpis nibh vel sit enim porta a.'),
            _buildSection(context, '4. Our Team', 'Lorem ipsum dolor sit amet consectetur. Massa suscipit euismod interdum suspendisse id. Vitae sed quam amet dictumst vel sed integer morbi. Vel sed aenean ultricies in volutpat scelerisque id eget hendrerit.'),
            _buildSection(context, '5. Contact Information', 'Lorem ipsum dolor sit amet consectetur. Id feugiat pretum ipsum sit amet consectetur.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Text(content, style: AppStyles.bodyMediumOf(context).copyWith(height: 1.6, color: context.textSecondaryColor)),
        ],
      ),
    );
  }
}
