import 'package:eco_core/shared/models/collection_request.dart';
import 'package:eco_core/shared/models/collector.dart';
import 'package:eco_core/shared/models/reward_item.dart';
import 'package:eco_core/shared/models/waste_report.dart';

abstract class ReportRepository {
  Future<List<WasteReport>> listMine(String userId);
  Future<List<WasteReport>> listAll({String? status, String? search});
  Future<WasteReport> getById(String id);
  Future<WasteReport> create(WasteReport report);
  Future<WasteReport> updateStatus(String id, String status, {String? operatorId});
  Stream<List<WasteReport>> watchAll();
}

abstract class CollectionRequestRepository {
  Future<List<CollectionRequest>> listMine(String userId);
  Future<List<CollectionRequest>> listForCollector(String collectorId);

  /// Demandes en attente d'un collecteur, éventuellement filtrées par ville.
  Future<List<CollectionRequest>> listPending({String? city});

  /// Toutes les demandes (back-office), éventuellement filtrées par statut.
  Future<List<CollectionRequest>> listAll({String? status, int limit = 200});
  Future<CollectionRequest> getById(String id);
  Future<CollectionRequest> create(CollectionRequest request);
  Future<CollectionRequest> update(CollectionRequest request);

  /// Affecte un collecteur et passe la demande en `matched`.
  Future<CollectionRequest> assign(String requestId, String collectorId);

  /// Met à jour le statut ; `weightKg` / `proofFileId` lors de la confirmation.
  Future<CollectionRequest> updateStatus(
    String requestId,
    String status, {
    double? weightKg,
    String? proofFileId,
    DateTime? collectedAt,
  });

  /// Flux temps réel d'une demande (suivi citoyen).
  Stream<CollectionRequest> watchOne(String requestId);
}

abstract class CollectorRepository {
  Future<List<Collector>> list({String? company});
  Future<Collector?> byUserId(String userId);
  Future<Collector?> byId(String id);
  Future<void> setAvailability(String id, bool available);
  Future<Collector> upsert(Collector collector);
  Future<void> incrementInterventions(String id);
}

abstract class RewardRepository {
  Future<List<RewardItem>> catalog();
  Future<int> redeem({required String userId, required String itemId});
  Future<List<Map<String, dynamic>>> leaderboard();
}

abstract class ZoneRepository {
  Future<List<Zone>> list();
  Future<void> assignOperator(String zoneId, String operatorId);
  Future<void> setOperators(String zoneId, List<String> operatorIds);
}

abstract class NotificationRepository {
  Future<List<AppNotification>> listMine(String userId, {int limit = 50});
  Future<void> markRead(String id);
  Future<void> markAllRead(String userId);
  Future<void> create(AppNotification notification);
  Stream<List<AppNotification>> watchMine(String userId);
}

abstract class PaymentService {
  Future<String> startCheckout({
    required String provider,
    required int amountXaf,
    required String requestId,
  });
}
