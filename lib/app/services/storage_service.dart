import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  // Keys
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserJson = 'user_json';
  static const _kUserRole = 'user_role';

  /// Initialize the storage service
  Future<StorageService> init() async {
    return this;
  }

  // ─── Tokens ─────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _kRefreshToken);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
    ]);
  }

  // ─── User ───────────────────────────────────────────────

  Future<void> saveUserJson(Map<String, dynamic> user) async {
    await _storage.write(key: _kUserJson, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    final raw = await _storage.read(key: _kUserJson);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    await _storage.delete(key: _kUserJson);
  }

  // ─── Role ───────────────────────────────────────────────

  Future<void> saveRole(String role) async {
    await _storage.write(key: _kUserRole, value: role);
  }

  Future<String?> getRole() async {
    return _storage.read(key: _kUserRole);
  }

  // ─── Clear Auth Data ─────────────────────────────────────

  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserJson),
      _storage.delete(key: _kUserRole),
    ]);
  }

  // ─── Clear All ──────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ─── Generic key-value ─────────────────────────────────

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  // ─── Check if logged in ─────────────────────────────────

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && refresh != null;
  }
}
