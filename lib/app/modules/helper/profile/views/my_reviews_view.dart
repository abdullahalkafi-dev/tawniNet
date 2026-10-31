import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/error_retry.dart';
import 'package:awnneaapp/app/core/widgets/review_card.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/review_service.dart';

/// The helper's own reviews: answer a review once, or report an unfair one.
class MyReviewsView extends StatefulWidget {
  const MyReviewsView({super.key});

  @override
  State<MyReviewsView> createState() => _MyReviewsViewState();
}

class _MyReviewsViewState extends State<MyReviewsView> {
  final _service = Get.find<ReviewService>();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = Get.find<AuthService>().currentUser.value?.id;
    if (id == null) return;
    setState(() {
      _loading = _items.isEmpty;
      _failed = false;
    });
    try {
      final raw = await _service.getUserReviews(id);
      final out = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) out.add(ReviewService.toCardMap(Map<String, dynamic>.from(item)));
      }
      if (mounted) setState(() => _items = out);
    } catch (_) {
      if (mounted) setState(() => _failed = _items.isEmpty);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askText({required String title, required String hint, int min = 2, int max = 500}) async {
    final ctl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          maxLines: 4,
          maxLength: max,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('btn_cancel'.tr)),
          FilledButton(
            onPressed: () {
              final text = ctl.text.trim();
              if (text.length < min) {
                AppFeedback.error('review_text_too_short'.trParams({'min': '$min'}));
                return;
              }
              Navigator.pop(ctx, text);
            },
            child: Text('btn_submit'.tr),
          ),
        ],
      ),
    );
    ctl.dispose();
    return result;
  }

  Future<void> _reply(Map<String, dynamic> review) async {
    final text = await _askText(title: 'review_reply_title'.tr, hint: 'review_reply_hint'.tr);
    if (text == null) return;
    try {
      await _service.replyToReview(review['id'].toString(), text);
      AppFeedback.success('review_reply_sent'.tr);
      await _load();
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
  }

  Future<void> _report(Map<String, dynamic> review) async {
    final text = await _askText(title: 'review_report_title'.tr, hint: 'review_report_hint'.tr, min: 3, max: 300);
    if (text == null) return;
    try {
      await _service.reportReview(review['id'].toString(), text);
      AppFeedback.success('review_report_sent'.tr);
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: Text('my_reviews_title'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: _loading
          ? SkeletonList(count: 4, itemBuilder: (_, _) => const JobCardSkeleton())
          : _failed
              ? ErrorRetry(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.rate_review_outlined, size: 48, color: context.textHintColor),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'rating_no_reviews'.tr,
                                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          children: [
                            for (final r in _items)
                              ReviewCard(
                                review: r,
                                actions: Row(
                                  children: [
                                    if ((r['reply'] ?? '').toString().isEmpty)
                                      TextButton.icon(
                                        onPressed: () => _reply(r),
                                        icon: const Icon(Icons.reply, size: 18),
                                        label: Text('review_reply_action'.tr),
                                      ),
                                    TextButton.icon(
                                      onPressed: () => _report(r),
                                      icon: const Icon(Icons.flag_outlined, size: 18),
                                      label: Text('review_report_action'.tr),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
    );
  }
}
