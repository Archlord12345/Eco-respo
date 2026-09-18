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
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      assignedCollectorId: map['assignedCollectorId'] as String?,
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      isRecurring: map['isRecurring'] as bool? ?? false,
      paymentProvider: map['paymentProvider'] as String?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      proofFileId: map['proofFileId'] as String?,
      address: map['address'] as String? ?? '',
      timeSlot: map['timeSlot'] as String? ?? '',
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
      };
}
