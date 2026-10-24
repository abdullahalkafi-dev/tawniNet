import 'package:get/get.dart';
import 'en_US.dart';
import 'ar_MA.dart';
import 'fr_FR.dart';
import 'es_ES.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'ar_MA': arMA,
        'fr_FR': frFR,
        'es_ES': esES,
      };
}
