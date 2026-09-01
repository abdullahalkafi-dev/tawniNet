import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/awnnea_search_controller.dart';

class SearchView extends GetView<AwnneaSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: _buildSearchField(context),
      ),
      body: Obx(() {
        if (controller.isSearching.value) {
          return _buildResultsView(context);
        }
        return _buildSuggestionsView(context);
      }),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller.searchController,
        autofocus: true,
        onChanged: controller.onSearchChanged,
        onSubmitted: controller.onSearch,
        style: TextStyle(color: context.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'search_cleaner'.tr,
          hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          icon: Icon(Icons.search, color: context.textHintColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSuggestionsView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Services',
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoadingSuggestions.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (controller.categories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No services found',
                    style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  ),
                ),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.categories.map((cat) {
                return GestureDetector(
                  onTap: () => controller.onCategoryTap(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(context.isDarkMode ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(context.isDarkMode ? 0.3 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty)
                          Image.network(
                            cat.iconUrl!,
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.build,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          const Icon(
                            Icons.build,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          cat.name,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 30),
          Obx(() {
            if (controller.suggestions.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'search_recent'.tr,
                    style: AppStyles.h2Of(context).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ...controller.suggestions.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item,
                      style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.cancel_outlined, color: context.textHintColor, size: 20),
                      onPressed: () => controller.removeRecent(item),
                    ),
                    onTap: () {
                      controller.searchController.text = item;
                      controller.onSearch(item);
                    },
                  )),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildResultsView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppStyles.h2Of(context).copyWith(fontSize: 18),
                  children: [
                    TextSpan(text: 'search_results_for'.tr),
                    TextSpan(
                      text: ' "${controller.searchController.text}"',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Obx(() => Text(
                '${controller.searchResults.length} found',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.primary),
              )),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() {
              if (controller.searchResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: context.textHintColor),
                      const SizedBox(height: 16),
                      Text(
                        'No helpers found',
                        style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: controller.searchResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final helper = controller.searchResults[index];
                  return _buildHelperCard(context, helper);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperCard(BuildContext context, HelperJob helper) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: helper.helperImage.isNotEmpty
                    ? Image.network(
                        helper.helperImage,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context),
                      )
                    : _buildAvatarPlaceholder(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helper.helperName,
                      style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helper.category,
                      style: AppStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    if (helper.bio != null && helper.bio!.isNotEmpty)
                      Text(
                        helper.bio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: context.textHintColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.toNamed(Routes.helperPublicProfile, arguments: helper.id);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: context.borderSubtle),
                      backgroundColor: context.inputFillLight,
                    ),
                    child: Text(
                      'btn_view_profile'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.isDarkMode ? AppColors.primary : Colors.teal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text('btn_chat'.tr, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      color: context.inputFillLight,
      padding: const EdgeInsets.all(12),
      child: SvgPicture.asset(
        'assets/svgs/profile_icon.svg',
        colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
      ),
    );
  }
}
