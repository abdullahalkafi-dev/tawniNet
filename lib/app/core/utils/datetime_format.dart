import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Shared date/time helpers.
/// Save dates as ISO `yyyy-MM-dd`. Display times as 12-hour `h:mm AM/PM`.
class AppDateTime {
  AppDateTime._();

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('MMM d, yyyy');

  /// `2026-09-12`
  static String toIsoDate(DateTime date) => _isoDate.format(date);

  /// "Now", "5 min", "3 h", "2 d", "3 w": short, localized, for lists.
  static String shortAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'chat_time_now'.tr;
    if (diff.inMinutes < 60) return 'chat_time_minutes'.trParams({'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return 'chat_time_hours'.trParams({'n': '${diff.inHours}'});
    if (diff.inDays < 7) return 'chat_time_days'.trParams({'n': '${diff.inDays}'});
    return 'chat_time_weeks'.trParams({'n': '${(diff.inDays / 7).floor()}'});
  }

  /// Local "HH:mm" of an ISO timestamp from the server (they are UTC).
  static String clockTime(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

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

  /// Shortest bookable slot, in minutes. Mirrors the backend rule.
  static const int minBookingMinutes = 30;

  /// Longest shift that may cross midnight (mirrors the backend).
  static const int maxOvernightMinutes = 12 * 60;

  /// Minutes between two time strings, or null if either is unparseable.
  /// An end at or before the start is read as "the next day" (night shift),
  /// exactly like the server does; equal times give 24 h which is rejected
  /// by [validateTimeRange].
  static int? minutesBetween(String? startRaw, String? endRaw) {
    final start = tryParseTimeOfDay(startRaw);
    final end = tryParseTimeOfDay(endRaw);
    if (start == null || end == null) return null;
    var mins = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    if (mins <= 0) mins += 24 * 60;
    return mins;
  }

  /// Hours between two times (null when unusable). Same rule as the server.
  static double? hoursBetween(String? startRaw, String? endRaw) {
    final mins = minutesBetween(startRaw, endRaw);
    return mins == null ? null : mins / 60.0;
  }

  /// Returns a translated error, or null when the range is valid.
  /// Both empty is allowed unless [required] is true.
  static String? validateTimeRange(
    String? startRaw,
    String? endRaw, {
    bool required = false,
  }) {
    final hasStart = startRaw != null && startRaw.trim().isNotEmpty;
    final hasEnd = endRaw != null && endRaw.trim().isNotEmpty;
    if (!hasStart && !hasEnd && !required) return null;
    if (!hasStart || !hasEnd) return 'time_both_required'.tr;
    final mins = minutesBetween(startRaw, endRaw);
    if (mins == null) return 'time_invalid'.tr;
    final a = tryParseTimeOfDay(startRaw)!;
    final b = tryParseTimeOfDay(endRaw)!;
    final crossesMidnight = (b.hour * 60 + b.minute) <= (a.hour * 60 + a.minute);
    if (crossesMidnight && (mins == 24 * 60 || mins > maxOvernightMinutes)) {
      return 'time_end_after_start'.tr;
    }
    if (mins < minBookingMinutes) {
      return 'time_min_duration'.trParams({'min': '$minBookingMinutes'});
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
