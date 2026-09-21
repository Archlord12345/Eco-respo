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

const _db = AppwriteConfig.databaseId;

class AppwriteReportRepository implements ReportRepository {
  AppwriteReportRepository(this._tables, this._realtime, this._queue);

  final TablesDB _tables;
  final Realtime _realtime;
  final SyncQueue _queue;

  static const _table = AppwriteConfig.reportsCollection;

  @override
  Future<List<WasteReport>> listMine(String userId) async {
    try {
      final res = await _tables.listRows(
        databaseId: _db,
        tableId: _table,
        queries: [Query.equal('authorId', userId), Query.orderDesc('\$createdAt')],
      );
      return res.rows.map(_mapReport).toList();
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
      final res = await _tables.listRows(
        databaseId: _db,
        tableId: _table,
        queries: queries,
      );
      return res.rows.map(_mapReport).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<WasteReport> getById(String id) async {
    final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: id);
    return _mapReport(row);
  }

  @override
  Future<WasteReport> create(WasteReport report) async {
    try {
      final row = await _tables.createRow(
        databaseId: _db,
        tableId: _table,
        rowId: ID.unique(),
        data: report.toMap(),
        permissions: [
          Permission.read(Role.user(report.authorId)),
          Permission.update(Role.user(report.authorId)),
          Permission.read(Role.users()),
          Permission.update(Role.users()),
        ],
      );
      return _mapReport(row);
    } catch (e) {
      await _queue.enqueue(type: 'waste_report', payload: report.toMap());
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<WasteReport> updateStatus(String id, String status, {String? operatorId}) async {
    final data = <String, dynamic>{'status': status};
    if (operatorId != null) data['assignedOperatorId'] = operatorId;
    final row = await _tables.updateRow(
      databaseId: _db,
      tableId: _table,
      rowId: id,
      data: data,
    );
    return _mapReport(row);
  }

  @override
  Stream<List<WasteReport>> watchAll() {
    final controller = StreamController<List<WasteReport>>();
    listAll().then(controller.add).catchError((_) {});
    final sub = _realtime.subscribe([AppwriteConfig.rowsChannel(_table)]);
    sub.stream.listen((_) async {
      try {
        controller.add(await listAll());
      } catch (_) {}
    });
    controller.onCancel = sub.close;
    return controller.stream;
  }

  WasteReport _mapReport(models.Row row) => WasteReport.fromMap(row.data, id: row.$id);
}

class AppwriteCollectionRequestRepository implements CollectionRequestRepository {
  AppwriteCollectionRequestRepository(this._tables, this._functions);

  final TablesDB _tables;
  final Functions _functions;

  static const _table = AppwriteConfig.requestsCollection;

  CollectionRequest _map(models.Row r) => CollectionRequest.fromMap(r.data, id: r.$id);

  @override
  Future<List<CollectionRequest>> listMine(String userId) async {
    final res = await _tables.listRows(
      databaseId: _db,
      tableId: _table,
      queries: [Query.equal('authorId', userId), Query.orderDesc('\$createdAt')],
    );
    return res.rows.map(_map).toList();
  }

  @override
  Future<List<CollectionRequest>> listForCollector(String collectorId) async {
    final res = await _tables.listRows(
      databaseId: _db,
      tableId: _table,
      queries: [
        Query.equal('assignedCollectorId', collectorId),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return res.rows.map(_map).toList();
  }

  @override
  Future<CollectionRequest> create(CollectionRequest request) async {
    final row = await _tables.createRow(
      databaseId: _db,
      tableId: _table,
      rowId: ID.unique(),
      data: request.toMap(),
      permissions: [
        Permission.read(Role.user(request.authorId)),
        Permission.update(Role.user(request.authorId)),
        Permission.read(Role.users()),
        Permission.update(Role.users()),
      ],
    );
    // Valkey : agrégé côté Appwrite Function, consommé ici via HTTP.
    try {
      await _functions.createExecution(
        functionId: AppwriteConfig.matchCollectorFn,
        body: '{"requestId":"${row.$id}"}',
      );
    } catch (_) {}
    return _map(row);
  }

  @override
  Future<CollectionRequest> update(CollectionRequest request) async {
    final row = await _tables.updateRow(
      databaseId: _db,
      tableId: _table,
      rowId: request.id,
      data: request.toMap(),
    );
    return _map(row);
  }
}

class AppwriteCollectorRepository implements CollectorRepository {
  AppwriteCollectorRepository(this._tables);
  final TablesDB _tables;

  static const _table = AppwriteConfig.collectorsCollection;

  @override
  Future<List<Collector>> list() async {
    final res = await _tables.listRows(databaseId: _db, tableId: _table);
    return res.rows.map((r) => Collector.fromMap(r.data, id: r.$id)).toList();
  }

  @override
  Future<Collector?> byUserId(String userId) async {
    final res = await _tables.listRows(
      databaseId: _db,
      tableId: _table,
      queries: [Query.equal('userId', userId), Query.limit(1)],
    );
    if (res.rows.isEmpty) return null;
    return Collector.fromMap(res.rows.first.data, id: res.rows.first.$id);
  }

  @override
  Future<void> setAvailability(String id, bool available) async {
    await _tables.updateRow(
      databaseId: _db,
      tableId: _table,
      rowId: id,
      data: {'isAvailable': available},
    );
  }
}

class AppwriteRewardRepository implements RewardRepository {
  AppwriteRewardRepository(this._tables, this._functions);
  final TablesDB _tables;
  final Functions _functions;

  @override
  Future<List<RewardItem>> catalog() async {
    final res = await _tables.listRows(
      databaseId: _db,
      tableId: AppwriteConfig.rewardsCollection,
      queries: [Query.equal('enabled', true), Query.orderAsc('pointsCost')],
    );
    return res.rows.map((r) => RewardItem.fromMap(r.data, id: r.$id)).toList();
  }

  @override
  Future<int> redeem({required String userId, required String itemId}) async {
    // Valkey : agrégé côté Appwrite Function, consommé ici via HTTP.
    try {
      final ex = await _functions.createExecution(
        functionId: AppwriteConfig.computeRewardPointsFn,
        body: '{"userId":"$userId","itemId":"$itemId","action":"redeem"}',
      );
      final points = int.tryParse(ex.responseBody);
      if (points == null) {
        throw const NetworkFailure('Réponse invalide du service de récompenses.');
      }
      return points;
    } catch (e) {
      if (e is NetworkFailure) rethrow;
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> leaderboard() async {
    // Valkey : agrégé côté Appwrite Function ; repli sur la table users.
    try {
      final ex = await _functions.createExecution(
        functionId: AppwriteConfig.computeRewardPointsFn,
        body: '{"action":"leaderboard"}',
      );
      return [
        {'name': 'Classement', 'points': ex.responseBody},
      ];
    } catch (_) {
      final users = await _tables.listRows(
        databaseId: _db,
        tableId: AppwriteConfig.usersCollection,
        queries: [Query.orderDesc('points'), Query.limit(10)],
      );
      return users.rows
          .map((r) => {'name': r.data['name'], 'points': r.data['points']})
          .toList();
    }
  }
}

class AppwriteZoneRepository implements ZoneRepository {
  AppwriteZoneRepository(this._tables);
  final TablesDB _tables;

  static const _table = AppwriteConfig.zonesCollection;

  @override
  Future<List<Zone>> list() async {
    final res = await _tables.listRows(databaseId: _db, tableId: _table);
    return res.rows.map((r) => Zone.fromMap(r.data, id: r.$id)).toList();
  }

  @override
  Future<void> assignOperator(String zoneId, String operatorId) async {
    final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: zoneId);
    final ops = [...(row.data['assignedOperators'] as List? ?? []), operatorId];
    await _tables.updateRow(
      databaseId: _db,
      tableId: _table,
      rowId: zoneId,
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
    ref.watch(tablesProvider),
    ref.watch(realtimeProvider),
    SyncQueue(),
  );
});

final requestRepositoryProvider = Provider<CollectionRequestRepository>((ref) {
  return AppwriteCollectionRequestRepository(
    ref.watch(tablesProvider),
    ref.watch(functionsProvider),
  );
});

final collectorRepositoryProvider = Provider<CollectorRepository>((ref) {
  return AppwriteCollectorRepository(ref.watch(tablesProvider));
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return AppwriteRewardRepository(
    ref.watch(tablesProvider),
    ref.watch(functionsProvider),
  );
});

final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  return AppwriteZoneRepository(ref.watch(tablesProvider));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return AppwritePaymentService(ref.watch(functionsProvider));
});

final storageUploaderProvider = Provider<StorageUploader>((ref) {
  return StorageUploader(ref.watch(storageProvider));
});
