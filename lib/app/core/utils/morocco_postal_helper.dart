class MoroccoPostalHelper {
  MoroccoPostalHelper._();

  static const Map<String, String> regionPrefixes = {
    '10': 'Rabat / Témara',
    '11': 'Salé',
    '12': 'Kénitra',
    '13': 'Sidi Kacem / Sidi Slimane',
    '14': 'Khemisset',
    '20': 'Casablanca Centre / Anfa',
    '21': 'Casablanca Hay Hassani / Ain Chock',
    '22': 'Casablanca Ain Sebaa / Sidi Bernoussi',
    '23': 'Mohammédia',
    '24': 'El Jadida',
    '25': 'Settat',
    '26': 'Benslimane',
    '27': 'Berrechid',
    '30': 'Fès',
    '31': 'Sefrou',
    '33': 'Boulemane',
    '34': 'Moulay Yacoub',
    '35': 'Taza',
    '40': 'Marrakech',
    '41': 'Al Haouz',
    '42': 'Chichaoua',
    '43': 'El Kelaa des Sraghna',
    '44': 'Essaouira',
    '46': 'Safi',
    '50': 'Meknès',
    '51': 'El Hajeb',
    '52': 'Errachidia',
    '53': 'Ifrane / Midelt',
    '60': 'Oujda',
    '61': 'Jerada',
    '62': 'Nador / Driouch',
    '63': 'Berkane',
    '64': 'Taourirt',
    '70': 'Guelmim / Tan-Tan',
    '71': 'Laâyoune',
    '72': 'Boujdour',
    '73': 'Dakhla',
    '80': 'Agadir / Ida-Outanane',
    '81': 'Inezgane / Ait Melloul',
    '82': 'Chtouka Ait Baha',
    '83': 'Taroudant',
    '84': 'Tiznit',
    '85': 'Tata',
    '90': 'Tanger / Asilah',
    '91': 'Fahs Anjra',
    '92': 'Larache / Ksar El Kebir',
    '93': 'Tétouan / Mdiq / Fnideq',
    '94': 'Chefchaouen / Ouezzane',
    '95': 'Al Hoceïma',
  };

  /// Check if the input is a valid 5-digit Moroccan Postal Code
  static bool isValidPostalCode(String input) {
    final clean = input.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(clean)) {
      return false;
    }
    final prefix = clean.substring(0, 2);
    final prefixNum = int.tryParse(prefix) ?? 0;
    return prefixNum >= 10 && prefixNum <= 95;
  }

  /// Get the region name from a 5-digit postal code
  static String? getRegionForPostalCode(String postalCode) {
    final clean = postalCode.trim();
    if (clean.length < 2) return null;
    final prefix = clean.substring(0, 2);
    return regionPrefixes[prefix];
  }

  /// Validates a city / zip code string (e.g. "Casablanca 20000" or "20000" or "Casablanca")
  static String? validateCityZip(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Please enter your City and Zip Code (e.g. Casablanca 20000)';
    }

    final trimmed = input.trim();

    // Check if contains a 5-digit number
    final match = RegExp(r'\b\d{5}\b').firstMatch(trimmed);
    if (match != null) {
      final code = match.group(0)!;
      if (!isValidPostalCode(code)) {
        return 'Please enter a valid 5-digit Moroccan postal code (10000 to 95000)';
      }
    }

    if (trimmed.length < 3) {
      return 'Please enter a valid Moroccan city or postal code';
    }

    return null;
  }
}
