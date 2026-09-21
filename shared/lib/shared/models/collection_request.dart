import 'enums.dart';

class CollectionRequest {
  const CollectionRequest({
    required this.id,
    required this.authorId,
    required this.wasteType,
    required this.estimatedVolume,
    required this.status,
    this.scheduledAt,
    this.assignedCollectorId,
    this.amountPaid = 0,
    this.isRecurring = false,
    this.paymentProvider,
    this.weightKg,
    this.proofFileId,
    this.address = '',
    this.timeSlot = '',
    this.city = 'Yaoundé',
    this.lat,
    this.lng,
    this.collectedAt,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String authorId;
  final WasteCategory wasteType;
  final VolumeSize estimatedVolume;
  final DateTime? scheduledAt;
  final RequestStatus status;
  final String? assignedCollectorId;
  final int amountPaid;
  final bool isRecurring;
  final String? paymentProvider;
  final double? weightKg;
  final String? proofFileId;
  final String address;
  final String timeSlot;
  final String city;
  final double? lat;
  final double? lng;
  final DateTime? collectedAt;
  final String notes;
  final DateTime? createdAt;

  bool get hasPosition => lat != null && lng != null && lat != 0 && lng != 0;

  factory CollectionRequest.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return CollectionRequest(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      wasteType: WasteCategory.values.firstWhere(
        (e) => e.name == map['wasteType'],
        orElse: () => WasteCategory.menager,
      ),
      estimatedVolume: VolumeSizeX.parse(map['estimatedVolume'] as String?),
      scheduledAt: DateTime.tryParse(map['scheduledAt'] as String? ?? ''),
      status: RequestStatusX.parse(map['status'] as String?),
      assignedCollectorId: map['assignedCollectorId'] as String?,
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      isRecurring: map['isRecurring'] as bool? ?? false,
      paymentProvider: map['paymentProvider'] as String?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      proofFileId: map['proofFileId'] as String?,
      address: map['address'] as String? ?? '',
      timeSlot: map['timeSlot'] as String? ?? '',
      city: map['city'] as String? ?? 'Yaoundé',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      collectedAt: DateTime.tryParse(map['collectedAt'] as String? ?? ''),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['\$createdAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'wasteType': wasteType.name,
        'estimatedVolume': estimatedVolume.wire,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'status': status.name,
        'assignedCollectorId': assignedCollectorId,
        'amountPaid': amountPaid,
        'isRecurring': isRecurring,
        'paymentProvider': paymentProvider,
        'weightKg': weightKg,
        'proofFileId': proofFileId,
        'address': address,
        'timeSlot': timeSlot,
        'city': city,
        'lat': lat,
        'lng': lng,
        'collectedAt': collectedAt?.toIso8601String(),
        'notes': notes,
      };

  CollectionRequest copyWith({
    RequestStatus? status,
    String? assignedCollectorId,
    double? weightKg,
    String? proofFileId,
    DateTime? scheduledAt,
    DateTime? collectedAt,
    int? amountPaid,
    String? notes,
  }) {
    return CollectionRequest(
      id: id,
      authorId: authorId,
      wasteType: wasteType,
      estimatedVolume: estimatedVolume,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      assignedCollectorId: assignedCollectorId ?? this.assignedCollectorId,
      amountPaid: amountPaid ?? this.amountPaid,
      isRecurring: isRecurring,
      paymentProvider: paymentProvider,
      weightKg: weightKg ?? this.weightKg,
      proofFileId: proofFileId ?? this.proofFileId,
      address: address,
      timeSlot: timeSlot,
      city: city,
      lat: lat,
      lng: lng,
      collectedAt: collectedAt ?? this.collectedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
