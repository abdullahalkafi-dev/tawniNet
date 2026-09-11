import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:get/get.dart';

/// In-app notification history API (mirrors FCM payloads for deep-links).
class NotificationApi {
  NotificationApi() {
    _api = Get.find<ApiClient>();
  }

  late final ApiClient _api;

  Future<Map<String, dynamic>> list({int page = 1, int limit = 20}) async {
    final res = await _api.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'limit': limit},
      fromData: (d) => d,
    );
    if (res.success && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {'docs': <dynamic>[], 'total': 0, 'unread': 0, 'page': page, 'limit': limit};
  }

  Future<int> unreadCount() async {
    final res = await _api.get(
      ApiConstants.notificationsUnread,
      fromData: (d) => d,
    );
    if (res.success && res.data is Map) {
      return ((res.data as Map)['unread'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> markRead(String id) async {
    await _api.patch(ApiConstants.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _api.patch(ApiConstants.notificationsReadAll);
  }
}
