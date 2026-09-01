import 'package:get/get.dart';

class RefetchService extends GetxService {
  final _callbacks = <String, Future<void> Function()>{};

  /// Register a fetch callback with a key.
  void register(String key, Future<void> Function() callback) {
    _callbacks[key] = callback;
  }

  /// Unregister a key (call in controller.onClose to avoid memory leaks).
  void unregister(String key) {
    _callbacks.remove(key);
  }

  /// Refetch a single key.
  Future<void> invalidate(String key) async {
    final cb = _callbacks[key];
    if (cb != null) {
      await cb();
    }
  }

  /// Refetch multiple keys.
  Future<void> invalidateMany(List<String> keys) async {
    for (final key in keys) {
      final cb = _callbacks[key];
      if (cb != null) {
        await cb();
      }
    }
  }

  /// Refetch everything registered.
  Future<void> invalidateAll() async {
    for (final cb in _callbacks.values) {
      await cb();
    }
  }

  /// Clear all registered callbacks (on logout).
  void clear() {
    _callbacks.clear();
  }
}
