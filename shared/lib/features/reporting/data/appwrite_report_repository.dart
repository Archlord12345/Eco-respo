import 'dart:async';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eco_core/core/appwrite/appwrite_client.dart';
import 'package:eco_core/core/appwrite/appwrite_config.dart';
import 'package:eco_core/core/error/app_exceptions.dart';
import 'package:eco_core/core/offline/sync_queue.dart';
import 'package:eco_core/shared/models/collection_request.dart';
import 'package:eco_core/shared/models/collector.dart';
import 'package:eco_core/shared/models/enums.dart';
import 'package:eco_core/shared/models/reward_item.dart';
import 'package:eco_core/shared/models/waste_report.dart';
import 'package:eco_core/features/reporting/domain/repositories/report_repository.dart';

String _aw(Object e) => e is AppwriteException ? (e.message ?? 'Erreur Appwrite') : e.toString();

const _db = AppwriteConfig.databaseId;

/// Permissions par défaut d'une ligne créée par un utilisateur : lui-même en
/// lecture/écriture, plus tous les utilisateurs connectés (collecteurs,
/// back-office) en lecture/mise à jour — modèle MVP, à durcir avec des Teams.
List<String> _rowPermissions(String ownerId) => [
      Permission.read(Role.user(ownerId)),
      Permission.update(Role.user(ownerId)),
      Permission.read(Role.users()),
      Permission.update(Role.users()),
    ];

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
      final queries = <String>[Query.orderDesc('\$createdAt'), Query.limit(200)];
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
    try {
      final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: id);
      return _mapReport(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<WasteReport> create(WasteReport report) async {
    try {
      final row = await _tables.createRow(
        databaseId: _db,
        tableId: _table,
        rowId: ID.unique(),
        data: report.toMap(),
        permissions: _rowPermissions(report.authorId),
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
    if (status == ReportStatus.resolved.wire) {
      data['resolvedAt'] = DateTime.now().toIso8601String();
    }
    try {
      final row = await _tables.updateRow(
        databaseId: _db,
        tableId: _table,
        rowId: id,
        data: data,
      );
      return _mapReport(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
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
  AppwriteCollectionRequestRepository(this._tables, this._functions, this._realtime);

  final TablesDB _tables;
  final Functions _functions;
  final Realtime _realtime;

  static const _table = AppwriteConfig.requestsCollection;

  CollectionRequest _map(models.Row r) => CollectionRequest.fromMap(r.data, id: r.$id);

  Future<List<CollectionRequest>> _list(List<String> queries) async {
    try {
      final res = await _tables.listRows(databaseId: _db, tableId: _table, queries: queries);
      return res.rows.map(_map).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<List<CollectionRequest>> listMine(String userId) =>
      _list([Query.equal('authorId', userId), Query.orderDesc('\$createdAt'), Query.limit(100)]);

  @override
  Future<List<CollectionRequest>> listForCollector(String collectorId) => _list([
        Query.equal('assignedCollectorId', collectorId),
        Query.orderDesc('\$createdAt'),
        Query.limit(200),
      ]);

  @override
  Future<List<CollectionRequest>> listPending({String? city}) => _list([
        Query.equal('status', RequestStatus.pending.wire),
        if (city != null && city.isNotEmpty) Query.equal('city', city),
        Query.orderAsc('scheduledAt'),
        Query.limit(50),
      ]);

  @override
  Future<List<CollectionRequest>> listAll({String? status, int limit = 200}) => _list([
        if (status != null && status.isNotEmpty) Query.equal('status', status),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ]);

  @override
  Future<CollectionRequest> getById(String id) async {
    try {
      final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: id);
      return _map(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<CollectionRequest> create(CollectionRequest request) async {
    final models.Row row;
    try {
      row = await _tables.createRow(
        databaseId: _db,
        tableId: _table,
        rowId: ID.unique(),
        data: request.toMap(),
        permissions: _rowPermissions(request.authorId),
      );
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
    // Le matching automatique est délégué à la Function `matchCollector` ;
    // en son absence, la demande reste `pending` et est dispatchée par
    // l'entreprise de collecte (desktop) ou acceptée par un collecteur (mobile).
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
    try {
      final row = await _tables.updateRow(
        databaseId: _db,
        tableId: _table,
        rowId: request.id,
        data: request.toMap(),
      );
      return _map(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<CollectionRequest> assign(String requestId, String collectorId) async {
    try {
      final row = await _tables.updateRow(
        databaseId: _db,
        tableId: _table,
        rowId: requestId,
        data: {
          'assignedCollectorId': collectorId,
          'status': RequestStatus.matched.wire,
        },
      );
      return _map(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<CollectionRequest> updateStatus(
    String requestId,
    String status, {
    double? weightKg,
    String? proofFileId,
    DateTime? collectedAt,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (weightKg != null) data['weightKg'] = weightKg;
    if (proofFileId != null) data['proofFileId'] = proofFileId;
    if (collectedAt != null) data['collectedAt'] = collectedAt.toIso8601String();
    try {
      final row = await _tables.updateRow(
        databaseId: _db,
        tableId: _table,
        rowId: requestId,
        data: data,
      );
      return _map(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Stream<CollectionRequest> watchOne(String requestId) {
    final controller = StreamController<CollectionRequest>();
    getById(requestId).then(controller.add).catchError(controller.addError);
    final sub = _realtime.subscribe([AppwriteConfig.rowChannel(_table, requestId)]);
    sub.stream.listen((event) {
      try {
        controller.add(CollectionRequest.fromMap(
          event.payload,
          id: event.payload['\$id'] as String? ?? requestId,
        ));
      } catch (_) {}
    });
    controller.onCancel = sub.close;
    return controller.stream;
  }
}

class AppwriteCollectorRepository implements CollectorRepository {
  AppwriteCollectorRepository(this._tables);
  final TablesDB _tables;

  static const _table = AppwriteConfig.collectorsCollection;

  Collector _map(models.Row r) => Collector.fromMap(r.data, id: r.$id);

  @override
  Future<List<Collector>> list({String? company}) async {
    try {
      final res = await _tables.listRows(
        databaseId: _db,
        tableId: _table,
        queries: [
          if (company != null && company.isNotEmpty) Query.equal('company', company),
          Query.limit(200),
        ],
      );
      return res.rows.map(_map).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<Collector?> byUserId(String userId) async {
    try {
      final res = await _tables.listRows(
        databaseId: _db,
        tableId: _table,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      if (res.rows.isEmpty) return null;
      return _map(res.rows.first);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<Collector?> byId(String id) async {
    try {
      final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: id);
      return _map(row);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<void> setAvailability(String id, bool available) async {
    try {
      await _tables.updateRow(
        databaseId: _db,
        tableId: _table,
        rowId: id,
        data: {'isAvailable': available},
      );
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<Collector> upsert(Collector collector) async {
    try {
      final row = await _tables.upsertRow(
        databaseId: _db,
        tableId: _table,
        rowId: collector.id.isEmpty ? ID.unique() : collector.id,
        data: collector.toMap(),
        permissions: collector.userId.isEmpty
            ? [Permission.read(Role.users()), Permission.update(Role.users())]
            : _rowPermissions(collector.userId),
      );
      return _map(row);
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<void> incrementInterventions(String id) async {
    try {
      await _tables.incrementRowColumn(
        databaseId: _db,
        tableId: _table,
        rowId: id,
        column: 'interventionsCount',
        value: 1,
      );
    } catch (_) {
      // Non bloquant : le compteur est indicatif.
    }
  }
}

class AppwriteRewardRepository implements RewardRepository {
  AppwriteRewardRepository(this._tables, this._functions);
  final TablesDB _tables;
  final Functions _functions;

  @override
  Future<List<RewardItem>> catalog() async {
    try {
      final res = await _tables.listRows(
        databaseId: _db,
        tableId: AppwriteConfig.rewardsCollection,
        queries: [Query.equal('enabled', true), Query.orderAsc('pointsCost')],
      );
      return res.rows.map((r) => RewardItem.fromMap(r.data, id: r.$id)).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<int> redeem({required String userId, required String itemId}) async {
    // Le calcul autoritaire des points est porté par la Function
    // `computeRewardPoints` ; repli : débit direct dans la table users.
    try {
      final ex = await _functions.createExecution(
        functionId: AppwriteConfig.computeRewardPointsFn,
        body: '{"userId":"$userId","itemId":"$itemId","action":"redeem"}',
      );
      final points = int.tryParse(ex.responseBody);
      if (points != null) return points;
    } catch (_) {}
    try {
      final item = await _tables.getRow(
        databaseId: _db,
        tableId: AppwriteConfig.rewardsCollection,
        rowId: itemId,
      );
      final user = await _tables.getRow(
        databaseId: _db,
        tableId: AppwriteConfig.usersCollection,
        rowId: userId,
      );
      final cost = (item.data['pointsCost'] as num?)?.toInt() ?? 0;
      final current = (user.data['points'] as num?)?.toInt() ?? 0;
      if (current < cost) {
        throw const NetworkFailure('Points insuffisants pour cette récompense.');
      }
      final updated = await _tables.updateRow(
        databaseId: _db,
        tableId: AppwriteConfig.usersCollection,
        rowId: userId,
        data: {'points': current - cost},
      );
      return (updated.data['points'] as num?)?.toInt() ?? (current - cost);
    } catch (e) {
      if (e is NetworkFailure) rethrow;
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> leaderboard() async {
    try {
      final users = await _tables.listRows(
        databaseId: _db,
        tableId: AppwriteConfig.usersCollection,
        queries: [Query.orderDesc('points'), Query.limit(10)],
      );
      return users.rows
          .map((r) => {'name': r.data['name'], 'points': r.data['points']})
          .toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }
}

class AppwriteZoneRepository implements ZoneRepository {
  AppwriteZoneRepository(this._tables);
  final TablesDB _tables;

  static const _table = AppwriteConfig.zonesCollection;

  @override
  Future<List<Zone>> list() async {
    try {
      final res = await _tables.listRows(databaseId: _db, tableId: _table);
      return res.rows.map((r) => Zone.fromMap(r.data, id: r.$id)).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<void> assignOperator(String zoneId, String operatorId) async {
    final row = await _tables.getRow(databaseId: _db, tableId: _table, rowId: zoneId);
    final ops = [...(row.data['assignedOperators'] as List? ?? []), operatorId];
    await setOperators(zoneId, ops.cast<String>().toSet().toList());
  }

  @override
  Future<void> setOperators(String zoneId, List<String> operatorIds) async {
    try {
      await _tables.updateRow(
        databaseId: _db,
        tableId: _table,
        rowId: zoneId,
        data: {'assignedOperators': operatorIds},
      );
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }
}

class AppwriteNotificationRepository implements NotificationRepository {
  AppwriteNotificationRepository(this._tables, this._realtime);
  final TablesDB _tables;
  final Realtime _realtime;

  static const _table = AppwriteConfig.notificationsCollection;

  AppNotification _map(models.Row r) => AppNotification.fromMap(r.data, id: r.$id);

  @override
  Future<List<AppNotification>> listMine(String userId, {int limit = 50}) async {
    try {
      final res = await _tables.listRows(
        databaseId: _db,
        tableId: _table,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
        ],
      );
      return res.rows.map(_map).toList();
    } catch (e) {
      throw NetworkFailure(_aw(e));
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _tables.updateRow(databaseId: _db, tableId: _table, rowId: id, data: {'read': true});
    } catch (_) {}
  }

  @override
  Future<void> markAllRead(String userId) async {
    final items = await listMine(userId);
    for (final n in items.where((n) => !n.read)) {
      await markRead(n.id);
    }
  }

  @override
  Future<void> create(AppNotification notification) async {
    try {
      await _tables.createRow(
        databaseId: _db,
        tableId: _table,
        rowId: ID.unique(),
        data: notification.toMap(),
        permissions: _rowPermissions(notification.userId),
      );
    } catch (_) {
      // Une notification manquée ne doit jamais bloquer l'action métier.
    }
  }

  @override
  Stream<List<AppNotification>> watchMine(String userId) {
    final controller = StreamController<List<AppNotification>>();
    listMine(userId).then(controller.add).catchError(controller.addError);
    final sub = _realtime.subscribe([AppwriteConfig.rowsChannel(_table)]);
    sub.stream.listen((_) async {
      try {
        controller.add(await listMine(userId));
      } catch (_) {}
    });
    controller.onCancel = sub.close;
    return controller.stream;
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
    ref.watch(realtimeProvider),
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

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return AppwriteNotificationRepository(
    ref.watch(tablesProvider),
    ref.watch(realtimeProvider),
  );
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return AppwritePaymentService(ref.watch(functionsProvider));
});

final storageUploaderProvider = Provider<StorageUploader>((ref) {
  return StorageUploader(ref.watch(storageProvider));
});
