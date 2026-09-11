import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/notification_api.dart';
import 'package:awnneaapp/app/services/notification_badge_controller.dart';
import 'package:awnneaapp/app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Shared in-app notification feed (client + helper).
/// Loads history from `/notifications`, supports unread badge + deep-link on tap.
class AppNotificationListView extends StatefulWidget {
  const AppNotificationListView({
    super.key,
    this.title,
    this.showMarkAll = true,
  });

  final String? title;
  final bool showMarkAll;

  @override
  State<AppNotificationListView> createState() => _AppNotificationListViewState();
}

class _AppNotificationListViewState extends State<AppNotificationListView> {
  final ScrollController _scroll = ScrollController();
  late final NotificationApi _api;

  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _api = Get.isRegistered<NotificationApi>()
        ? Get.find<NotificationApi>()
        : Get.put(NotificationApi(), permanent: true);
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    // Sync home/helper bell after the user reads items in this screen.
    if (Get.isRegistered<NotificationBadgeController>()) {
      Get.find<NotificationBadgeController>().refresh();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.list(page: 1, limit: 20);
      final docs = (res['docs'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final total = (res['total'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _items
            ..clear()
            ..addAll(docs);
          _page = 1;
          _hasMore = _items.length < total;
          _unread = (res['unread'] as num?)?.toInt() ?? 0;
          _loading = false;
        });
        if (Get.isRegistered<NotificationBadgeController>()) {
          Get.find<NotificationBadgeController>().unread.value = _unread;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final res = await _api.list(page: next, limit: 20);
      final docs = (res['docs'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final total = (res['total'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _items.addAll(docs);
          _page = next;
          _hasMore = _items.length < total;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllRead();
      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          item['read'] = true;
        }
        _unread = 0;
      });
      if (Get.isRegistered<NotificationBadgeController>()) {
        Get.find<NotificationBadgeController>().clear();
      }
    } catch (_) {}
  }

  Future<void> _onTap(Map<String, dynamic> item) async {
    final id = (item['_id'] ?? item['id'] ?? '').toString();
    final wasUnread = item['read'] != true;
    if (id.isNotEmpty && wasUnread) {
      try {
        await _api.markRead(id);
        if (mounted) {
          setState(() {
            item['read'] = true;
            if (_unread > 0) _unread--;
          });
        }
        if (Get.isRegistered<NotificationBadgeController>()) {
          Get.find<NotificationBadgeController>().refresh();
        }
      } catch (_) {}
    }

    final rawData = item['data'];
    final data = <String, dynamic>{};
    if (rawData is Map) {
      rawData.forEach((k, v) {
        if (v != null) data[k.toString()] = v.toString();
      });
    }
    if (data.isNotEmpty && Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().navigateFromData(data);
    }
  }

  String _formatWhen(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly == today) {
        return DateFormat('h:mm a').format(date);
      }
      if (dateOnly == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      }
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }

  IconData _iconFor(Map<String, dynamic> item) {
    final data = item['data'];
    final type = data is Map ? (data['type'] ?? '').toString() : '';
    switch (type) {
      case 'job_accepted':
      case 'job_completed':
      case 'job_cancelled':
      case 'new_job':
        return Icons.work_outline;
      case 'chat_message':
      case 'chat_offer':
      case 'offer_accepted':
      case 'offer_rejected':
      case 'offer_cancelled':
        return Icons.chat_bubble_outline;
      case 'payment_success':
      case 'wallet_topup':
      case 'payment_failed':
        return Icons.payments_outlined;
      case 'kyc_approved':
      case 'kyc_rejected':
      case 'kyc_pending':
        return Icons.verified_user_outlined;
      case 'support_reply':
        return Icons.support_agent_outlined;
      case 'review_received':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title ?? 'notif_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (widget.showMarkAll && _unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'notif_mark_all_read'.tr,
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'notif_empty'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.textHintColor,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final item = _items[index];
                      final unread = item['read'] != true;
                      return Material(
                        color: unread
                            ? AppColors.primary.withOpacity(0.06)
                            : context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _onTap(item),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderSubtle),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _iconFor(item),
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (item['title'] ?? '')
                                                  .toString(),
                                              style: AppStyles.bodyLargeOf(
                                                context,
                                              ).copyWith(
                                                fontWeight: unread
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (unread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['body'] ?? '').toString(),
                                        style: AppStyles.bodyMedium.copyWith(
                                          fontSize: 13,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatWhen(item['createdAt']),
                                        style: AppStyles.bodyMedium.copyWith(
                                          fontSize: 11,
                                          color: context.textHintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
