import 'package:latlong2/latlong.dart';

class AppConstants {
  static const appName = 'Éco-Responsable';
  static const tagline = 'Ensemble pour un Cameroun plus propre';
  static const countryCode = '+237';
  static const phonePrefix = '+237 ';
  static const yaounde = LatLng(3.8480, 11.5021);
  static const douala = LatLng(4.0511, 9.7679);
  static const defaultCity = 'Yaoundé';

  static const cities = ['Yaoundé', 'Douala', 'Bafoussam', 'Garoua', 'Bamenda', 'Maroua'];

  static LatLng centerFor(String city) => switch (city) {
        'Douala' => douala,
        'Bafoussam' => const LatLng(5.4737, 10.4179),
        'Garoua' => const LatLng(9.3017, 13.3921),
        'Bamenda' => const LatLng(5.9631, 10.1591),
        'Maroua' => const LatLng(10.5910, 14.3159),
        _ => yaounde,
      };

  /// Facteurs d'impact indicatifs (kg de déchets valorisés → CO₂ évité).
  static const co2PerKg = 0.7;

  /// Points attribués par kilogramme collecté (repli local de
  /// `computeRewardPoints`).
  static const pointsPerKg = 10;

  /// Rémunération indicative du collecteur en FCFA par kg (planche 6).
  static const collectorFeePerKg = 200;

  /// Identifiant OpenStreetMap (User-Agent des tuiles).
  static const osmUserAgent = 'com.eco.eco_responsable';
}
