import 'package:flutter/painting.dart';

class AppAssets {
  /// Nom du package Flutter qui embarque les visuels (`eco_core`).
  static const package = 'eco_core';

  /// [ImageProvider] prêt à l'emploi pour `CircleAvatar`, `DecorationImage`…
  static AssetImage image(String asset) => AssetImage(asset, package: package);

  static const logo = 'assets/images/logos/logo.png';
  static const logoWhite = 'assets/images/logos/logo_white.png';
  static const welcomeHero = 'assets/images/auth/welcome_hero.png';
  static const welcomeWorker = 'assets/images/auth/welcome_worker.png';
  static const welcomeCity = 'assets/images/auth/welcome_city.png';
  static const onboarding1 = 'assets/images/auth/onboarding_1.png';
  static const onboarding2 = 'assets/images/auth/onboarding_2.png';
  static const onboarding3 = 'assets/images/auth/onboarding_3.png';
  static const cameroonFlag = 'assets/images/shared/cameroon_flag.png';
  static const otpPhone = 'assets/images/shared/otp_phone.png';
  static const avatarPlaceholder = 'assets/images/profile/avatar_placeholder.png';
  static const avatarMoussa = 'assets/images/profile/avatar_moussa.png';
  static const avatarSandrine = 'assets/images/profile/avatar_sandrine.png';
  static const leafDeco = 'assets/images/profile/leaf_deco.png';
  static const notifCollecte = 'assets/images/profile/notif_collecte.png';
  static const notifPoints = 'assets/images/profile/notif_points.png';
  static const notifMap = 'assets/images/profile/notif_map.png';
  static const rewardMtn = 'assets/images/rewards/reward_mtn.png';
  static const rewardVoucher = 'assets/images/rewards/reward_voucher.png';
  static const rewardPartner = 'assets/images/rewards/reward_partner.png';
  static const badgeBronze = 'assets/images/rewards/badge_bronze.png';
  static const badgeSilver = 'assets/images/rewards/badge_silver.png';
  static const badgeGold = 'assets/images/rewards/badge_gold.png';
  static const reportDump = 'assets/images/reporting/report_dump.png';
  static const reportBin = 'assets/images/reporting/report_bin.png';
  static const reportHousehold = 'assets/images/reporting/report_household.png';
  static const dumpPhoto = 'assets/images/reporting/dump_photo.png';
  static const reportDetailPhoto = 'assets/images/reporting/report_detail_photo.png';
  static const proofPlaceholder = 'assets/images/reporting/proof_placeholder.png';
  static const collectorTruck = 'assets/images/reporting/collector_truck.png';
  // Les cartes sont toujours de vraies cartes (flutter_map) : aucun visuel statique.
  static const iconRecycle = 'assets/images/map/icon_recycle.png';
  static const iconCity = 'assets/images/map/icon_city.png';
  static const iconCitizens = 'assets/images/map/icon_citizens.png';
  static const iconCameroon = 'assets/images/map/icon_cameroon.png';
  static const mtnMomo = 'assets/images/payments/mtn_momo.png';
  static const orangeMoney = 'assets/images/payments/orange_money.png';
  static const afriland = 'assets/images/payments/afriland.png';
  static const iconTri = 'assets/images/payments/icon_tri.png';

  /// Visuels « photo » (pleins bords, à recadrer en `cover`). Tout le reste
  /// est une illustration ou une icône à fond transparent (`contain`).
  static const photos = <String>{
    welcomeHero,
    welcomeWorker,
    welcomeCity,
    onboarding1,
    onboarding2,
    onboarding3,
    avatarMoussa,
    avatarSandrine,
    dumpPhoto,
    reportDetailPhoto,
    proofPlaceholder,
    collectorTruck,
    cameroonFlag,
  };

  static bool isPhoto(String asset) => photos.contains(asset);
}
