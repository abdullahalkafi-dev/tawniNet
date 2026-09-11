import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared date/time helpers.
/// Save dates as ISO `yyyy-MM-dd`. Display times as 12-hour `h:mm AM/PM`.
class AppDateTime {
  AppDateTime._();

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('MMM d, yyyy');

  /// `2026-09-12`
  static String toIsoDate(DateTime date) => _isoDate.format(date);

  /// Parse ISO or common display forms. Null if unparseable.
  static DateTime? tryParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    return DateTime.tryParse(value) ??
        _displayDate.tryParse(value) ??
        DateFormat('MM/dd/yyyy').tryParse(value) ??
        DateFormat('d/M/yyyy').tryParse(value);
  }

  /// Human display: `Sep 12, 2026`. Falls back to raw string.
  static String formatDateDisplay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = tryParseDate(raw);
    if (parsed == null) return raw.trim();
    return _displayDate.format(parsed);
  }

  /// Parse `17:00`, `17:00:00`, `5:00 PM`, `5 PM`.
  static TimeOfDay? tryParseTimeOfDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toUpperCase();

    final amPm = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$').firstMatch(value);
    if (amPm != null) {
      var hour = int.tryParse(amPm.group(1)!) ?? 0;
      final minute = int.tryParse(amPm.group(2) ?? '0') ?? 0;
      final isPm = amPm.group(3) == 'PM';
      if (hour < 1 || hour > 12) return null;
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      if (minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      if (hour == null || minute == null) return null;
      if (hour > 23 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final hourOnly = int.tryParse(value);
    if (hourOnly != null && hourOnly >= 0 && hourOnly <= 23) {
      return TimeOfDay(hour: hourOnly, minute: 0);
    }
    return null;
  }

  /// `5:00 PM` (12-hour, no leading zero on hour).
  static String formatTimeOfDay12h(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Normalize any stored time string to `5:00 PM`. Falls back to raw.
  static String formatTime12h(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = tryParseTimeOfDay(raw);
    if (parsed == null) return raw.trim();
    return formatTimeOfDay12h(parsed);
  }

  /// `Sep 12, 2026 · 5:00 PM - 7:00 PM` style range from raw fields.
  static String formatDateTimeRange({
    String? date,
    String? startTime,
    String? endTime,
  }) {
    final parts = <String>[];
    final dateText = formatDateDisplay(date);
    if (dateText.isNotEmpty) parts.add(dateText);

    final start = formatTime12h(startTime);
    final end = formatTime12h(endTime);
    if (start.isNotEmpty && end.isNotEmpty) {
      parts.add('$start - $end');
    } else if (start.isNotEmpty) {
      parts.add(start);
    } else if (end.isNotEmpty) {
      parts.add(end);
    }
    return parts.join(' · ');
  }
}
