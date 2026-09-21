// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Éco-Responsable';

  @override
  String get welcomeTitle =>
      'Faites de chaque citoyen un acteur de la propreté urbaine';

  @override
  String get commencer => 'Commencer';

  @override
  String get inscription => 'Inscription';

  @override
  String get phoneLabel => 'Numéro de téléphone (Cameroun)';

  @override
  String get getOtp => 'Recevoir le code OTP';

  @override
  String get valider => 'Valider';

  @override
  String get homeImpactTitle => 'Votre impact cette semaine';

  @override
  String get points => 'points';

  @override
  String get kgSorted => 'kg triés';

  @override
  String get co2Avoided => 'kg CO₂ évité';
}
