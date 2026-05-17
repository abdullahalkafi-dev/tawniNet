import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/helper_profile_controller.dart';

class HelperProfileView extends GetView<HelperProfileController> {
  const HelperProfileView({super.key});

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
          'Helper details',
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildStats(),
                const SizedBox(height: 32),
                _buildAboutMe(),
                const SizedBox(height: 32),
                _buildPhotos(),
                const SizedBox(height: 32),
                _buildReviews(),
              ],
            ),
          ),
          _buildBottomChat(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
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
                    padding: const EdgeInsets.all(20),
                    child: SvgPicture.asset(
                      'assets/svgs/profile_icon.svg',
                      colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sophia Carter', style: AppStyles.h1.copyWith(fontSize: 24)),
          Text(
            'Cleaner',
            style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text(
                'Downtown Area . 0.5 mi away',
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('3 Yrs', 'Experience'),
        _buildStatItem('120+', 'Jobs Done'),
        _buildStatItem('4.9 ⭐', 'Rating'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMe() {
    const fullText =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
    const truncatedText =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam. ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About me', style: AppStyles.h2.copyWith(fontSize: 20)),
        const SizedBox(height: 12),
        Obx(
          () => RichText(
            text: TextSpan(
              style: AppStyles.bodyMedium.copyWith(
                height: 1.5,
                color: Colors.grey[600],
              ),
              children: [
                TextSpan(
                  text: controller.isAboutMeExpanded.value ? fullText : truncatedText,
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: controller.toggleAboutMeExpanded,
                    child: Text(
                      controller.isAboutMeExpanded.value ? ' Read less' : 'Read more...',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotos() {
    final images = [
      'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1527515545081-5db817172677?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1527515545081-5db817172677?auto=format&fit=crop&q=80&w=200',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: AppStyles.h2.copyWith(fontSize: 20)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final fallbackImages = [
              'assets/images/onboarding_1.png',
              'assets/images/onboarding_2.png',
              'assets/images/onboarding_3.png',
              'assets/images/select_role.png',
            ];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    fallbackImages[index % fallbackImages.length],
                    fit: BoxFit.cover,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: AppStyles.h2.copyWith(fontSize: 20)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                RichText(
                  text: TextSpan(
                    style: AppStyles.h1.copyWith(
                      fontSize: 40,
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: '4.9'),
                      TextSpan(
                        text: ' OUT OF 5',
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '175 Reviews',
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildRatingProgress(5, 0.8, '80%'),
                  _buildRatingProgress(4, 0.12, '12%'),
                  _buildRatingProgress(3, 0.05, '5%'),
                  _buildRatingProgress(2, 0.03, '3%'),
                  _buildRatingProgress(1, 0, '0%'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildReviewItem(
          'Rihana',
          '45m ago',
          'I\'m very happy with order, it was delivered on and good quality. Recommended!',
        ),
        _buildReviewItem(
          'Jhon',
          '30m ago',
          'I love it. Awesome customer service!! Helped me out with adding an additional item to my order. Thanks again!',
        ),
        _buildReviewItem(
          'Rihana',
          '50m ago',
          'I\'m very happy with order, it was delivered on and good quality. Recommended!',
        ),
      ],
    );
  }

  Widget _buildRatingProgress(int star, double progress, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$star', style: AppStyles.bodyMedium.copyWith(fontSize: 10)),
          const SizedBox(width: 4),
          const Icon(Icons.star, color: AppColors.primary, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[100],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1F3A5F),
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            percent,
            style: AppStyles.bodyMedium.copyWith(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String time, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple[100],
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          time,
                          style: AppStyles.bodyMedium.copyWith(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomChat() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sentiment_satisfied_alt_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: controller.sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
