import 'package:flutter_test/flutter_test.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/widgets/helper_form_fields.dart';

// Pure-logic tests: these mirror rules the server enforces (hourly price =
// rate x hours, night shifts, minimum slot) and the helper form data helpers.
void main() {
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
