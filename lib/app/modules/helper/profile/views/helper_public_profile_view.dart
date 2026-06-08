import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperPublicProfileView extends StatefulWidget {
  const HelperPublicProfileView({super.key});

  @override
  State<HelperPublicProfileView> createState() => _HelperPublicProfileViewState();
}

class _HelperPublicProfileViewState extends State<HelperPublicProfileView> {
  bool isAvailable = true;
  bool isAboutExpanded = false;

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
          'Profile',
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildAboutSection(),
            const SizedBox(height: 24),
            _buildPhotosSection(),
            const SizedBox(height: 24),
            _buildReviewsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text('Ethan Carter', style: AppStyles.h1.copyWith(fontSize: 22)),
          Text(
            'Handyman, Cleaning, Moving',
            style: AppStyles.bodyMedium.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '4.8 (124 reviews)',
                style: AppStyles.bodyLarge.copyWith(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.toNamed(Routes.helperEditProfile),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Edit Info', style: AppStyles.buttonText.copyWith(color: AppColors.primary, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => isAvailable = !isAvailable),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? AppColors.primary : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Unavailable',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    const fullText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam. At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores.';
    const shortText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About me', style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => isAboutExpanded = !isAboutExpanded),
          child: RichText(
            text: TextSpan(
              text: isAboutExpanded ? fullText : shortText,
              style: AppStyles.bodyMedium.copyWith(height: 1.5),
              children: [
                TextSpan(
                  text: isAboutExpanded ? ' Read less...' : ' Read more...',
                  style: AppStyles.bodyMedium.copyWith(
                    height: 1.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://i.pravatar.cc/150?u=photo$index',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('4.9', style: AppStyles.h1.copyWith(fontSize: 36)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) => Icon(Icons.star, color: AppColors.primary, size: 18)),
                ),
                Text('175 Reviews', style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewBar(5, '80%'),
        _buildReviewBar(4, '12%'),
        _buildReviewBar(3, '5%'),
        _buildReviewBar(2, '3%'),
        _buildReviewBar(1, '0%'),
        const SizedBox(height: 20),
        _buildReviewItem('Rihanna', 'https://i.pravatar.cc/150?u=rihanna', 5, '45m ago',
            'I\'m very happy with order, it was delivered on and good quality. Recommended!'),
        const SizedBox(height: 16),
        _buildReviewItem('Jhon', 'https://i.pravatar.cc/150?u=jhon', 5, '30m ago',
            'I love it. Awesome customer service!! Helped me out with adding an additional item to my order. Thanks again!'),
        const SizedBox(height: 16),
        _buildReviewItem('Rihanna', 'https://i.pravatar.cc/150?u=rihanna2', 5, '50m ago',
            'I\'m very happy with order, it was delivered on and good quality. Recommended!'),
      ],
    );
  }

  Widget _buildReviewBar(int stars, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$stars', style: AppStyles.bodyMedium.copyWith(fontSize: 14)),
          ),
          Icon(Icons.star, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: double.parse(percent.replaceAll('%', '')) / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(percent, style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String image, int rating, String time, String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                image,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 36,
                    height: 36,
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.person, size: 16, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(name, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text(time, style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(rating, (i) => Icon(Icons.star, color: AppColors.primary, size: 14)),
        ),
        const SizedBox(height: 8),
        Text(comment, style: AppStyles.bodyMedium.copyWith(height: 1.4)),
      ],
    );
  }
}
