import 'enums.dart';

class WasteReport {
  const WasteReport({
    required this.id,
    required this.authorId,
    required this.lat,
    required this.lng,
    required this.category,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.photoFileId,
    this.address = '',
    this.description = '',
    this.assignedOperatorId,
    this.city = 'Yaoundé',
  });

  final String id;
  final String authorId;
  final String? photoFileId;
  final double lat;
  final double lng;
  final WasteCategory category;
  final Urgency urgency;
  final ReportStatus status;
  final DateTime createdAt;
  final String address;
  final String description;
  final String? assignedOperatorId;
  final String city;

  factory WasteReport.fromMap(Map<String, dynamic> map, {required String id}) {
    return WasteReport(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      photoFileId: map['photoFileId'] as String?,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      category: WasteCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => WasteCategory.menager,
      ),
      urgency: Urgency.values.firstWhere(
        (e) => e.name == map['urgency'],
        orElse: () => Urgency.moyen,
      ),
      status: ReportStatusX.parse(map['status'] as String?),
      createdAt: DateTime.tryParse(
            map['reportedAt'] as String? ?? map['\$createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
      assignedOperatorId: map['assignedOperatorId'] as String?,
      city: map['city'] as String? ?? 'Yaoundé',
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'photoFileId': photoFileId,
        'lat': lat,
        'lng': lng,
        'category': category.name,
        'urgency': urgency.name,
        'status': status.wire,
        'address': address,
        'description': description,
        'assignedOperatorId': assignedOperatorId,
        'city': city,
        'reportedAt': createdAt.toIso8601String(),
      };
}
