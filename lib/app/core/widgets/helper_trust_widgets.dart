import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _verifiedBlue = Color(0xFF1D9BF0);
const Color _starAmber = Color(0xFFFFB400);

/// "Verified Helper" trust badge. [compact] renders only the check icon,
/// for tight spots next to a name.
class VerifiedBadge extends StatelessWidget {
  final bool compact;
  const VerifiedBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: 'verified_helper'.tr,
        child: const Icon(Icons.verified, size: 16, color: _verifiedBlue),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _verifiedBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 14, color: _verifiedBlue),
          const SizedBox(width: 4),
          Text(
            'verified_helper'.tr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _verifiedBlue,
            ),
          ),
        ],
      ),
    );
  }
}

/// ★ 4.8 (23) — or a "New" tag when the helper has no reviews yet.
class RatingSummary extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double fontSize;
  final bool showReviewWord;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.fontSize = 12,
    this.showReviewWord = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount <= 0) {
      return Text(
        'rating_new'.tr,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: context.textHintColor,
        ),
      );
    }
    final countLabel = showReviewWord
        ? 'rating_reviews_count'.trParams({'count': '$reviewCount'})
        : '($reviewCount)';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 4, color: _starAmber),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          countLabel,
          style: TextStyle(fontSize: fontSize, color: context.textHintColor),
        ),
      ],
    );
  }
}

/// Row of small work-sample thumbnails shown on helper cards.
class WorkPhotoStrip extends StatelessWidget {
  final List<String> urls;
  final double size;
  const WorkPhotoStrip({super.key, required this.urls, this.size = 56});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: size,
      child: Row(
        children: [
          for (final url in urls.take(3))
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppNetworkImage(
                url: url,
                width: size,
                height: size,
                radius: 10,
                errorWidget: const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
