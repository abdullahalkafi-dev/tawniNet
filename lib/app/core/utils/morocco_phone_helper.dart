class MoroccoPhoneHelper {
  static final RegExp mobileRegex = RegExp(r'^\+212[67]\d{8}$');
  static final RegExp rawInputRegex = RegExp(r'^(\+212|00212|0)?[67]\d{8}$');

  /// Normalizes any Moroccan phone input to standard international +2126XXXXXXXX or +2127XXXXXXXX
  static String normalize(String input) {
    String cleaned = input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('00212')) {
      cleaned = '+212${cleaned.substring(5)}';
    } else if (cleaned.startsWith('212') && !cleaned.startsWith('+212')) {
      cleaned = '+$cleaned';
    } else if (cleaned.startsWith('06') || cleaned.startsWith('07')) {
      cleaned = '+212${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+212') && (cleaned.startsWith('6') || cleaned.startsWith('7')) && cleaned.length == 9) {
      cleaned = '+212$cleaned';
    }

    return cleaned;
  }

  /// Formats a phone number for user-friendly display: +212 6 12 34 56 78
  static String formatDisplay(String phone) {
    final normalized = normalize(phone);
    if (normalized.length == 13 && normalized.startsWith('+212')) {
      final prefix = normalized.substring(0, 4); // +212
      final lead = normalized.substring(4, 5);   // 6 or 7
      final p1 = normalized.substring(5, 7);
      final p2 = normalized.substring(7, 9);
      final p3 = normalized.substring(9, 11);
      final p4 = normalized.substring(11, 13);
      return '$prefix $lead $p1 $p2 $p3 $p4';
    }
    return phone;
  }

  /// Formats local display: 06 12 34 56 78
  static String formatLocalDisplay(String phone) {
    final normalized = normalize(phone);
    if (normalized.length == 13 && normalized.startsWith('+212')) {
      final local = '0${normalized.substring(4)}';
      final lead = local.substring(0, 2);
      final p1 = local.substring(2, 4);
      final p2 = local.substring(4, 6);
      final p3 = local.substring(6, 8);
      final p4 = local.substring(8, 10);
      return '$lead $p1 $p2 $p3 $p4';
    }
    return phone;
  }

  /// Validates Moroccan mobile phone number input
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('05') || cleaned.startsWith('+2125') || cleaned.startsWith('002125') || cleaned.startsWith('2125')) {
      return 'Please enter a mobile phone number (06 or 07) to receive your WhatsApp code';
    }

    final normalized = normalize(cleaned);
    if (!mobileRegex.hasMatch(normalized)) {
      return 'Enter a valid Moroccan mobile number (e.g. 06 12 34 56 78 or +212 6...)';
    }

    return null;
  }
}
