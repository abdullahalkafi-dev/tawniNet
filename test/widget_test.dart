import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/widgets/helper_form_fields.dart';

// Pure-logic tests: these mirror rules the server enforces (hourly price =
// rate x hours, night shifts, minimum slot) and the helper form data helpers.
void main() {
  group('dates and times follow the app language', () {
    setUpAll(() async => initializeDateFormatting());
    tearDown(() => Get.locale = null);

    test('English, French and Arabic show different text, in Latin digits', () {
      Get.locale = const Locale('en', 'US');
      final en = AppDateTime.localizedDate('2026-10-31');
      Get.locale = const Locale('fr', 'FR');
      final fr = AppDateTime.localizedDate('2026-10-31');
      Get.locale = const Locale('ar', 'MA');
      final ar = AppDateTime.localizedDate('2026-10-31');
      expect({en, fr, ar}.length, 3);
      expect(en, contains('Oct'));
      expect(ar, contains('2026'));
    });

    test('French and Spanish show 24-hour time, English 12-hour', () {
      Get.locale = const Locale('fr', 'FR');
      expect(AppDateTime.localizedTime('5:00 PM'), '17:00');
      Get.locale = const Locale('en', 'US');
      expect(AppDateTime.localizedTime('17:00'), contains('PM'));
    });

    test('the form format sent to the server never changes with the language', () {
      Get.locale = const Locale('ar', 'MA');
      expect(AppDateTime.formatTime12h('17:00'), '5:00 PM');
      expect(AppDateTime.formatDateDisplay('2026-10-31'), 'Oct 31, 2026');
    });
  });

  group('AppDateTime hours (same rule as the server)', () {
    test('plain range', () {
      expect(AppDateTime.hoursBetween('9:00 AM', '11:30 AM'), 2.5);
      expect(AppDateTime.hoursBetween('09:00', '17:00'), 8.0);
    });

    test('end before start means the next day (night shift)', () {
      expect(AppDateTime.hoursBetween('10:00 PM', '2:00 AM'), 4.0);
    });

    test('unparseable input gives null', () {
      expect(AppDateTime.hoursBetween('abc', '10:00'), isNull);
      expect(AppDateTime.hoursBetween(null, '10:00'), isNull);
    });

    test('range validation', () {
      // "time_*" keys come back untranslated in tests (no locale loaded).
      expect(AppDateTime.validateTimeRange('09:00', '12:00'), isNull);
      expect(AppDateTime.validateTimeRange('09:00', '09:15'), isNotNull); // < 30 min
      expect(AppDateTime.validateTimeRange('09:00', '09:00'), isNotNull); // 24 h
      expect(AppDateTime.validateTimeRange('09:00', null), isNotNull); // one side missing
      expect(AppDateTime.validateTimeRange(null, null), isNull); // both empty is allowed
      expect(AppDateTime.validateTimeRange(null, null, required: true), isNotNull);
      expect(AppDateTime.validateTimeRange('06:00', '23:00'), isNull);
      expect(AppDateTime.validateTimeRange('06:00', '05:00'), isNotNull); // 23 h overnight
    });
  });

  group('helper form data', () {
    test('city matching ignores case and falls back to the address', () {
      expect(matchMoroccanCity('casablanca'), 'Casablanca');
      expect(matchMoroccanCity('20000', 'Rue 5, Marrakech, Morocco'), 'Marrakech');
      expect(matchMoroccanCity('20000'), isNull);
      expect(matchMoroccanCity(null, null), isNull);
    });

    test('every city has coordinates', () {
      for (final city in kMoroccanCities) {
        expect(kMoroccanCityCenters.containsKey(city), isTrue, reason: city);
      }
    });

    test('languages keep only known names', () {
      expect(parseHelperLanguages('Arabic, French; Klingon'), ['Arabic', 'French']);
      expect(parseHelperLanguages('English'), ['English']);
      expect(parseHelperLanguages(null), isEmpty);
    });
  });
}
