import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:awnneaapp/app/data/models/auth_model.dart';
import 'package:awnneaapp/app/data/models/booking_model.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';

// The fixtures in test/fixtures are real responses of the backend (captured from a running
// server). These tests make sure the app's data models read them: if the server changes a
// field, this fails here instead of on a phone.
dynamic _load(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync());
dynamic _data(String name) => (_load(name) as Map)['data'];
List _docs(dynamic d) => d is List ? d : (d['docs'] ?? d['jobs'] ?? d['helpers'] ?? d['conversations'] ?? []) as List;

void main() {
  test('login + profile of a client and of a helper', () {
    final login = _data('login_client') as Map<String, dynamic>;
    expect(login['accessToken'], isA<String>());
    expect(login['refreshToken'], isA<String>());
    final client = AuthUser.fromJson(Map<String, dynamic>.from(_data('me_client') as Map));
    expect(client.name, isNotEmpty);
    expect(client.notificationPrefs, isNotEmpty);
    final helper = AuthUser.fromJson(Map<String, dynamic>.from(_data('me_helper') as Map));
    expect(helper.helperApplicationStatus, 'approved');
    expect(helper.isAvailable, isTrue);
    expect(helper.language, isNotNull);
  });

  test('categories (slug, icon, pricing)', () {
    final list = (_data('categories') as List).map((c) => Category.fromJson(Map<String, dynamic>.from(c as Map))).toList();
    expect(list, isNotEmpty);
    expect(list.every((c) => c.id.isNotEmpty && c.name.isNotEmpty), isTrue);
    expect(list.any((c) => c.slug != null), isTrue);
  });

  test('a completed booking and the job detail, as client and as helper', () {
    for (final fixture in ['job_detail_client', 'job_detail_helper']) {
      final b = Booking.fromJson(Map<String, dynamic>.from(_data(fixture) as Map));
      expect(b.id, isNotEmpty, reason: fixture);
      expect(b.status, BookingStatus.completed, reason: fixture);
      expect(b.budget, greaterThan(0), reason: fixture);
    }
    for (final raw in _docs(_data('my_bookings_completed'))) {
      expect(() => Booking.fromJson(Map<String, dynamic>.from(raw as Map)), returnsNormally);
    }
  });

  test('jobs near a helper hide the client\'s private details', () {
    final jobs = _docs(_data('nearby_helper'));
    expect(jobs, isNotEmpty);
    for (final raw in jobs) {
      final map = Map<String, dynamic>.from(raw as Map);
      final job = HelperJob.fromJson(map);
      expect(job.id, isNotEmpty);
      final text = jsonEncode(map);
      expect(text.contains('omar.client'), isFalse);
      expect(text.contains('+212698765431'), isFalse);
    }
  });

  test('helper search cards', () {
    final list = _docs(_data('helpers_search'));
    for (final raw in list) {
      final map = Map<String, dynamic>.from(raw as Map);
      expect(() => HelperJob.fromHelperJson(map), returnsNormally);
      expect(map.containsKey('location'), isFalse, reason: 'a helper\'s exact home position is not sent');
    }
  });

  test('conversations and messages', () {
    final convs = _docs(_data('conversations'));
    expect(convs, isNotEmpty);
    for (final raw in convs) {
      expect(() => ChatConversation.fromJson(Map<String, dynamic>.from(raw as Map)), returnsNormally);
    }
    final msgs = _docs(_data('messages'));
    expect(msgs, isNotEmpty);
    for (final raw in msgs) {
      final m = ChatMessage.fromJson(Map<String, dynamic>.from(raw as Map));
      expect(m.id, isNotEmpty);
    }
  });

  test('wallet totals, reviews with the helper reply, support ticket', () {
    final wallet = _data('wallet_balance') as Map;
    expect(wallet['balance'], isA<num>());
    expect(wallet['totals'], isA<Map>());
    final reviews = _data('reviews_user') as List;
    expect(reviews, isNotEmpty);
    expect((reviews.first as Map)['reply'], isNotNull, reason: 'the reply is sent with the review');
    final detail = _data('support_ticket_detail') as Map;
    expect(detail['ticket'], isA<Map>());
    expect(detail['messages'], isA<List>());
    expect(_data('config')['platformFeePercentage'], isA<num>());
  });
}
