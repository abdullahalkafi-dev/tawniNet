import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';

/// One review: stars, comment, the helper's public reply and (optionally) a
/// row of actions under it. [review] is the shape built by the profile
/// controllers: id, rating, comment, date, reviewerName, reviewerAvatar, reply.
class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final Widget? actions;

  const ReviewCard({super.key, required this.review, this.actions});

  @override
  Widget build(BuildContext context) {
    final rating = ((review['rating'] as num?) ?? 0).round().clamp(0, 5);
    final name = (review['reviewerName'] ?? 'ui_client'.tr).toString();
    final avatar = (review['reviewerAvatar'] ?? '').toString();
    final comment = (review['comment'] ?? '').toString();
    final date = (review['date'] ?? '').toString();
    final reply = (review['reply'] ?? '').toString();
    final edited = review['edited'] == true;
    final resolvedAvatar = ApiConstants.resolveImageUrl(avatar) ?? avatar;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AppNetworkImage(url: resolvedAvatar, width: 36, height: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (date.isNotEmpty)
                Text(date, style: TextStyle(fontSize: 11, color: context.textHintColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16),
              ),
              if (edited) ...[
                const SizedBox(width: 8),
                Text('review_edited'.tr, style: TextStyle(fontSize: 11, color: context.textHintColor)),
              ],
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: AppStyles.bodyMediumOf(context).copyWith(height: 1.4)),
          ],
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.inputFillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'review_reply_label'.tr,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(reply, style: AppStyles.bodyMediumOf(context).copyWith(height: 1.4, fontSize: 13)),
                ],
              ),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 8),
            actions!,
          ],
        ],
      ),
    );
  }
}
