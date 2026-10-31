import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_dialogs.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A service offer inside the chat. Shows the real total (hours × rate for an
/// hourly offer), and asks for confirmation before every action that commits money.
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

  static String _num(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final offer = message.offerData;
    if (offer == null) return const SizedBox.shrink();

    final isPending = offer.status == 'pending';
    final isAwaitingPayment = offer.status == 'awaiting_payment';
    // Accept / Reject / Pay now — client (non-sender) only
    final canClientAct = !isHelper && !isSentByMe;
    // Edit / Cancel — helper (offer sender) while still pending
    final canHelperAct = (isHelper || isSentByMe) && isPending;
    final showActions = (canClientAct && (isPending || isAwaitingPayment)) || canHelperAct;
    final sentByHelper = isHelper || isSentByMe;
    final statusColor = _statusColor(offer.status);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ui_service_offer'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
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
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: GestureDetector(
                      onTap: () => Get.to(
                        () => ImageViewerScreen(imageUrls: offer.images, initialIndex: index),
                      ),
                      child: AppNetworkImage(
                        url: offer.images[index],
                        width: 80,
                        height: 80,
                        radius: 8,
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
                    style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                _buildPriceBlock(context, offer, sentByHelper),
                const SizedBox(height: 8),

                // Date + Time range
                if (offer.date.isNotEmpty || offer.startTime.isNotEmpty || offer.endTime.isNotEmpty)
                  _detailRow(
                    context,
                    Icons.access_time,
                    AppDateTime.formatDateTimeRange(
                      date: offer.date,
                      startTime: offer.startTime,
                      endTime: offer.endTime,
                    ),
                  ),

                if (offer.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _detailRow(context, Icons.location_on_outlined, offer.address),
                ],

                const SizedBox(height: 4),
                _detailRow(
                  context,
                  offer.paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                  offer.paymentMethod == 'cash' ? 'offer_pay_cash'.tr : 'offer_pay_online'.tr,
                ),

                if (isPending && offer.expiresAt != null) ...[
                  const SizedBox(height: 4),
                  _detailRow(
                    context,
                    Icons.hourglass_bottom,
                    'offer_expires'.trParams({'when': _remaining(offer.expiresAt!)}),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (showActions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.borderSubtle)),
              ),
              child: canClientAct && isAwaitingPayment
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('booking_pay_now'.tr, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                  : _buildActionButtons(context, offer),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.textHintColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: context.textHintColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// "5 h × 100 MAD = 500 MAD" for hourly offers; the commission and the
  /// helper's net for the helper who sent it.
  Widget _buildPriceBlock(BuildContext context, OfferData offer, bool sentByHelper) {
    final total = offer.total;
    final hasFee = offer.feePercentage != null && offer.feePercentage! > 0;
    final commission = hasFee ? total * offer.feePercentage! / 100 : null;
    final net = offer.helperNet ?? (commission != null ? total - commission : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'MAD ${_num(total)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'offer_total_word'.tr,
              style: TextStyle(fontSize: 12, color: context.textHintColor),
            ),
          ],
        ),
        if (offer.isHourly) ...[
          const SizedBox(height: 2),
          Text(
            (offer.hours != null)
                ? 'post_total_preview'.trParams({
                    'hours': _num(offer.hours!),
                    'rate': _num(offer.hourlyRate ?? offer.price),
                    'total': _num(total),
                  })
                : 'offer_per_hour'.trParams({'rate': _num(offer.price)}),
            style: TextStyle(fontSize: 12, color: context.textHintColor),
          ),
        ],
        if (sentByHelper && commission != null && net != null) ...[
          const SizedBox(height: 4),
          Text(
            'offer_commission_line'.trParams({
              'pct': _num(offer.feePercentage!),
              'amount': _num(commission),
            }),
            style: TextStyle(fontSize: 11, color: context.textHintColor),
          ),
          Text(
            'offer_you_receive'.trParams({'amount': _num(net)}),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  String _remaining(DateTime when) {
    final diff = when.difference(DateTime.now());
    if (diff.isNegative) return 'offer_expired_now'.tr;
    if (diff.inHours >= 1) return 'chat_time_hours'.trParams({'n': '${diff.inHours}'});
    return 'chat_time_minutes'.trParams({'n': '${diff.inMinutes.clamp(1, 59)}'});
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    final String text;
    switch (status) {
      case 'accepted':
        text = 'job_accepted'.tr;
        break;
      case 'rejected':
        text = 'ui_rejected'.tr;
        break;
      case 'cancelled':
        text = 'status_cancelled'.tr;
        break;
      case 'expired':
        text = 'offer_status_expired'.tr;
        break;
      case 'awaiting_payment':
        text = 'ui_payment_required'.tr;
        break;
      default:
        text = 'status_pending'.tr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  ButtonStyle _outlined(Color c) => OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      );

  Widget _buildActionButtons(BuildContext context, OfferData offer) {
    // Helper (sender): only Cancel / Edit while pending — never Accept/Pay
    if (isHelper || isSentByMe) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final ok = await AppDialogs.confirm(
                  title: 'offer_cancel_title'.tr,
                  message: 'offer_cancel_body'.tr,
                  confirmLabel: 'offer_cancel_confirm'.tr,
                  cancelLabel: 'offer_keep'.tr,
                  danger: true,
                );
                if (ok) onCancel?.call();
              },
              style: _outlined(Colors.red),
              child: Text('btn_cancel'.tr, style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              style: _outlined(AppColors.primary),
              child: Text('ui_edit'.tr, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    }

    // Client: accept or reject
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final ok = await AppDialogs.confirm(
                title: 'offer_reject_title'.tr,
                message: 'offer_reject_body'.tr,
                confirmLabel: 'ui_reject'.tr,
                danger: true,
              );
              if (ok) onReject?.call();
            },
            style: _outlined(Colors.red),
            child: Text('ui_reject'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final ok = await AppDialogs.confirm(
                title: 'offer_accept_title'.tr,
                message: 'offer_accept_body'.trParams({
                  'total': _num(offer.total),
                  'payment': offer.paymentMethod == 'cash'
                      ? 'offer_pay_cash'.tr
                      : 'offer_pay_online'.tr,
                }),
                confirmLabel: 'ui_accept'.tr,
              );
              if (ok) onAccept?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Text('ui_accept'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
      case 'expired':
        return Colors.orange;
      case 'awaiting_payment':
        return Colors.orange.shade800;
      default:
        return Colors.blue;
    }
  }
}
