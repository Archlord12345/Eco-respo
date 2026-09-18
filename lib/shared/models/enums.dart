enum UserRole { citizen, collector, admin }

enum WasteCategory { menager, plastique, electronique, encombrant }

enum Urgency { faible, moyen, eleve, critique }

enum ReportStatus { reported, inProgress, resolved }

enum RequestStatus { pending, matched, enRoute, collected, cancelled }

enum VolumeSize { petit, moyen, grand, tresGrand }

enum RewardType { mobileMoneyCredit, voucher, partnerPerk }

extension UserRoleX on UserRole {
  String get wire => name;
  static UserRole parse(String? v) => UserRole.values.firstWhere(
        (e) => e.name == v,
        orElse: () => UserRole.citizen,
      );
}

extension WasteCategoryX on WasteCategory {
  String get labelFr => switch (this) {
        WasteCategory.menager => 'Ménager',
        WasteCategory.plastique => 'Plastique',
        WasteCategory.electronique => 'Électronique',
        WasteCategory.encombrant => 'Encombrant',
      };
}

extension UrgencyX on Urgency {
  String get labelFr => switch (this) {
        Urgency.faible => 'Faible',
        Urgency.moyen => 'Moyen',
        Urgency.eleve => 'Élevé',
        Urgency.critique => 'Critique',
      };
}

extension ReportStatusX on ReportStatus {
  String get labelFr => switch (this) {
        ReportStatus.reported => 'Signalé',
        ReportStatus.inProgress => 'Pris en charge',
        ReportStatus.resolved => 'Résolu',
      };
  String get wire => name;
  static ReportStatus parse(String? v) => ReportStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ReportStatus.reported,
      );
}

extension RequestStatusX on RequestStatus {
  String get labelFr => switch (this) {
        RequestStatus.pending => 'En attente',
        RequestStatus.matched => 'Collecteur trouvé',
        RequestStatus.enRoute => 'En route',
        RequestStatus.collected => 'Collecté',
        RequestStatus.cancelled => 'Annulé',
      };
}

extension VolumeSizeX on VolumeSize {
  String get wire => switch (this) {
        VolumeSize.tresGrand => 'tres_grand',
        _ => name,
      };
  String get labelFr => switch (this) {
        VolumeSize.petit => 'Petit (1-5 kg)',
        VolumeSize.moyen => 'Moyen (5-20 kg)',
        VolumeSize.grand => 'Grand (20-50 kg)',
        VolumeSize.tresGrand => 'Très grand (+50 kg)',
      };
  static VolumeSize parse(String? v) {
    if (v == 'tres_grand') return VolumeSize.tresGrand;
    return VolumeSize.values.firstWhere(
      (e) => e.name == v,
      orElse: () => VolumeSize.petit,
    );
  }
}
