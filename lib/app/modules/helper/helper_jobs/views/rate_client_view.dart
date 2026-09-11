import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/review_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RateClientView extends StatefulWidget {
  const RateClientView({super.key});

  @override
  State<RateClientView> createState() => _RateClientViewState();
}

class _RateClientViewState extends State<RateClientView> {
  int _rating = 0;
  bool _isSubmitting = false;
  final _reviewController = TextEditingController();
  Map<String, dynamic> _job = const {};

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _job = Map<String, dynamic>.from(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    if (job.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: const Center(child: Text('Job not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'rate_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'rate_skip'.tr,
              style: AppStyles.bodyLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildClientInfo(context, job),
            const SizedBox(height: 30),
            Text(
              'rate_how_was'.tr,
              style: AppStyles.h2Of(context).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildStarRating(),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'rate_leave_review'.tr,
                style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 200,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'rate_share'.tr,
                hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                filled: true,
                fillColor: context.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'rate_submit'.tr,
              isLoading: _isSubmitting,
              onPressed: () async {
                if (_rating == 0) {
                  AppFeedback.error(
                    'Please select a star rating',
                    title: 'Rating Required',
                  );
                  return;
                }
                if (_isSubmitting) return;
                setState(() => _isSubmitting = true);
                try {
                  final reviewService = Get.find<ReviewService>();
                  final jobId = (job['id'] ?? job['_id'])?.toString() ?? '';
                  final postedBy = job['postedBy'];
                  String revieweeId = (job['clientId'] ?? '').toString();
                  if (revieweeId.isEmpty && postedBy is Map) {
                    revieweeId =
                        (postedBy['_id'] ?? postedBy['id'] ?? '').toString();
                  }
                  if (jobId.isEmpty || revieweeId.isEmpty) {
                    AppFeedback.error(
                      'Could not identify this job for review.',
                      title: 'Review failed',
                    );
                    return;
                  }
                  await reviewService.submitReview(
                    jobId: jobId,
                    revieweeId: revieweeId,
                    rating: _rating.toDouble(),
                    comment: _reviewController.text,
                  );
                  // Patch local job list so completed details hide Review button.
                  if (Get.isRegistered<HelperJobsController>()) {
                    Get.find<HelperJobsController>().patchJobLocally(jobId, {
                      'hasMyReview': true,
                      'myReview': {
                        'rating': _rating,
                        'comment': _reviewController.text,
                        'createdAt': DateTime.now().toIso8601String(),
                      },
                    });
                  }
                  if (!mounted) return;
                  Get.back();
                  AppFeedback.success(
                    'rate_submitted'.tr.isNotEmpty
                        ? 'rate_submitted'.tr
                        : 'Thank you!',
                    title: 'rate_thank_you'.tr.isNotEmpty
                        ? 'rate_thank_you'.tr
                        : 'Review Submitted',
                  );
                  try {
                    Get.find<RefetchService>()
                        .invalidateJobPipeline()
                        .catchError((_) {});
                  } catch (_) {}
                } catch (e) {
                  AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
                } finally {
                  if (mounted) {
                    setState(() => _isSubmitting = false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context, Map job) {
    final name = JobDisplay.personName(
      job['postedBy'],
      fallback: JobDisplay.safeText(job['clientName'], fallback: 'Client'),
    );
    final avatar = JobDisplay.personAvatar(job['postedBy'],
        fallback: JobDisplay.safeText(job['clientImage']));
    final resolvedAvatar = ApiConstants.resolveImageUrl(avatar) ?? avatar;
    final location = JobDisplay.publicAddress(job);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.network(
              resolvedAvatar,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: context.inputFillLight,
                  child: Icon(Icons.person, color: context.textHintColor),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'status_completed'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => setState(() => _rating = index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
