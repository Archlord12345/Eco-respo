import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/appwrite/appwrite_client.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/collector.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/reward_item.dart';
import '../../reporting/data/appwrite_report_repository.dart';

/// Actions métier d'un collecteur ou d'un dispatcher sur une demande de
/// collecte : chaque transition met la ligne à jour puis prévient le citoyen.
class CollectorActions {
  CollectorActions(this._ref);
  final Ref _ref;

  Future<void> _notify(
    String userId,
    String title,
    String body, {
    String kind = 'collecte',
    String refType = 'request',
    required String refId,
  }) {
    return _ref.read(notificationRepositoryProvider).create(
          AppNotification(
            id: '',
            userId: userId,
            title: title,
            body: body,
            kind: kind,
            createdAt: DateTime.now(),
            refType: refType,
            refId: refId,
          ),
        );
  }

  /// Un collecteur accepte une demande en attente (ou un dispatcher l'affecte).
  Future<CollectionRequest> accept(CollectionRequest request, Collector collector) async {
    final updated = await _ref.read(requestRepositoryProvider).assign(request.id, collector.id);
    final who = collector.displayName.isNotEmpty ? collector.displayName : 'Un collecteur';
    await _notify(
      request.authorId,
      'Collecteur assigné',
      '$who prend en charge votre collecte de ${request.wasteType.labelFr.toLowerCase()}'
      '${request.address.isNotEmpty ? ' à ${request.address}' : ''}.',
      refId: request.id,
    );
    if (collector.userId.isNotEmpty && collector.userId != request.authorId) {
      await _notify(
        collector.userId,
        'Nouvelle collecte à réaliser',
        '${request.wasteType.labelFr} · ${request.estimatedVolume.labelFr} · ${request.address}',
        refType: 'collector_request',
        refId: request.id,
      );
    }
    return updated;
  }

  /// Le collecteur part vers l'adresse.
  Future<CollectionRequest> start(CollectionRequest request) async {
    final updated = await _ref
        .read(requestRepositoryProvider)
        .updateStatus(request.id, RequestStatus.enRoute.wire);
    await _notify(
      request.authorId,
      'Votre collecteur est en route',
      'Arrivée estimée ${request.timeSlot.isNotEmpty ? 'sur le créneau ${request.timeSlot}' : 'dans les prochaines minutes'}.',
      kind: 'status',
      refId: request.id,
    );
    return updated;
  }

  /// Confirmation avec preuve photo et poids ; attribue les points au citoyen.
  Future<CollectionRequest> confirm(
    CollectionRequest request, {
    required double weightKg,
    Uint8List? proofBytes,
    Collector? collector,
  }) async {
    String? proofId;
    if (proofBytes != null) {
      try {
        proofId = await _ref.read(storageUploaderProvider).uploadProof(
              filename: 'proof_${request.id}.jpg',
              bytes: proofBytes,
            );
      } catch (_) {
        // La preuve est facultative : la collecte reste confirmée sans photo.
      }
    }
    final updated = await _ref.read(requestRepositoryProvider).updateStatus(
          request.id,
          RequestStatus.collected.wire,
          weightKg: weightKg,
          proofFileId: proofId,
          collectedAt: DateTime.now(),
        );
    if (collector != null) {
      await _ref.read(collectorRepositoryProvider).incrementInterventions(collector.id);
    }
    final points = (weightKg * AppConstants.pointsPerKg).round();
    await _awardPoints(request.authorId, points);
    await _notify(
      request.authorId,
      'Collecte terminée',
      '${weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1)} kg collectés. '
      'Vous gagnez $points points Éco-Responsable !',
      kind: 'points',
      refId: request.id,
    );
    return updated;
  }

  /// Annulation par le citoyen ou le dispatcher.
  Future<CollectionRequest> cancel(CollectionRequest request, {String? reason}) async {
    final updated = await _ref
        .read(requestRepositoryProvider)
        .updateStatus(request.id, RequestStatus.cancelled.wire);
    await _notify(
      request.authorId,
      'Collecte annulée',
      reason ?? 'Votre demande de collecte a été annulée.',
      kind: 'alert',
      refId: request.id,
    );
    return updated;
  }

  /// Repli local de la Function `computeRewardPoints` : incrément direct.
  Future<void> _awardPoints(String userId, int points) async {
    if (points <= 0) return;
    try {
      await _ref.read(functionsProvider).createExecution(
            functionId: AppwriteConfig.computeRewardPointsFn,
            body: '{"userId":"$userId","points":$points,"action":"award"}',
          );
      return;
    } catch (_) {}
    try {
      await _ref.read(tablesProvider).incrementRowColumn(
            databaseId: AppwriteConfig.databaseId,
            tableId: AppwriteConfig.usersCollection,
            rowId: userId,
            column: 'points',
            value: points.toDouble(),
          );
    } on AppwriteException {
      // Profil absent ou droits insuffisants : les points seront recalculés
      // par la Function lors de son déploiement.
    }
  }
}

final collectorActionsProvider = Provider<CollectorActions>(CollectorActions.new);
