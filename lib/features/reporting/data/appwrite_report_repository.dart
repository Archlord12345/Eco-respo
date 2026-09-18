import 'dart:async';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eco_responsable/core/appwrite/appwrite_client.dart';
import 'package:eco_responsable/core/appwrite/appwrite_config.dart';
import 'package:eco_responsable/core/error/app_exceptions.dart';
import 'package:eco_responsable/core/offline/sync_queue.dart';
import 'package:eco_responsable/shared/models/collection_request.dart';
import 'package:eco_responsable/shared/models/collector.dart';
import 'package:eco_responsable/shared/models/reward_item.dart';
import 'package:eco_responsable/shared/models/waste_report.dart';
import 'package:eco_responsable/features/reporting/domain/repositories/report_repository.dart';

String _aw(Object e) => e is AppwriteException ? (e.message ?? 'Erreur Appwrite') : e.toString();

class AppwriteReportRepository implements ReportRepository {
  AppwriteReportRepository(this._db, this._realtime, this._queue);

  final Databases _db;
  final Realtime _realtime;
  final SyncQueue _queue;

  @override
  Future<List<WasteReport>> listMine(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollection,
        queries: [Query.equal('authorId', userId), Query.orderDesc('\$createdAt')],
      );
      return res.documents.map(_mapReport).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<List<WasteReport>> listAll({String? status, String? search}) async {
    try {
      final queries = <String>[Query.orderDesc('\$createdAt'), Query.limit(100)];
      if (status != null && status.isNotEmpty && status != 'Tous') {
        queries.add(Query.equal('status', status));
      }
      if (search != null && search.isNotEmpty) {
        queries.add(Query.contains('address', search));
      }
      final res = await _db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollection,
        queries: queries,
      );
      return res.documents.map(_mapReport).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<WasteReport> getById(String id) async {
    final doc = await _db.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.reportsCollection,
      documentId: id,
    );
    return _mapReport(doc);
  }

  @override
  Future<WasteReport> create(WasteReport report) async {
    try {
      final doc = await _db.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollection,
        documentId: ID.unique(),
        data: report.toMap(),
        permissions: [
          Permission.read(Role.user(report.authorId)),
          Permission.update(Role.user(report.authorId)),
          Permission.read(Role.users()),
          Permission.update(Role.users()),
        ],
      );
      return _mapReport(doc);
    } catch (e) {
      await _queue.enqueue(type: 'waste_report', payload: report.toMap());
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<WasteReport> updateStatus(String id, String status, {String? operatorId}) async {
    final data = <String, dynamic>{'status': status};
    if (operatorId != null) data['assignedOperatorId'] = operatorId;
    final doc = await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.reportsCollection,
      documentId: id,
      data: data,
    );
    return _mapReport(doc);
  }

  @override
  Stream<List<WasteReport>> watchAll() {
    final controller = StreamController<List<WasteReport>>();
    listAll().then(controller.add).catchError((_) {});
    final sub = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.reportsCollection}.documents',
    ]);
    sub.stream.listen((_) async {
      controller.add(await listAll());
    });
    controller.onCancel = sub.close;
    return controller.stream;
  }

  WasteReport _mapReport(models.Document doc) =>
      WasteReport.fromMap(doc.data, id: doc.$id);
}

class AppwriteCollectionRequestRepository implements CollectionRequestRepository {
  AppwriteCollectionRequestRepository(this._db, this._functions);

  final Databases _db;
  final Functions _functions;

  @override
  Future<List<CollectionRequest>> listMine(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.requestsCollection,
      queries: [Query.equal('authorId', userId), Query.orderDesc('\$createdAt')],
    );
    return res.documents
        .map((d) => CollectionRequest.fromMap(d.data, id: d.$id))
        .toList();
  }

  @override
  Future<List<CollectionRequest>> listForCollector(String collectorId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.requestsCollection,
      queries: [
        Query.equal('assignedCollectorId', collectorId),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return res.documents
        .map((d) => CollectionRequest.fromMap(d.data, id: d.$id))
        .toList();
  }

  @override
  Future<CollectionRequest> create(CollectionRequest request) async {
    final doc = await _db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.requestsCollection,
      documentId: ID.unique(),
      data: request.toMap(),
    );
    // Valkey: agrégé côté Appwrite Function, consommé ici via HTTP
    try {
      await _functions.createExecution(
        functionId: AppwriteConfig.matchCollectorFn,
        body: '{"requestId":"${doc.$id}"}',
      );
    } catch (_) {}
    return CollectionRequest.fromMap(doc.data, id: doc.$id);
  }

  @override
  Future<CollectionRequest> update(CollectionRequest request) async {
    final doc = await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.requestsCollection,
      documentId: request.id,
      data: request.toMap(),
    );
    return CollectionRequest.fromMap(doc.data, id: doc.$id);
  }
}

class AppwriteCollectorRepository implements CollectorRepository {
  AppwriteCollectorRepository(this._db);
  final Databases _db;

  @override
  Future<List<Collector>> list() async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.collectorsCollection,
    );
    return res.documents.map((d) => Collector.fromMap(d.data, id: d.$id)).toList();
  }

  @override
  Future<Collector?> byUserId(String userId) async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.collectorsCollection,
      queries: [Query.equal('userId', userId)],
    );
    if (res.documents.isEmpty) return null;
    return Collector.fromMap(res.documents.first.data, id: res.documents.first.$id);
  }

  @override
  Future<void> setAvailability(String id, bool available) async {
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.collectorsCollection,
      documentId: id,
      data: {'isAvailable': available},
    );
  }
}

class AppwriteRewardRepository implements RewardRepository {
  AppwriteRewardRepository(this._db, this._functions);
  final Databases _db;
  final Functions _functions;

  @override
  Future<List<RewardItem>> catalog() async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.rewardsCollection,
    );
    return res.documents.map((d) => RewardItem.fromMap(d.data, id: d.$id)).toList();
  }

  @override
  Future<int> redeem({required String userId, required String itemId}) async {
    // Valkey: agrégé côté Appwrite Function, consommé ici via HTTP
    try {
      final ex = await _functions.createExecution(
        functionId: AppwriteConfig.computeRewardPointsFn,
        body: '{"userId":"$userId","itemId":"$itemId","action":"redeem"}',
      );
      return int.tryParse(ex.responseBody) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> leaderboard() async {
    // Valkey: agrégé côté Appwrite Function, consommé ici via HTTP
    try {
      final ex = await _functions.createExecution(
        functionId: AppwriteConfig.computeRewardPointsFn,
        body: '{"action":"leaderboard"}',
      );
      return [
        {'name': 'Classement', 'points': ex.responseBody},
      ];
    } catch (_) {
      final users = await _db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        queries: [Query.orderDesc('points'), Query.limit(10)],
      );
      return users.documents
          .map((d) => {'name': d.data['name'], 'points': d.data['points']})
          .toList();
    }
  }
}

class AppwriteZoneRepository implements ZoneRepository {
  AppwriteZoneRepository(this._db);
  final Databases _db;

  @override
  Future<List<Zone>> list() async {
    final res = await _db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.zonesCollection,
    );
    return res.documents.map((d) => Zone.fromMap(d.data, id: d.$id)).toList();
  }

  @override
  Future<void> assignOperator(String zoneId, String operatorId) async {
    final doc = await _db.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.zonesCollection,
      documentId: zoneId,
    );
    final ops = [...(doc.data['assignedOperators'] as List? ?? []), operatorId];
    await _db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.zonesCollection,
      documentId: zoneId,
      data: {'assignedOperators': ops.toSet().toList()},
    );
  }
}

class AppwritePaymentService implements PaymentService {
  AppwritePaymentService(this._functions);
  final Functions _functions;

  @override
  Future<String> startCheckout({
    required String provider,
    required int amountXaf,
    required String requestId,
  }) async {
    try {
      final ex = await _functions.createExecution(
        functionId: AppwriteConfig.paymentWebhookFn,
        body:
            '{"provider":"$provider","amount":$amountXaf,"requestId":"$requestId"}',
      );
      return ex.responseBody;
    } catch (e) {
      return 'pending';
    }
  }
}

class StorageUploader {
  StorageUploader(this._storage);
  final Storage _storage;

  Future<String> uploadReportPhoto({
    required String filename,
    required Uint8List bytes,
  }) async {
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.reportPhotosBucket,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: bytes, filename: filename),
    );
    return file.$id;
  }

  Future<String> uploadProof({
    required String filename,
    required Uint8List bytes,
  }) async {
    final file = await _storage.createFile(
      bucketId: AppwriteConfig.collectionProofsBucket,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: bytes, filename: filename),
    );
    return file.$id;
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return AppwriteReportRepository(
    ref.watch(databasesProvider),
    ref.watch(realtimeProvider),
    SyncQueue(),
  );
});

final requestRepositoryProvider = Provider<CollectionRequestRepository>((ref) {
  return AppwriteCollectionRequestRepository(
    ref.watch(databasesProvider),
    ref.watch(functionsProvider),
  );
});

final collectorRepositoryProvider = Provider<CollectorRepository>((ref) {
  return AppwriteCollectorRepository(ref.watch(databasesProvider));
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return AppwriteRewardRepository(
    ref.watch(databasesProvider),
    ref.watch(functionsProvider),
  );
});

final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  return AppwriteZoneRepository(ref.watch(databasesProvider));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return AppwritePaymentService(ref.watch(functionsProvider));
});

final storageUploaderProvider = Provider<StorageUploader>((ref) {
  return StorageUploader(ref.watch(storageProvider));
});
