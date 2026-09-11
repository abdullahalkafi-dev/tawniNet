import 'package:get/get.dart';
import 'package:awnneaapp/app/services/notification_api.dart';

/// Shared unread badge for client + helper notification bells.
class NotificationBadgeController extends GetxService {
  final unread = 0.obs;
  bool _loading = false;

  NotificationApi get _api {
    if (Get.isRegistered<NotificationApi>()) {
      return Get.find<NotificationApi>();
    }
    return Get.put(NotificationApi(), permanent: true);
  }

  Future<NotificationBadgeController> init() async {
    refresh();
    return this;
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final count = await _api.unreadCount();
      unread.value = count;
    } catch (_) {
      // keep last known count
    } finally {
      _loading = false;
    }
  }

  void clear() => unread.value = 0;
}
