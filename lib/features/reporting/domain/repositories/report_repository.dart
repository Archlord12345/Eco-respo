import 'package:eco_responsable/shared/models/collection_request.dart';
import 'package:eco_responsable/shared/models/collector.dart';
import 'package:eco_responsable/shared/models/reward_item.dart';
import 'package:eco_responsable/shared/models/waste_report.dart';

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
  Future<CollectionRequest> create(CollectionRequest request);
  Future<CollectionRequest> update(CollectionRequest request);
}

abstract class CollectorRepository {
  Future<List<Collector>> list();
  Future<Collector?> byUserId(String userId);
  Future<void> setAvailability(String id, bool available);
}

abstract class RewardRepository {
  Future<List<RewardItem>> catalog();
  Future<int> redeem({required String userId, required String itemId});
  Future<List<Map<String, dynamic>>> leaderboard();
}

abstract class ZoneRepository {
  Future<List<Zone>> list();
  Future<void> assignOperator(String zoneId, String operatorId);
}

abstract class PaymentService {
  Future<String> startCheckout({
    required String provider,
    required int amountXaf,
    required String requestId,
  });
}
