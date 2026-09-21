// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Eco-Responsible';

  @override
  String get welcomeTitle =>
      'Make every citizen an actor for urban cleanliness';

  @override
  String get commencer => 'Start';

  @override
  String get inscription => 'Sign Up';

  @override
  String get phoneLabel => 'Phone Number (Cameroon)';

  @override
  String get getOtp => 'Get OTP Code';

  @override
  String get valider => 'Validate';

  @override
  String get homeImpactTitle => 'Your impact this week';

  @override
  String get points => 'points';

  @override
  String get kgSorted => 'kg sorted';

  @override
  String get co2Avoided => 'kg CO₂ avoided';
}
