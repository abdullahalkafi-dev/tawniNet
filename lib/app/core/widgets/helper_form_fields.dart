import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';

/// Proper names, the same in every app language.
const kMoroccanCities = [
  'Agadir', 'Al Hoceima', 'Asilah', 'Azrou', 'Beni Mellal', 'Berkane', 'Berrechid', 'Casablanca',
  'Chefchaouen', 'Dakhla', 'El Jadida', 'Errachidia', 'Essaouira', 'Fes', 'Guelmim', 'Ifrane',
  'Kenitra', 'Khemisset', 'Khouribga', 'Laayoune', 'Larache', 'Marrakech', 'Meknes', 'Mohammedia',
  'Nador', 'Ouarzazate', 'Oujda', 'Rabat', 'Safi', 'Sale', 'Settat', 'Sidi Kacem', 'Tangier',
  'Taza', 'Temara', 'Tetouan', 'Tiznit',
];

/// Languages a helper can speak: stored value (English name, like the rest of
/// the data, e.g. "Arabic, French") → translation key shown to the user.
const kHelperLanguageOptions = {
  'Arabic': 'helper_lang_arabic',
  'Moroccan Arabic': 'helper_lang_darija',
  'French': 'helper_lang_french',
  'English': 'helper_lang_english',
  'Amazigh': 'helper_lang_amazigh',
  'Spanish': 'helper_lang_spanish',
};

/// Keeps only the known language names out of a stored "A, B" string.
List<String> parseHelperLanguages(String? stored) => (stored ?? '')
    .split(RegExp(r'[,;]'))
    .map((e) => e.trim())
    .where(kHelperLanguageOptions.containsKey)
    .toList();

/// Returns the list city that matches [city] (or, failing that, appears in
/// [address]); null when nothing matches.
String? matchMoroccanCity(String? city, [String? address]) {
  final c = (city ?? '').trim().toLowerCase();
  for (final name in kMoroccanCities) {
    if (name.toLowerCase() == c) return name;
  }
  final a = (address ?? '').toLowerCase();
  if (a.isEmpty) return null;
  for (final name in kMoroccanCities) {
    if (a.contains(name.toLowerCase())) return name;
  }
  return null;
}

class CityDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const CityDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('apply_city_label'.tr, style: AppStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.inputFillColor,
            border: Border.all(color: context.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: context.cardColor,
              isExpanded: true,
              hint: Text('apply_city_select'.tr, style: AppStyles.bodyMedium.copyWith(color: context.textHintColor)),
              items: kMoroccanCities
                  .map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: TextStyle(color: context.textPrimaryColor)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class LanguageChips extends StatelessWidget {
  final List<String> selected;
  final void Function(String language, bool on) onToggle;

  const LanguageChips({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('apply_languages_label'.tr, style: AppStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kHelperLanguageOptions.entries.map((e) {
            final on = selected.contains(e.key);
            return FilterChip(
              label: Text(e.value.tr),
              selected: on,
              showCheckmark: false,
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              side: BorderSide(color: on ? AppColors.primary : context.borderSubtle),
              onSelected: (v) => onToggle(e.key, v),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// City centres (lat, lon), used when the user picks a city instead of an
/// exact address (always works, even when address search is unavailable).
const kMoroccanCityCenters = <String, List<double>>{
  'Agadir': [30.4278, -9.5981], 'Al Hoceima': [35.2517, -3.9372], 'Asilah': [35.4650, -6.0340],
  'Azrou': [33.4342, -5.2210], 'Beni Mellal': [32.3373, -6.3498], 'Berkane': [34.9200, -2.3200],
  'Berrechid': [33.2655, -7.5875], 'Casablanca': [33.5731, -7.5898], 'Chefchaouen': [35.1688, -5.2636],
  'Dakhla': [23.6848, -15.9580], 'El Jadida': [33.2316, -8.5007], 'Errachidia': [31.9314, -4.4244],
  'Essaouira': [31.5085, -9.7595], 'Fes': [34.0331, -5.0003], 'Guelmim': [28.9870, -10.0574],
  'Ifrane': [33.5228, -5.1100], 'Kenitra': [34.2610, -6.5802], 'Khemisset': [33.8244, -6.0663],
  'Khouribga': [32.8811, -6.9063], 'Laayoune': [27.1253, -13.1625], 'Larache': [35.1932, -6.1557],
  'Marrakech': [31.6295, -7.9811], 'Meknes': [33.8935, -5.5473], 'Mohammedia': [33.6866, -7.3830],
  'Nador': [35.1681, -2.9335], 'Ouarzazate': [30.9335, -6.9370], 'Oujda': [34.6814, -1.9086],
  'Rabat': [34.0209, -6.8416], 'Safi': [32.2994, -9.2372], 'Sale': [34.0531, -6.7985],
  'Settat': [33.0010, -7.6166], 'Sidi Kacem': [34.2214, -5.7070], 'Tangier': [35.7595, -5.8340],
  'Taza': [34.2100, -4.0100], 'Temara': [33.9287, -6.9068], 'Tetouan': [35.5785, -5.3684],
  'Tiznit': [29.6974, -9.7316],
};
