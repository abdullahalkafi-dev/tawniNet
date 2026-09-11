import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OfferCardWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isSentByMe;
  final bool isHelper;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  const OfferCardWidget({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.isHelper,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final offer = message.offerData;
    if (offer == null) return const SizedBox.shrink();

    final isPending = offer.status == 'pending';
    final isAwaitingPayment = offer.status == 'awaiting_payment';
    final showActions = isPending || (isAwaitingPayment && !isHelper && !isSentByMe);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(offer.status).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(offer.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  size: 16,
                  color: _getStatusColor(offer.status),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Service Offer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(offer.status),
                    ),
                  ),
                ),
                _buildStatusBadge(offer.status),
              ],
            ),
          ),

          // Offer images
          if (offer.images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: offer.images.length.clamp(0, 4),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () {
                        Get.to(
                          () => ImageViewerScreen(
                            imageUrls: offer.images,
                            initialIndex: index,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ApiConstants.resolveImageUrl(offer.images[index]) ??
                              offer.images[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: context.inputFillColor,
                            child: Icon(Icons.image, color: context.textHintColor),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Offer details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (offer.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    offer.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),

                // Price row
                Row(
                  children: [
                    Text(
                      'MAD ${offer.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer.priceType == 'hourly' ? '/hour' : '(fixed)',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textHintColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date + Time range
                if (offer.date.isNotEmpty || offer.startTime.isNotEmpty || offer.endTime.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: context.textHintColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            if (offer.date.isNotEmpty)
                              AppDateTime.formatDateDisplay(offer.date),
                            if (offer.startTime.isNotEmpty || offer.endTime.isNotEmpty)
                              [
                                AppDateTime.formatTime12h(offer.startTime),
                                AppDateTime.formatTime12h(offer.endTime),
                              ].where((t) => t.isNotEmpty).join(' - '),
                          ].where((s) => s.isNotEmpty).join('  '),
                          style: TextStyle(fontSize: 12, color: context.textHintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 4),

                // Payment method
                Row(
                  children: [
                    Icon(
                      offer.paymentMethod == 'cash'
                          ? Icons.money
                          : Icons.credit_card,
                      size: 14,
                      color: context.textHintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer.paymentMethod == 'cash' ? 'Cash' : 'Online',
                      style: TextStyle(fontSize: 12, color: context.textHintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          if (showActions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.borderSubtle),
                ),
              ),
              child: isAwaitingPayment
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Pay now', style: TextStyle(fontSize: 12)),
                      ),
                    )
                  : _buildActionButtons(offer.status),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'cancelled':
        color = Colors.orange;
        text = 'Cancelled';
        break;
      case 'awaiting_payment':
        color = Colors.orange.shade800;
        text = 'Payment required';
        break;
      default:
        color = Colors.blue;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (isHelper) {
      // Helper can cancel or edit (only if pending)
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Edit', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    } else {
      // User can accept or reject
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Accept', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'awaiting_payment':
        return Colors.orange.shade800;
      default:
        return Colors.blue;
    }
  }
}
