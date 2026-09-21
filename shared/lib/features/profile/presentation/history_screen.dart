import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/waste_report.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../company/presentation/company_screens.dart' show RequestStatusChip;
import '../../reporting/data/appwrite_report_repository.dart';

final myReportsProvider = FutureProvider.family<List<WasteReport>, String?>((ref, uid) {
  if (uid == null) return Future.value(const []);
  return ref.watch(reportRepositoryProvider).listMine(uid);
});

final myRequestsProvider = FutureProvider.family<List<CollectionRequest>, String?>((ref, uid) {
  if (uid == null) return Future.value(const []);
  return ref.watch(requestRepositoryProvider).listMine(uid);
});

/// Impact cumulé calculé à partir des collectes validées de l'utilisateur.
class CitizenImpact {
  const CitizenImpact({required this.kg, required this.reports, required this.collections, required this.resolved});
  final double kg;
  final int reports;
  final int collections;
  final int resolved;

  double get co2Kg => kg * AppConstants.co2PerKg;
  double get trees => co2Kg / 22; // ≈ 22 kg CO₂ absorbés par arbre et par an
}

final myImpactProvider = FutureProvider.family<CitizenImpact, String?>((ref, uid) async {
  final reports = await ref.watch(myReportsProvider(uid).future);
  final requests = await ref.watch(myRequestsProvider(uid).future);
  final done = requests.where((r) => r.status == RequestStatus.collected);
  return CitizenImpact(
    kg: done.fold(0.0, (s, r) => s + (r.weightKg ?? 0)),
    reports: reports.length,
    collections: done.length,
    resolved: reports.where((r) => r.status == ReportStatus.resolved).length,
  );
});

String wasteAssetFor(WasteCategory c) => switch (c) {
      WasteCategory.menager => AppAssets.reportHousehold,
      WasteCategory.plastique => AppAssets.reportBin,
      WasteCategory.electronique => AppAssets.iconRecycle,
      WasteCategory.encombrant => AppAssets.reportDump,
    };

/// Historique citoyen (planche 3) : signalements, collectes et impact.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.id;
    final reports = ref.watch(myReportsProvider(uid));
    final reqs = ref.watch(myRequestsProvider(uid));
    final impact = ref.watch(myImpactProvider(uid));
    final fmt = DateFormat('dd MMM y • HH:mm', 'fr');
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          bottom: const TabBar(tabs: [Tab(text: 'Signalements & Collectes'), Tab(text: 'Impact')]),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myReportsProvider(uid));
                ref.invalidate(myRequestsProvider(uid));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Mes signalements', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      reports.maybeWhen(data: (l) => Text('${l.length}'), orElse: () => const SizedBox.shrink()),
                    ],
                  ),
                  reports.when(
                    data: (list) => list.isEmpty
                        ? _empty('Aucun signalement pour l’instant.', 'Signaler un dépôt', () => context.go('/report'))
                        : Column(
                            children: [
                              for (final r in list)
                                Card(
                                  margin: const EdgeInsets.only(top: 8),
                                  child: ListTile(
                                    onTap: () => context.push('/report/${r.id}'),
                                    leading: AssetImageBox(asset: wasteAssetFor(r.category), height: 48, width: 48, radius: 10),
                                    title: Text(r.category.labelFr, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('${r.address.isEmpty ? r.city : r.address}\n${fmt.format(r.createdAt)}'),
                                    trailing: StatusBadge(status: r.status),
                                    isThreeLine: true,
                                  ),
                                ),
                            ],
                          ),
                    loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                    error: (e, _) => _error('Signalements indisponibles : $e'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Text('Mes collectes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      reqs.maybeWhen(data: (l) => Text('${l.length}'), orElse: () => const SizedBox.shrink()),
                    ],
                  ),
                  reqs.when(
                    data: (list) => list.isEmpty
                        ? _empty('Aucune collecte demandée.', 'Demander une collecte', () => context.go('/collect'))
                        : Column(
                            children: [
                              for (final r in list)
                                Card(
                                  margin: const EdgeInsets.only(top: 8),
                                  child: ListTile(
                                    onTap: () => context.push('/collect/${r.id}'),
                                    leading: const CircleAvatar(
                                      backgroundColor: AppColors.paleGreen,
                                      child: Icon(Icons.local_shipping, color: AppColors.primaryGreen),
                                    ),
                                    title: Text('Collecte de ${r.wasteType.labelFr.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${r.address.isEmpty ? r.city : r.address}\n'
                                      '${r.scheduledAt != null ? fmt.format(r.scheduledAt!) : r.timeSlot}'
                                      '${r.weightKg != null ? ' • ${r.weightKg} kg' : ''}',
                                    ),
                                    trailing: RequestStatusChip(r.status),
                                    isThreeLine: true,
                                  ),
                                ),
                            ],
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => _error('Collectes indisponibles : $e'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            impact.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: _error('Impact indisponible : $e')),
              data: (i) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Impact cumulé de vos actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text(
                    'Estimations basées sur vos collectes validées et vos signalements résolus.',
                    style: TextStyle(fontSize: 12, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      _ImpactTile(value: '${i.kg.toStringAsFixed(i.kg >= 10 ? 0 : 1)} kg', label: 'de déchets collectés'),
                      _ImpactTile(value: '${i.co2Kg.toStringAsFixed(0)} kg', label: 'de CO₂ évités'),
                      _ImpactTile(value: i.trees.toStringAsFixed(1), label: 'arbre(s) équivalents préservés'),
                      _ImpactTile(value: '${i.resolved}/${i.reports}', label: 'signalements résolus'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AssetImageBox(asset: AppAssets.iconCitizens, height: 140, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String text, String action, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(color: AppColors.textDark))),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
      );
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
      decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen, fontSize: 20)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
