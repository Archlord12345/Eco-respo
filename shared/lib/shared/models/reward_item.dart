import 'enums.dart';

class RewardItem {
  const RewardItem({
    required this.id,
    required this.type,
    required this.pointsCost,
    required this.title,
    this.description = '',
    this.imageKey = 'reward_voucher',
    this.enabled = true,
  });

  final String id;
  final RewardType type;
  final int pointsCost;
  final String title;
  final String description;
  final String imageKey;
  final bool enabled;

  factory RewardItem.fromMap(Map<String, dynamic> map, {required String id}) {
    return RewardItem(
      id: id,
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.voucher,
      ),
      pointsCost: (map['pointsCost'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageKey: map['imageKey'] as String? ?? 'reward_voucher',
      enabled: map['enabled'] as bool? ?? true,
    );
  }
}

class Zone {
  const Zone({
    required this.id,
    required this.city,
    required this.district,
    required this.assignedOperators,
    this.collectionFrequency = '',
    this.color = '#2E7D32',
    this.centerLat = 3.848,
    this.centerLng = 11.502,
  });

  final String id;
  final String city;
  final String district;
  final List<String> assignedOperators;
  final String collectionFrequency;
  final String color;
  final double centerLat;
  final double centerLng;

  factory Zone.fromMap(Map<String, dynamic> map, {required String id}) {
    return Zone(
      id: id,
      city: map['city'] as String? ?? 'Yaoundé',
      district: map['district'] as String? ?? '',
      assignedOperators:
          (map['assignedOperators'] as List?)?.cast<String>() ?? const [],
      collectionFrequency: map['collectionFrequency'] as String? ?? '',
      color: map['color'] as String? ?? '#2E7D32',
      centerLat: (map['centerLat'] as num?)?.toDouble() ?? 3.848,
      centerLng: (map['centerLng'] as num?)?.toDouble() ?? 11.502,
    );
  }

  Map<String, dynamic> toMap() => {
        'city': city,
        'district': district,
        'assignedOperators': assignedOperators,
        'collectionFrequency': collectionFrequency,
        'color': color,
        'centerLat': centerLat,
        'centerLng': centerLng,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    this.read = false,
    this.refType,
    this.refId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String kind;
  final bool read;
  final DateTime createdAt;
  final String? refType;
  final String? refId;

  /// Route à ouvrir au tap (détail signalement / suivi demande).
  String? get targetRoute => switch (refType) {
        'report' when refId != null => '/report/$refId',
        'request' when refId != null => '/collect/$refId',
        'collector_request' when refId != null => '/collector/stop/$refId',
        _ => null,
      };

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'kind': kind,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        'refType': refType,
        'refId': refId,
      };

  factory AppNotification.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AppNotification(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      kind: map['kind'] as String? ?? 'info',
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(
            map['createdAt'] as String? ?? map['\$createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      refType: map['refType'] as String?,
      refId: map['refId'] as String?,
    );
  }
}
