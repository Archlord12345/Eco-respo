import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/waste_report.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.id;
    final reports = ref.watch(myReportsProvider(uid));
    final reqs = ref.watch(myRequestsProvider(uid));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Signalements & Collectes'),
              Tab(text: 'Impact'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Mes signalements', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                    reports.maybeWhen(data: (l) => Text('${l.length}'), orElse: () => const Text('12')),
                  ],
                ),
                reports.when(
                  data: (list) => Column(
                    children: list
                        .map(
                          (r) => ListTile(
                            leading: AssetImageBox(
                              asset: r.category == WasteCategory.menager
                                  ? AppAssets.reportHousehold
                                  : r.category == WasteCategory.plastique
                                      ? AppAssets.reportBin
                                      : AppAssets.reportDump,
                              height: 48,
                              width: 48,
                              radius: 10,
                            ),
                            title: Text(r.category.labelFr),
                            subtitle: Text('${r.address}\n${DateFormat('dd MMM y • HH:mm', 'fr').format(r.createdAt)}'),
                            trailing: StatusBadge(status: r.status),
                            isThreeLine: true,
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Column(
                    children: [
                      _fake('Dépôt sauvage', 'Bastos, Yaoundé', AppAssets.reportDump, ReportStatus.reported),
                      _fake('Bac plein', 'Nlongkak, Yaoundé', AppAssets.reportBin, ReportStatus.inProgress),
                      _fake('Déchets ménagers', 'Mfoundi, Yaoundé', AppAssets.reportHousehold, ReportStatus.resolved),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Mes collectes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                reqs.when(
                  data: (list) => Column(
                    children: list
                        .map(
                          (r) => ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8F5E9),
                              child: Icon(Icons.local_shipping, color: AppColors.primaryGreen),
                            ),
                            title: Text('Collecte de ${r.wasteType.labelFr}'),
                            subtitle: Text(r.address),
                            trailing: const StatusBadge(status: ReportStatus.resolved),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => Column(
                    children: [
                      _fake('Collecte de plastiques', 'Mfoundi, Yaoundé', AppAssets.collectorTruck, ReportStatus.resolved),
                      _fake('Collecte de verre', 'Nlongkak, Yaoundé', AppAssets.collectorTruck, ReportStatus.resolved),
                      _fake('Collecte de papiers/cartons', 'Bastos, Yaoundé', AppAssets.collectorTruck, ReportStatus.resolved),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Impact cumulé de vos actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: _ImpactTile(value: '72 kg', label: 'de déchets collectés')),
                      Expanded(child: _ImpactTile(value: '36', label: 'arbres préservés')),
                      Expanded(child: _ImpactTile(value: '182 kg', label: 'de CO₂ évités')),
                      Expanded(child: _ImpactTile(value: '12', label: 'communautés aidées')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fake(String t, String s, String a, ReportStatus st) {
    return ListTile(
      leading: AssetImageBox(asset: a, height: 48, width: 48, radius: 10),
      title: Text(t),
      subtitle: Text(s),
      trailing: StatusBadge(status: st),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen, fontSize: 18)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

final myReportsProvider =
    FutureProvider.family<List<WasteReport>, String?>((ref, uid) {
  if (uid == null) return Future.value(const []);
  return ref.watch(reportRepositoryProvider).listMine(uid);
});

final myRequestsProvider =
    FutureProvider.family<List<CollectionRequest>, String?>((ref, uid) {
  if (uid == null) return Future.value(const []);
  return ref.watch(requestRepositoryProvider).listMine(uid);
});
