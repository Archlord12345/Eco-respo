import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/appwrite/appwrite_client.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/waste_report.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(allReportsProvider);
    return _AdminFrame(
      title: 'Tableau de bord',
      subtitle: 'Suivi des signalements et des opérations citoyennes',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _Kpi(title: 'Taux de résolution', value: '78%', hint: 'sur 365 signalements', color: Color(0xFFE8F5E9)),
              _Kpi(title: 'Délai moyen d’intervention', value: '4h 32', hint: 'les 30 derniers jours', color: Color(0xFFE3F2FD)),
              _Kpi(title: 'Volume collecté', value: '1 248 tonnes', hint: 'déchets ménagers et assimilés', color: Color(0xFFFFF8E1)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _card(
                  'Carte de chaleur des signalements',
                  AssetImageBox(asset: AppAssets.heatmap, height: 280, width: double.infinity),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _card(
                  'Évolution des signalements',
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: AppColors.primaryGreen,
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 4),
                              FlSpot(2, 2.5),
                              FlSpot(3, 5),
                              FlSpot(4, 4.2),
                              FlSpot(5, 6),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            'Types de déchets collectés',
            SizedBox(
              height: 180,
              child: reports.maybeWhen(
                data: (list) => PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: 48, color: AppColors.primaryGreen, title: 'Ménagers'),
                      PieChartSectionData(value: 22, color: AppColors.lightGreen, title: 'Plastique'),
                      PieChartSectionData(value: 18, color: AppColors.earthOchre, title: 'Organiques'),
                      PieChartSectionData(value: 12, color: AppColors.institutionalBlue, title: 'Autres'),
                    ],
                  ),
                ),
                orElse: () => PieChart(
                  PieChartData(sections: [
                    PieChartSectionData(value: 48, color: AppColors.primaryGreen, title: '48%'),
                    PieChartSectionData(value: 22, color: AppColors.lightGreen, title: '22%'),
                    PieChartSectionData(value: 18, color: AppColors.earthOchre, title: '18%'),
                    PieChartSectionData(value: 12, color: AppColors.institutionalBlue, title: '12%'),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String t, Widget c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        c,
      ]),
    );
  }
}

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  WasteReport? _selected;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(allReportsProvider);
    return _AdminFrame(
      title: 'Gestion des signalements',
      subtitle: 'Identifiez, suivez et traitez les signalements citoyens',
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher ID, lieu, citoyen…'),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: reports.when(
                      data: (list) {
                        final filtered = list.where((r) => r.address.toLowerCase().contains(_search.toLowerCase())).toList();
                        return SingleChildScrollView(
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Lieu')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Statut')),
                              DataColumn(label: Text('Urgence')),
                            ],
                            rows: filtered
                                .map(
                                  (r) => DataRow(
                                    onSelectChanged: (_) => setState(() => _selected = r),
                                    cells: [
                                      DataCell(Text(r.id.substring(0, r.id.length.clamp(0, 8)))),
                                      DataCell(Text(r.address)),
                                      DataCell(Text(r.category.labelFr)),
                                      DataCell(StatusBadge(status: r.status)),
                                      DataCell(Text(r.urgency.labelFr)),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('$e'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 340,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: _selected == null
                ? const Center(child: Text('Sélectionnez un signalement'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Détail ${_selected!.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      AssetImageBox(asset: AppAssets.reportDetailPhoto, height: 140, width: double.infinity),
                      const SizedBox(height: 8),
                      Text(_selected!.address),
                      Text(_selected!.description),
                      StatusBadge(status: _selected!.status),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          await ref.read(reportRepositoryProvider).updateStatus(
                                _selected!.id,
                                ReportStatus.inProgress.wire,
                                operatorId: 'op-hygiene-plus',
                              );
                        },
                        child: const Text('Affecter'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class AdminZonesScreen extends ConsumerWidget {
  const AdminZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(adminZonesProvider);
    final collectors = ref.watch(adminCollectorsProvider);
    return _AdminFrame(
      title: 'Zones et opérateurs',
      subtitle: 'Gérez les zones de collecte et les opérateurs partenaires',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: AssetImageBox(asset: AppAssets.zonesMap, height: 480, width: double.infinity)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Opérateurs partenaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Expanded(
                    child: collectors.when(
                      data: (list) => ListView(
                        children: list
                            .map((c) => ListTile(
                                  title: Text(c.company.isEmpty ? c.displayName : c.company),
                                  subtitle: Text(c.phone),
                                  trailing: Chip(label: Text(c.isAvailable ? 'Actif' : 'Inactif')),
                                ))
                            .toList(),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => const ListTile(title: Text('Hygiène Plus'), subtitle: Text('+237 6 77 45 67 89')),
                    ),
                  ),
                  const Text('Zones', style: TextStyle(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: zones.when(
                      data: (list) => ListView(
                        children: list
                            .map((z) => ListTile(
                                  title: Text('${z.district} — ${z.city}'),
                                  subtitle: Text(z.collectionFrequency),
                                ))
                            .toList(),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const ListTile(title: Text('Zone 1 – Centre')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminReportsCommScreen extends ConsumerWidget {
  const AdminReportsCommScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = TextEditingController();
    return _AdminFrame(
      title: 'Rapports et communication',
      subtitle: 'Générez des rapports et communiquez avec les citoyens',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(onPressed: () {}, child: const Text('Exporter PDF')),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: () {}, child: const Text('Exporter CSV')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _reportTile('Rapport général', 'Signalements globaux, collectes, opérateurs'),
                  _reportTile('Rapport par zone', 'Performance par arrondissement et collecteur'),
                  _reportTile('Rapport par opérateur', 'Volume et ponctualité de collecte'),
                  _reportTile('Rapport des signalements', 'État de traitement et urgences'),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Envoyer une campagne / alerte citoyenne', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                      initialValue: 'sms',
                      items: const [
                        DropdownMenuItem(value: 'sms', child: Text('SMS')),
                        DropdownMenuItem(value: 'push', child: Text('Push')),
                      ],
                      onChanged: (_) {},
                      decoration: const InputDecoration(labelText: 'Type de message'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: msg, maxLines: 5, decoration: const InputDecoration(labelText: 'Message')),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        try {
                          await ref.read(functionsProviderSafe).createExecution(
                                functionId: 'generateAdminReport',
                                body: '{"kind":"campaign"}',
                              );
                        } catch (_) {}
                      },
                      child: const Text('Envoyer la campagne'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(String t, String s) {
    return Card(
      child: ListTile(
        title: Text(t),
        subtitle: Text(s),
        trailing: TextButton(onPressed: () {}, child: const Text('Générer')),
      ),
    );
  }
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminFrame(
      title: 'Paramètres',
      subtitle: 'Municipalité',
      child: Center(child: Text('Mairie de Yaoundé — Admin Municipal')),
    );
  }
}

class _AdminFrame extends StatelessWidget {
  const _AdminFrame({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textDark, fontSize: 12)),
                  ],
                ),
              ),
              AssetImageBox(asset: AppAssets.cameroonFlag, height: 20, width: 28, radius: 3),
              const SizedBox(width: 8),
              const Text('Mairie de Yaoundé'),
              const SizedBox(width: 16),
              const CircleAvatar(backgroundImage: AssetImage(AppAssets.avatarPlaceholder)),
              const SizedBox(width: 8),
              const Text('Admin Municipal'),
            ],
          ),
        ),
        Expanded(child: ColoredBox(color: const Color(0xFFF4F6F5), child: child)),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.title, required this.value, required this.hint, required this.color});
  final String title;
  final String value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          Text(hint, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

final allReportsProvider = FutureProvider<List<WasteReport>>((ref) {
  return ref.watch(reportRepositoryProvider).listAll();
});

final adminZonesProvider = FutureProvider((ref) => ref.watch(zoneRepositoryProvider).list());
final adminCollectorsProvider = FutureProvider((ref) => ref.watch(collectorRepositoryProvider).list());

final functionsProviderSafe = Provider((ref) {
  return ref.watch(functionsProvider);
});
