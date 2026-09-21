class Collector {
  const Collector({
    required this.id,
    required this.userId,
    required this.coveredZones,
    required this.isAvailable,
    this.interventionsCount = 0,
    this.displayName = '',
    this.phone = '',
    this.company = '',
  });

  final String id;
  final String userId;
  final List<String> coveredZones;
  final bool isAvailable;
  final int interventionsCount;
  final String displayName;
  final String phone;
  final String company;

  factory Collector.fromMap(Map<String, dynamic> map, {required String id}) {
    return Collector(
      id: id,
      userId: map['userId'] as String? ?? '',
      coveredZones: (map['coveredZones'] as List?)?.cast<String>() ?? const [],
      isAvailable: map['isAvailable'] as bool? ?? false,
      interventionsCount: (map['interventionsCount'] as num?)?.toInt() ?? 0,
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      company: map['company'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'coveredZones': coveredZones,
        'isAvailable': isAvailable,
        'interventionsCount': interventionsCount,
        'displayName': displayName,
        'phone': phone,
        'company': company,
      };
}
