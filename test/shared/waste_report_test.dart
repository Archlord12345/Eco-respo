import 'package:eco_responsable/shared/models/enums.dart';
import 'package:eco_responsable/shared/models/waste_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WasteReport.fromMap mappe un document Appwrite', () {
    final report = WasteReport.fromMap({
      'authorId': 'u1',
      'photoFileId': 'f1',
      'lat': 3.84,
      'lng': 11.5,
      'category': 'plastique',
      'urgency': 'critique',
      'status': 'inProgress',
      'address': 'Bastos',
      'reportedAt': '2026-04-12T08:24:00.000Z',
    }, id: 'rep-1');

    expect(report.id, 'rep-1');
    expect(report.category, WasteCategory.plastique);
    expect(report.urgency, Urgency.critique);
    expect(report.status, ReportStatus.inProgress);
    expect(report.toMap()['authorId'], 'u1');
  });
}
