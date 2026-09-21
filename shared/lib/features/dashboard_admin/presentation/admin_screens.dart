import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/appwrite/appwrite_client.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/mini_map.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/models/collector.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/reward_item.dart';
import '../../../shared/models/waste_report.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../company/presentation/company_screens.dart' show Kpi, allRequestsProvider;
import '../../reporting/data/appwrite_report_repository.dart';
import '../../reporting/presentation/report_detail_screen.dart' show StoragePhoto;

// ----------------------------------------------------------------- providers

final allReportsProvider = FutureProvider<List<WasteReport>>((ref) {
  return ref.watch(reportRepositoryProvider).listAll();
});

final adminZonesProvider = FutureProvider<List<Zone>>((ref) => ref.watch(zoneRepositoryProvider).list());
final adminCollectorsProvider = FutureProvider<List<Collector>>((ref) => ref.watch(collectorRepositoryProvider).list());

void _refreshAdmin(WidgetRef ref) {
  ref.invalidate(allReportsProvider);
  ref.invalidate(adminZonesProvider);
  ref.invalidate(adminCollectorsProvider);
  ref.invalidate(allRequestsProvider);
}

String _operatorLabel(List<Collector>? ops, String? id) {
  if (id == null) return 'Non affecté';
  final c = ops?.where((c) => c.id == id).firstOrNull;
  if (c == null) return id;
  return c.company.isNotEmpty ? c.company : c.displayName;
}

Color _urgencyColor(Urgency u) => switch (u) {
      Urgency.faible => AppColors.primaryGreen,
      Urgency.moyen => AppColors.earthOchre,
      Urgency.eleve => AppColors.warning,
      Urgency.critique => AppColors.danger,
    };

class _AdminFrame extends ConsumerWidget {
  const _AdminFrame({required this.title, required this.subtitle, required this.child, this.actions = const []});
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(authProvider).user?.city ?? AppConstants.defaultCity;
    return Column(
      children: [
        BackOfficeHeader(title: title, subtitle: subtitle, organisation: 'Mairie de $city', actions: actions),
        Expanded(child: ColoredBox(color: const Color(0xFFF4F6F5), child: child)),
      ],
    );
  }
}

Widget _card(String title, Widget child, {Widget? trailing}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            ?trailing,
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );

// ------------------------------------------------------------------ dashboard

/// Vue d'ensemble (planche 4, écran 1).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(allReportsProvider);
    final requests = ref.watch(allRequestsProvider).value ?? const [];
    final city = ref.watch(authProvider).user?.city ?? AppConstants.defaultCity;
    final now = DateTime.now();
    return _AdminFrame(
      title: 'Tableau de bord',
      subtitle: 'Suivi de la gestion des déchets et des signalements citoyens',
      actions: [
        Chip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 14),
          label: Text('Du ${DateFormat('dd/MM/y').format(now.subtract(const Duration(days: 30)))} au ${DateFormat('dd/MM/y').format(now)}'),
        ),
        IconButton(tooltip: 'Actualiser', onPressed: () => _refreshAdmin(ref), icon: const Icon(Icons.refresh)),
      ],
      child: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('KPIs indisponibles : $e')),
        data: (items) {
          final resolved = items.where((i) => i.status == ReportStatus.resolved).toList();
          final rate = items.isEmpty ? 0 : (resolved.length * 100 ~/ items.length);
          final delays = resolved.where((r) => r.resolvedAt != null).map((r) => r.resolvedAt!.difference(r.createdAt)).toList();
          final avgDelay = delays.isEmpty ? null : Duration(seconds: delays.fold(0, (s, d) => s + d.inSeconds) ~/ delays.length);
          final kg = requests.where((r) => r.status == RequestStatus.collected).fold(0.0, (s, r) => s + (r.weightKg ?? 0));
          final days = List.generate(30, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i)));
          int countOn(DateTime d, bool Function(WasteReport) test) => items.where((r) {
                final c = r.createdAt;
                return c.year == d.year && c.month == d.month && c.day == d.day && test(r);
              }).length;
          final created = [for (final d in days) countOn(d, (_) => true)];
          final resolvedSeries = [
            for (final d in days)
              resolved.where((r) {
                final c = r.resolvedAt ?? r.createdAt;
                return c.year == d.year && c.month == d.month && c.day == d.day;
              }).length,
          ];
          final byCat = {for (final c in WasteCategory.values) c: items.where((r) => r.category == c).length};
          final total = items.length;
          final pins = [
            for (final r in items.where((r) => r.lat != 0 && r.lng != 0))
              MapPin(LatLng(r.lat, r.lng), color: r.status == ReportStatus.resolved ? AppColors.success : _urgencyColor(r.urgency)),
          ];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Kpi(title: 'Taux de résolution', value: '$rate %', hint: 'sur $total signalement(s)', color: AppColors.paleGreen, icon: Icons.check_circle_outline),
                  Kpi(
                    title: 'Délai moyen d’intervention',
                    value: avgDelay == null ? '—' : '${avgDelay.inHours}h ${(avgDelay.inMinutes % 60).toString().padLeft(2, '0')}',
                    hint: avgDelay == null ? 'aucun signalement résolu' : 'signalement → résolution',
                    color: const Color(0xFFE3F2FD),
                    icon: Icons.timer_outlined,
                  ),
                  Kpi(
                    title: 'Volume collecté',
                    value: kg >= 1000 ? '${(kg / 1000).toStringAsFixed(2)} t' : '${kg.toStringAsFixed(0)} kg',
                    hint: 'collectes validées',
                    color: const Color(0xFFFFF8E1),
                    icon: Icons.scale_outlined,
                  ),
                  Kpi(
                    title: 'Signalements ouverts',
                    value: '${items.where((r) => r.status != ReportStatus.resolved).length}',
                    hint: '${items.where((r) => r.urgency == Urgency.critique && r.status != ReportStatus.resolved).length} critique(s)',
                    color: Colors.white,
                    icon: Icons.campaign_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 950;
                  final map = _card(
                    'Carte de chaleur des signalements',
                    MiniMap(pins: pins, center: AppConstants.centerFor(city), zoom: 12, height: 320),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        _legend(AppColors.danger, 'Critique'),
                        _legend(AppColors.warning, 'Élevé'),
                        _legend(AppColors.earthOchre, 'Moyen'),
                        _legend(AppColors.success, 'Résolu'),
                      ],
                    ),
                  );
                  final chart = _card(
                    'Évolution des signalements · 30 jours',
                    SizedBox(
                      height: 320,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                getTitlesWidget: (v, _) => Text(DateFormat('d/M').format(days[v.toInt().clamp(0, 29)]), style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: AppColors.institutionalBlue,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              spots: [for (var i = 0; i < 30; i++) FlSpot(i.toDouble(), created[i].toDouble())],
                            ),
                            LineChartBarData(
                              isCurved: true,
                              color: AppColors.primaryGreen,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              spots: [for (var i = 0; i < 30; i++) FlSpot(i.toDouble(), resolvedSeries[i].toDouble())],
                            ),
                          ],
                        ),
                      ),
                    ),
                    trailing: Wrap(spacing: 8, children: [_legend(AppColors.institutionalBlue, 'Créés'), _legend(AppColors.primaryGreen, 'Résolus')]),
                  );
                  return wide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: map), const SizedBox(width: 16), Expanded(flex: 2, child: chart)])
                      : Column(children: [map, const SizedBox(height: 16), chart]);
                },
              ),
              const SizedBox(height: 16),
              _card(
                'Types de déchets signalés',
                SizedBox(
                  height: 200,
                  child: total == 0
                      ? const Center(child: Text('Aucun signalement pour l’instant.'))
                      : Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                  sections: [
                                    for (final e in byCat.entries.where((e) => e.value > 0))
                                      PieChartSectionData(
                                        value: e.value.toDouble(),
                                        color: _catColor(e.key),
                                        title: '${e.value * 100 ~/ total}%',
                                        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final e in byCat.entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(children: [
                                        Icon(Icons.circle, size: 10, color: _catColor(e.key)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(e.key.labelFr)),
                                        Text('${total == 0 ? 0 : e.value * 100 ~/ total} %', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legend(Color c, String l) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 10, color: c),
        const SizedBox(width: 4),
        Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]);

  Color _catColor(WasteCategory c) => switch (c) {
        WasteCategory.menager => AppColors.primaryGreen,
        WasteCategory.plastique => AppColors.lightGreen,
        WasteCategory.electronique => AppColors.institutionalBlue,
        WasteCategory.encombrant => AppColors.earthOchre,
      };
}

// ------------------------------------------------------------- signalements

/// Gestion des signalements — liste et détail (planche 4, écran 2).
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _selectedId;
  String _search = '';
  ReportStatus? _status;
  Urgency? _urgency;
  String? _operatorId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(allReportsProvider);
    final ops = ref.watch(adminCollectorsProvider).value;
    return _AdminFrame(
      title: 'Gestion des signalements',
      subtitle: 'Identifiez, suivez et traitez les signalements citoyens',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _exportCsv(context, reports.value ?? const [], ops),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exporter CSV'),
        ),
        const SizedBox(width: 8),
        IconButton(tooltip: 'Actualiser', onPressed: () => _refreshAdmin(ref), icon: const Icon(Icons.refresh)),
      ],
      child: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final list = all.where((r) {
            final q = _search.toLowerCase();
            final okQ = q.isEmpty || r.address.toLowerCase().contains(q) || r.city.toLowerCase().contains(q) || r.id.toLowerCase().contains(q) || r.reference.toLowerCase().contains(q);
            return okQ && (_status == null || r.status == _status) && (_urgency == null || r.urgency == _urgency);
          }).toList();
          final selected = all.where((r) => r.id == _selectedId).firstOrNull;
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher ID, lieu, quartier…', isDense: true),
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<ReportStatus?>(
                              initialValue: _status,
                              decoration: const InputDecoration(labelText: 'Statut', isDense: true),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Tous')),
                                for (final s in ReportStatus.values) DropdownMenuItem(value: s, child: Text(s.labelFr)),
                              ],
                              onChanged: (v) => setState(() => _status = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<Urgency?>(
                              initialValue: _urgency,
                              decoration: const InputDecoration(labelText: 'Urgence', isDense: true),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Toutes')),
                                for (final u in Urgency.values) DropdownMenuItem(value: u, child: Text(u.labelFr)),
                              ],
                              onChanged: (v) => setState(() => _urgency = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${list.length} signalement(s)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.antiAlias,
                          child: list.isEmpty
                              ? const Center(child: Text('Aucun signalement pour ces filtres.'))
                              : SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      columnSpacing: 18,
                                      columns: const [
                                        DataColumn(label: Text('#')),
                                        DataColumn(label: Text('Date')),
                                        DataColumn(label: Text('Lieu')),
                                        DataColumn(label: Text('Type')),
                                        DataColumn(label: Text('Statut')),
                                        DataColumn(label: Text('Urgence')),
                                        DataColumn(label: Text('Opérateur')),
                                      ],
                                      rows: [
                                        for (final r in list)
                                          DataRow(
                                            selected: r.id == _selectedId,
                                            onSelectChanged: (_) => setState(() {
                                              _selectedId = r.id;
                                              _operatorId = r.assignedOperatorId;
                                            }),
                                            cells: [
                                              DataCell(Text(r.reference, style: const TextStyle(fontSize: 12))),
                                              DataCell(Text(DateFormat('dd/MM/y').format(r.createdAt))),
                                              DataCell(Text(r.address.isEmpty ? r.city : r.address, overflow: TextOverflow.ellipsis)),
                                              DataCell(Text(r.category.labelFr)),
                                              DataCell(StatusBadge(status: r.status)),
                                              DataCell(Row(children: [
                                                Icon(Icons.circle, size: 10, color: _urgencyColor(r.urgency)),
                                                const SizedBox(width: 6),
                                                Text(r.urgency.labelFr),
                                              ])),
                                              DataCell(Text(_operatorLabel(ops, r.assignedOperatorId), overflow: TextOverflow.ellipsis)),
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
                ),
              ),
              Container(
                width: 360,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: selected == null
                    ? const Center(child: Text('Sélectionnez un signalement', textAlign: TextAlign.center))
                    : _ReportDetail(
                        report: selected,
                        operators: ops ?? const [],
                        operatorId: _operatorId,
                        busy: _busy,
                        onOperatorChanged: (v) => setState(() => _operatorId = v),
                        onAssign: () => _update(selected, ReportStatus.inProgress, operatorId: _operatorId),
                        onResolve: () => _update(selected, ReportStatus.resolved),
                        onReopen: () => _update(selected, ReportStatus.reported),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _update(WasteReport r, ReportStatus status, {String? operatorId}) async {
    setState(() => _busy = true);
    try {
      await ref.read(reportRepositoryProvider).updateStatus(r.id, status.wire, operatorId: operatorId);
      await ref.read(notificationRepositoryProvider).create(AppNotification(
            id: '',
            userId: r.authorId,
            title: 'Mise à jour de statut',
            body: 'Votre signalement ${r.reference} est maintenant « ${status.labelFr} »'
                '${operatorId != null ? ' — ${_operatorLabel(ref.read(adminCollectorsProvider).value, operatorId)} intervient.' : '.'}',
            kind: 'status',
            createdAt: DateTime.now(),
            refType: 'report',
            refId: r.id,
          ));
      ref.invalidate(allReportsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signalement ${r.reference} : ${status.labelFr}.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mise à jour impossible : $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv(BuildContext context, List<WasteReport> list, List<Collector>? ops) async {
    final b = StringBuffer('reference;date;statut;urgence;type;ville;adresse;lat;lng;operateur;resolu_le\n');
    for (final r in list) {
      b.writeln([
        r.reference,
        DateFormat('yyyy-MM-dd HH:mm').format(r.createdAt),
        r.status.labelFr,
        r.urgency.labelFr,
        r.category.labelFr,
        r.city,
        r.address.replaceAll(';', ','),
        r.lat,
        r.lng,
        _operatorLabel(ops, r.assignedOperatorId),
        r.resolvedAt == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(r.resolvedAt!),
      ].join(';'));
    }
    await saveCsv(context, 'signalements_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv', b.toString());
  }
}

/// Enregistre un CSV via la boîte de dialogue native ; repli presse-papiers.
Future<void> saveCsv(BuildContext context, String fileName, String content) async {
  try {
    final uri = await FilePicker.saveFile(fileName: fileName, bytes: utf8.encode('\uFEFF$content'), mimeType: 'text/csv');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uri == null ? 'Export annulé.' : 'Export enregistré : ${uri.pathSegments.lastOrNull ?? uri}')));
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copié dans le presse-papiers.')));
  }
}

class _ReportDetail extends StatelessWidget {
  const _ReportDetail({
    required this.report,
    required this.operators,
    required this.operatorId,
    required this.busy,
    required this.onOperatorChanged,
    required this.onAssign,
    required this.onResolve,
    required this.onReopen,
  });

  final WasteReport report;
  final List<Collector> operators;
  final String? operatorId;
  final bool busy;
  final ValueChanged<String?> onOperatorChanged;
  final VoidCallback onAssign;
  final VoidCallback onResolve;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: Text('Détail du signalement ${r.reference}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            StatusBadge(status: r.status),
          ],
        ),
        const SizedBox(height: 12),
        StoragePhoto(bucketId: AppwriteConfig.reportPhotosBucket, fileId: r.photoFileId, fallback: AppAssets.reportDetailPhoto, height: 150, radius: 12),
        const SizedBox(height: 12),
        _kv('Lieu', r.address.isEmpty ? r.city : '${r.address}, ${r.city}'),
        _kv('Coordonnées', '${r.lat.toStringAsFixed(4)}, ${r.lng.toStringAsFixed(4)}'),
        _kv('Signalé le', DateFormat('dd MMM y à HH:mm', 'fr').format(r.createdAt)),
        _kv('Type', r.category.labelFr),
        _kv('Urgence', r.urgency.labelFr),
        if (r.description.isNotEmpty) _kv('Description', r.description),
        if (r.resolvedAt != null) _kv('Résolu le', DateFormat('dd MMM y à HH:mm', 'fr').format(r.resolvedAt!)),
        const SizedBox(height: 10),
        if (r.lat != 0 && r.lng != 0) MiniMap(pins: [MapPin(LatLng(r.lat, r.lng), color: _urgencyColor(r.urgency))], zoom: 15, height: 130, interactive: false),
        const Divider(height: 28),
        const Text('Affectation à un opérateur', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: operators.any((o) => o.id == operatorId) ? operatorId : null,
          isExpanded: true,
          items: [
            for (final o in operators)
              DropdownMenuItem(value: o.id, child: Text(o.company.isNotEmpty ? '${o.company} — ${o.displayName}' : o.displayName, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: r.status == ReportStatus.resolved ? null : onOperatorChanged,
          decoration: const InputDecoration(hintText: 'Société / opérateur'),
        ),
        const SizedBox(height: 12),
        if (r.status != ReportStatus.resolved) ...[
          FilledButton.icon(
            onPressed: busy || operatorId == null ? null : onAssign,
            icon: const Icon(Icons.assignment_ind_outlined),
            label: Text(r.status == ReportStatus.reported ? 'Affecter et prendre en charge' : 'Réaffecter'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onResolve,
            icon: const Icon(Icons.task_alt),
            label: const Text('Marquer comme résolu'),
          ),
        ] else
          OutlinedButton.icon(onPressed: busy ? null : onReopen, icon: const Icon(Icons.replay), label: const Text('Rouvrir le signalement')),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: Text(k, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}

// ---------------------------------------------------------------------- zones

/// Zones et opérateurs (planche 4, écran 3).
class AdminZonesScreen extends ConsumerStatefulWidget {
  const AdminZonesScreen({super.key});

  @override
  ConsumerState<AdminZonesScreen> createState() => _AdminZonesScreenState();
}

class _AdminZonesScreenState extends ConsumerState<AdminZonesScreen> {
  bool _showOperators = false;

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(adminZonesProvider);
    final collectors = ref.watch(adminCollectorsProvider);
    final city = ref.watch(authProvider).user?.city ?? AppConstants.defaultCity;
    return _AdminFrame(
      title: 'Zones et opérateurs',
      subtitle: 'Gérez les zones de collecte et les opérateurs partenaires',
      actions: [
        FilledButton.icon(onPressed: () => _editZone(context, null, city), icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Nouvelle zone')),
        const SizedBox(width: 8),
        IconButton(tooltip: 'Actualiser', onPressed: () => _refreshAdmin(ref), icon: const Icon(Icons.refresh)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, icon: Icon(Icons.map_outlined), label: Text('Zones de collecte')),
                      ButtonSegment(value: true, icon: Icon(Icons.groups_outlined), label: Text('Opérateurs partenaires')),
                    ],
                    selected: {_showOperators},
                    onSelectionChanged: (s) => setState(() => _showOperators = s.first),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: zones.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (list) => MiniMap(
                        pins: [
                          for (var i = 0; i < list.length; i++)
                            MapPin(LatLng(list[i].centerLat, list[i].centerLng), color: _zoneColor(list[i].color), label: '${i + 1}'),
                        ],
                        center: AppConstants.centerFor(city),
                        zoom: 11.8,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  zones.maybeWhen(
                    data: (list) => Wrap(
                      spacing: 12,
                      children: [
                        for (var i = 0; i < list.length; i++)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.circle, size: 10, color: _zoneColor(list[i].color)),
                            const SizedBox(width: 4),
                            Text('Zone ${i + 1} – ${list[i].district}', style: const TextStyle(fontSize: 11)),
                          ]),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _showOperators
                  ? _operatorsPanel(collectors, zones.value ?? const [])
                  : _zonesPanel(zones, collectors.value ?? const [], city),
            ),
          ],
        ),
      ),
    );
  }

  Widget _operatorsPanel(AsyncValue<List<Collector>> collectors, List<Zone> zones) {
    return _card(
      'Opérateurs partenaires',
      collectors.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
        data: (list) => list.isEmpty
            ? const Text('Aucun opérateur. Les entreprises de collecte apparaissent ici dès qu’elles enregistrent leurs collecteurs.')
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Contact')),
                    DataColumn(label: Text('Zones')),
                    DataColumn(label: Text('Statut')),
                  ],
                  rows: [
                    for (final c in list)
                      DataRow(cells: [
                        DataCell(Text(c.company.isNotEmpty ? c.company : c.displayName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(c.phone.isEmpty ? '—' : c.phone)),
                        DataCell(Text(_zonesOf(c, zones))),
                        DataCell(Chip(
                          label: Text(c.isAvailable ? 'Actif' : 'Inactif', style: const TextStyle(fontSize: 11)),
                          backgroundColor: c.isAvailable ? AppColors.paleGreen : AppColors.neutralBackground,
                          side: BorderSide.none,
                        )),
                      ]),
                  ],
                ),
              ),
      ),
      trailing: collectors.maybeWhen(data: (l) => Text('${l.length}', style: const TextStyle(color: AppColors.textMuted)), orElse: () => const SizedBox.shrink()),
    );
  }

  String _zonesOf(Collector c, List<Zone> zones) {
    final assigned = zones.where((z) => z.assignedOperators.contains(c.id)).map((z) => z.district).toList();
    if (assigned.isNotEmpty) return assigned.join(', ');
    return c.coveredZones.isEmpty ? '—' : c.coveredZones.join(', ');
  }

  Widget _zonesPanel(AsyncValue<List<Zone>> zones, List<Collector> ops, String city) {
    return _card(
      'Affectation des zones aux opérateurs',
      zones.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('$e'),
        data: (list) => list.isEmpty
            ? Text('Aucune zone définie pour $city. Créez la première avec « Nouvelle zone ».')
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Zone')),
                    DataColumn(label: Text('Opérateur(s)')),
                    DataColumn(label: Text('Fréquence')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (var i = 0; i < list.length; i++)
                      DataRow(cells: [
                        DataCell(Row(children: [
                          Icon(Icons.circle, size: 10, color: _zoneColor(list[i].color)),
                          const SizedBox(width: 6),
                          Text('Zone ${i + 1} – ${list[i].district}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ])),
                        DataCell(Text(list[i].assignedOperators.isEmpty ? '—' : list[i].assignedOperators.map((id) => _operatorLabel(ops, id)).join(', '))),
                        DataCell(Text(list[i].collectionFrequency.isEmpty ? '—' : list[i].collectionFrequency)),
                        DataCell(Row(children: [
                          TextButton(onPressed: () => _assignOperators(context, list[i], ops), child: const Text('Modifier')),
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _editZone(context, list[i], city)),
                        ])),
                      ]),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _assignOperators(BuildContext context, Zone zone, List<Collector> ops) async {
    final selected = {...zone.assignedOperators};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Opérateurs — ${zone.district}'),
          content: SizedBox(
            width: 400,
            child: ops.isEmpty
                ? const Text('Aucun opérateur enregistré.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final o in ops)
                        CheckboxListTile(
                          value: selected.contains(o.id),
                          title: Text(o.company.isNotEmpty ? o.company : o.displayName),
                          subtitle: Text(o.phone),
                          onChanged: (v) => setLocal(() => v == true ? selected.add(o.id) : selected.remove(o.id)),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(zoneRepositoryProvider).setOperators(zone.id, selected.toList());
    ref.invalidate(adminZonesProvider);
  }

  Future<void> _editZone(BuildContext context, Zone? zone, String city) async {
    final district = TextEditingController(text: zone?.district ?? '');
    final freq = TextEditingController(text: zone?.collectionFrequency ?? 'Hebdomadaire');
    final lat = TextEditingController(text: (zone?.centerLat ?? AppConstants.centerFor(city).latitude).toStringAsFixed(4));
    final lng = TextEditingController(text: (zone?.centerLng ?? AppConstants.centerFor(city).longitude).toStringAsFixed(4));
    var color = zone?.color ?? '#2E7D32';
    const palette = ['#2E7D32', '#1565C0', '#D9A441', '#C62828', '#6A1B9A', '#00838F'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(zone == null ? 'Nouvelle zone — $city' : 'Modifier ${zone.district}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: district, decoration: const InputDecoration(labelText: 'Quartier / arrondissement')),
                const SizedBox(height: 10),
                TextField(controller: freq, decoration: const InputDecoration(labelText: 'Fréquence de collecte')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: lat, decoration: const InputDecoration(labelText: 'Latitude'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: lng, decoration: const InputDecoration(labelText: 'Longitude'))),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in palette)
                      GestureDetector(
                        onTap: () => setLocal(() => color = c),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: _zoneColor(c),
                          child: color == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (ok != true || district.text.trim().isEmpty) return;
    final data = Zone(
      id: zone?.id ?? '',
      city: city,
      district: district.text.trim(),
      assignedOperators: zone?.assignedOperators ?? const [],
      collectionFrequency: freq.text.trim(),
      color: color,
      centerLat: double.tryParse(lat.text) ?? AppConstants.centerFor(city).latitude,
      centerLng: double.tryParse(lng.text) ?? AppConstants.centerFor(city).longitude,
    ).toMap();
    try {
      final tables = ref.read(tablesProvider);
      if (zone == null) {
        await tables.createRow(databaseId: AppwriteConfig.databaseId, tableId: AppwriteConfig.zonesCollection, rowId: 'unique()', data: data);
      } else {
        await tables.updateRow(databaseId: AppwriteConfig.databaseId, tableId: AppwriteConfig.zonesCollection, rowId: zone.id, data: data);
      }
      ref.invalidate(adminZonesProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $e')));
    }
  }

  Color _zoneColor(String value) {
    final parsed = int.tryParse(value.replaceFirst('#', ''), radix: 16);
    return parsed == null ? AppColors.primaryGreen : Color(0xFF000000 | parsed);
  }
}

// -------------------------------------------------------- rapports et campagnes

/// Rapports et communication (planche 4, écran 4).
class AdminReportsCommScreen extends ConsumerStatefulWidget {
  const AdminReportsCommScreen({super.key});

  @override
  ConsumerState<AdminReportsCommScreen> createState() => _AdminReportsCommScreenState();
}

class _AdminReportsCommScreenState extends ConsumerState<AdminReportsCommScreen> {
  final _title = TextEditingController();
  final _msg = TextEditingController();
  String _kind = 'campaign';
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(allReportsProvider).value ?? const <WasteReport>[];
    final zones = ref.watch(adminZonesProvider).value ?? const <Zone>[];
    final ops = ref.watch(adminCollectorsProvider).value ?? const <Collector>[];
    return _AdminFrame(
      title: 'Rapports et communication',
      subtitle: 'Générez des rapports et communiquez avec les citoyens',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _generate(context, 'general', reports, zones, ops),
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Exporter CSV'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rapports disponibles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                _reportTile(Icons.summarize_outlined, 'Rapport général', 'Statistiques globales : signalements, collectes, opérateurs', () => _generate(context, 'general', reports, zones, ops)),
                _reportTile(Icons.map_outlined, 'Rapport par zone', 'Signalements et résolution par quartier', () => _generate(context, 'zone', reports, zones, ops)),
                _reportTile(Icons.groups_outlined, 'Rapport par opérateur', 'Volume traité et taux de résolution par opérateur', () => _generate(context, 'operator', reports, zones, ops)),
                _reportTile(Icons.campaign_outlined, 'Rapport des signalements', 'État de traitement et niveaux d’urgence', () => _generate(context, 'reports', reports, zones, ops)),
              ],
            );
            final right = _card(
              'Envoyer une campagne / alerte citoyenne',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _kind,
                    items: const [
                      DropdownMenuItem(value: 'campaign', child: Text('Campagne de sensibilisation')),
                      DropdownMenuItem(value: 'alert', child: Text('Alerte zone')),
                      DropdownMenuItem(value: 'info', child: Text('Information plateforme')),
                    ],
                    onChanged: (v) => setState(() => _kind = v ?? _kind),
                    decoration: const InputDecoration(labelText: 'Type de message'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titre', hintText: 'Ensemble pour une ville propre !')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msg,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Chers citoyens, triez vos déchets et participez à une ville plus propre…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _target,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Tous les citoyens de la commune')),
                      for (final z in zones) DropdownMenuItem(value: 'zone:${z.district}', child: Text('Quartier ${z.district}')),
                    ],
                    onChanged: (v) => setState(() => _target = v ?? _target),
                    decoration: const InputDecoration(labelText: 'Zone ciblée'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined),
                    label: const Text('Envoyer la campagne'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La campagne est déposée dans les notifications in-app des citoyens ciblés. '
                    'Les canaux SMS et push seront ajoutés via Appwrite Messaging.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 24), Expanded(child: right)])
                : ListView(children: [left, const SizedBox(height: 16), right]);
          },
        ),
      ),
    );
  }

  Widget _reportTile(IconData icon, String t, String s, VoidCallback onTap) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.paleGreen, child: Icon(icon, color: AppColors.primaryGreen)),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(s),
          trailing: FilledButton.tonal(onPressed: onTap, child: const Text('Générer')),
        ),
      );

  Future<void> _generate(BuildContext context, String kind, List<WasteReport> reports, List<Zone> zones, List<Collector> ops) async {
    // Tentative via la Function serveur (PDF), puis génération CSV locale.
    try {
      final ex = await ref.read(functionsProvider).createExecution(
            functionId: AppwriteConfig.generateAdminReportFn,
            body: '{"kind":"$kind"}',
          );
      if (ex.responseStatusCode == 200 && ex.responseBody.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rapport généré : ${ex.responseBody}')));
        return;
      }
    } catch (_) {}
    final b = StringBuffer();
    switch (kind) {
      case 'zone':
        b.writeln('zone;signalements;resolus;taux');
        for (final z in zones) {
          final rs = reports.where((r) => r.address.toLowerCase().contains(z.district.toLowerCase())).toList();
          final done = rs.where((r) => r.status == ReportStatus.resolved).length;
          b.writeln('${z.district};${rs.length};$done;${rs.isEmpty ? 0 : done * 100 ~/ rs.length}%');
        }
      case 'operator':
        b.writeln('operateur;affectes;resolus;taux;interventions');
        for (final o in ops) {
          final rs = reports.where((r) => r.assignedOperatorId == o.id).toList();
          final done = rs.where((r) => r.status == ReportStatus.resolved).length;
          b.writeln('${_operatorLabel(ops, o.id)};${rs.length};$done;${rs.isEmpty ? 0 : done * 100 ~/ rs.length}%;${o.interventionsCount}');
        }
      case 'reports':
        b.writeln('reference;date;statut;urgence;type;lieu');
        for (final r in reports) {
          b.writeln('${r.reference};${DateFormat('yyyy-MM-dd').format(r.createdAt)};${r.status.labelFr};${r.urgency.labelFr};${r.category.labelFr};${r.address}');
        }
      default:
        final resolved = reports.where((r) => r.status == ReportStatus.resolved).length;
        b.writeln('indicateur;valeur');
        b.writeln('signalements;${reports.length}');
        b.writeln('resolus;$resolved');
        b.writeln('taux_resolution;${reports.isEmpty ? 0 : resolved * 100 ~/ reports.length}%');
        b.writeln('zones;${zones.length}');
        b.writeln('operateurs;${ops.length}');
        for (final s in ReportStatus.values) {
          b.writeln('statut_${s.name};${reports.where((r) => r.status == s).length}');
        }
        for (final c in WasteCategory.values) {
          b.writeln('type_${c.name};${reports.where((r) => r.category == c).length}');
        }
    }
    if (!context.mounted) return;
    await saveCsv(context, 'rapport_${kind}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv', b.toString());
  }

  Future<void> _send() async {
    if (_msg.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final tables = ref.read(tablesProvider);
      final rows = await tables.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.usersCollection,
        queries: [
          if (_target.startsWith('zone:')) 'equal("district", ["${_target.substring(5)}"])',
          'equal("role", ["citizen"])',
          'limit(500)',
        ],
      );
      final repo = ref.read(notificationRepositoryProvider);
      final title = _title.text.trim().isEmpty
          ? (_kind == 'alert' ? 'Alerte zone' : _kind == 'info' ? 'Info plateforme' : 'Campagne de sensibilisation')
          : _title.text.trim();
      for (final row in rows.rows) {
        await repo.create(AppNotification(
          id: '',
          userId: row.$id,
          title: title,
          body: _msg.text.trim(),
          kind: _kind,
          createdAt: DateTime.now(),
        ));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campagne envoyée à ${rows.rows.length} citoyen(s).')));
      _msg.clear();
      _title.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
