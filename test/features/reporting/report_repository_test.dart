import 'package:eco_responsable/features/reporting/domain/repositories/report_repository.dart';
import 'package:eco_responsable/shared/models/enums.dart';
import 'package:eco_responsable/shared/models/waste_report.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReportRepository implements ReportRepository {
  final items = <WasteReport>[];

  @override
  Future<WasteReport> create(WasteReport report) async {
    final saved = WasteReport.fromMap(report.toMap(), id: 'new-id');
    items.add(saved);
    return saved;
  }

  @override
  Future<WasteReport> getById(String id) async =>
      items.firstWhere((e) => e.id == id);

  @override
  Future<List<WasteReport>> listAll({String? status, String? search}) async =>
      items;

  @override
  Future<List<WasteReport>> listMine(String userId) async =>
      items.where((e) => e.authorId == userId).toList();

  @override
  Future<WasteReport> updateStatus(
    String id,
    String status, {
    String? operatorId,
  }) async {
    final i = items.indexWhere((e) => e.id == id);
    final current = items[i];
    final updated = WasteReport.fromMap({
      ...current.toMap(),
      'status': status,
      'assignedOperatorId': operatorId,
    }, id: id);
    items[i] = updated;
    return updated;
  }

  @override
  Stream<List<WasteReport>> watchAll() => Stream.value(items);
}

void main() {
  test('ReportRepository factice : création et filtre auteur', () async {
    final repo = _FakeReportRepository();
    await repo.create(
      WasteReport(
        id: '',
        authorId: 'u1',
        lat: 3.8,
        lng: 11.5,
        category: WasteCategory.menager,
        urgency: Urgency.moyen,
        status: ReportStatus.reported,
        createdAt: DateTime.now(),
      ),
    );
    expect(await repo.listMine('u1'), hasLength(1));
    expect(await repo.listMine('other'), isEmpty);
  });
}
