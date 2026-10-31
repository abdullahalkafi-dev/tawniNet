import 'package:get/get.dart';
import 'en_US.dart';
import 'ar_MA.dart';
import 'fr_FR.dart';
import 'es_ES.dart';
import 'extra_translations.dart';
import 'ui_translations.dart';

class AppTranslations extends Translations {
  static Map<String, String> _withExtra(Map<String, String> base, int index) {
    final merged = Map<String, String>.from(base);
    for (final extra in [kExtraTranslations, kUiTranslations]) {
      extra.forEach((key, texts) {
        merged[key] = texts[index];
      });
    }
    return merged;
  }

  // Built once: GetX reads `keys` on every locale change.
  static final Map<String, Map<String, String>> _keys = {
    'en_US': _withExtra(enUS, 0),
    'fr_FR': _withExtra(frFR, 1),
    'ar_MA': _withExtra(arMA, 2),
    'es_ES': _withExtra(esES, 3),
  };

  @override
  Map<String, Map<String, String>> get keys => _keys;
}
