import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/mini_map.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/collector.dart';
import '../../../shared/models/enums.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../collector/data/collector_actions.dart';
import '../../reporting/data/appwrite_report_repository.dart';

// ----------------------------------------------------------------- providers

final allRequestsProvider = FutureProvider<List<CollectionRequest>>((ref) {
  return ref.watch(requestRepositoryProvider).listAll(limit: 500);
});

final fleetProvider = FutureProvider<List<Collector>>((ref) {
  return ref.watch(collectorRepositoryProvider).list();
});

void _refreshCompany(WidgetRef ref) {
  ref.invalidate(allRequestsProvider);
  ref.invalidate(fleetProvider);
}

String _fcfa(num v) => '${NumberFormat.decimalPattern('fr').format(v)} FCFA';

int _feeFor(CollectionRequest r) =>
    r.amountPaid > 0 ? r.amountPaid : ((r.weightKg ?? 0) * AppConstants.collectorFeePerKg).round();

Color _statusColor(RequestStatus s) => switch (s) {
      RequestStatus.pending => AppColors.earthOchre,
      RequestStatus.matched => AppColors.institutionalBlue,
      RequestStatus.enRoute => AppColors.warning,
      RequestStatus.collected => AppColors.primaryGreen,
      RequestStatus.cancelled => AppColors.danger,
    };

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip(this.status, {super.key});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.labelFr, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.subtitle, required this.child, this.actions = const []});
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackOfficeHeader(title: title, subtitle: subtitle, actions: actions),
        Expanded(child: ColoredBox(color: const Color(0xFFF4F6F5), child: child)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class Kpi extends StatelessWidget {
  const Kpi({super.key, required this.title, required this.value, required this.hint, required this.color, this.icon});
  final String title;
  final String value;
  final String hint;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          if (icon != null) ...[
            CircleAvatar(backgroundColor: Colors.white, child: Icon(icon, color: AppColors.primaryGreen)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- dashboard

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(allRequestsProvider);
    final fleet = ref.watch(fleetProvider);
    final user = ref.watch(authProvider).user;
    return _Frame(
      title: 'Tableau de bord',
      subtitle: 'Activité de collecte, flotte et revenus en temps réel',
      actions: [
        IconButton(tooltip: 'Actualiser', onPressed: () => _refreshCompany(ref), icon: const Icon(Icons.refresh)),
      ],
      child: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Données indisponibles : $e')),
        data: (list) {
          final now = DateTime.now();
          final pending = list.where((r) => r.status == RequestStatus.pending).toList();
          final active = list.where((r) => r.status == RequestStatus.matched || r.status == RequestStatus.enRoute).toList();
          final collected = list.where((r) => r.status == RequestStatus.collected).toList();
          final month = collected.where((r) => (r.collectedAt ?? r.createdAt ?? now).month == now.month && (r.collectedAt ?? r.createdAt ?? now).year == now.year);
          final revenue = month.fold(0, (s, r) => s + _feeFor(r));
          final kg = collected.fold(0.0, (s, r) => s + (r.weightKg ?? 0));
          final online = fleet.value?.where((c) => c.isAvailable).length ?? 0;
          final days = List.generate(14, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 13 - i)));
          final perDay = [
            for (final d in days)
              list.where((r) {
                final c = r.createdAt ?? r.scheduledAt;
                return c != null && c.year == d.year && c.month == d.month && c.day == d.day;
              }).length,
          ];
          final pins = [
            for (final r in [...pending, ...active].where((r) => r.hasPosition))
              MapPin(LatLng(r.lat!, r.lng!), color: _statusColor(r.status)),
          ];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Kpi(title: 'Demandes en attente', value: '${pending.length}', hint: 'à dispatcher', color: AppColors.paleOchre, icon: Icons.pending_actions),
                  Kpi(title: 'Collectes en cours', value: '${active.length}', hint: 'affectées / en route', color: const Color(0xFFE3F2FD), icon: Icons.local_shipping_outlined),
                  Kpi(title: 'Volume collecté', value: kg >= 1000 ? '${(kg / 1000).toStringAsFixed(1)} t' : '${kg.toStringAsFixed(0)} kg', hint: '${collected.length} collecte(s) validée(s)', color: AppColors.paleGreen, icon: Icons.scale_outlined),
                  Kpi(title: 'Revenus du mois', value: _fcfa(revenue), hint: DateFormat('MMMM y', 'fr').format(now), color: const Color(0xFFFFF8E1), icon: Icons.payments_outlined),
                  Kpi(title: 'Collecteurs en ligne', value: '$online / ${fleet.value?.length ?? 0}', hint: 'disponibles maintenant', color: Colors.white, icon: Icons.groups_outlined),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 900;
                  final map = _Card(
                    title: 'Carte des demandes ouvertes',
                    trailing: Text('${pins.length} géolocalisée(s)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    child: MiniMap(pins: pins, center: AppConstants.centerFor(user?.city ?? AppConstants.defaultCity), zoom: 12, height: 300),
                  );
                  final chart = _Card(
                    title: 'Demandes reçues · 14 derniers jours',
                    child: SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                            rightTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 2,
                                getTitlesWidget: (v, _) => Text(DateFormat('d/M').format(days[v.toInt()]), style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < days.length; i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(toY: perDay[i].toDouble(), color: AppColors.primaryGreen, width: 12, borderRadius: BorderRadius.circular(4)),
                              ]),
                          ],
                        ),
                      ),
                    ),
                  );
                  return wide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: map), const SizedBox(width: 16), Expanded(child: chart)])
                      : Column(children: [map, const SizedBox(height: 16), chart]);
                },
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Dernières demandes',
                child: Column(
                  children: [
                    for (final r in list.take(8))
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _statusColor(r.status).withValues(alpha: .12),
                          child: Icon(Icons.delete_outline, size: 16, color: _statusColor(r.status)),
                        ),
                        title: Text('${r.wasteType.labelFr} · ${r.estimatedVolume.labelFr}'),
                        subtitle: Text('${r.address.isEmpty ? r.city : r.address} · ${r.createdAt == null ? '' : DateFormat('dd/MM HH:mm').format(r.createdAt!)}'),
                        trailing: RequestStatusChip(r.status),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- dispatch

class CompanyDispatchScreen extends ConsumerStatefulWidget {
  const CompanyDispatchScreen({super.key});

  @override
  ConsumerState<CompanyDispatchScreen> createState() => _CompanyDispatchScreenState();
}

class _CompanyDispatchScreenState extends ConsumerState<CompanyDispatchScreen> {
  RequestStatus? _filter = RequestStatus.pending;
  String _search = '';
  String? _selectedId;
  String? _collectorId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(allRequestsProvider);
    final fleet = ref.watch(fleetProvider);
    return _Frame(
      title: 'Dispatch des demandes',
      subtitle: 'Affectez chaque demande de collecte au bon collecteur',
      actions: [
        IconButton(tooltip: 'Actualiser', onPressed: () => _refreshCompany(ref), icon: const Icon(Icons.refresh)),
      ],
      child: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final list = all.where((r) {
            final okStatus = _filter == null || r.status == _filter;
            final q = _search.toLowerCase();
            final okSearch = q.isEmpty || r.address.toLowerCase().contains(q) || r.city.toLowerCase().contains(q) || r.wasteType.labelFr.toLowerCase().contains(q);
            return okStatus && okSearch;
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
                            child: TextField(
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher une adresse, une ville, un type…', isDense: true),
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ChoiceChip(label: Text('Toutes (${all.length})'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                            const SizedBox(width: 8),
                            for (final s in RequestStatus.values) ...[
                              ChoiceChip(
                                label: Text('${s.labelFr} (${all.where((r) => r.status == s).length})'),
                                selected: _filter == s,
                                onSelected: (_) => setState(() => _filter = s),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.antiAlias,
                          child: list.isEmpty
                              ? const Center(child: Text('Aucune demande pour ce filtre.'))
                              : SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      columnSpacing: 20,
                                      columns: const [
                                        DataColumn(label: Text('Date')),
                                        DataColumn(label: Text('Lieu')),
                                        DataColumn(label: Text('Type')),
                                        DataColumn(label: Text('Volume')),
                                        DataColumn(label: Text('Statut')),
                                        DataColumn(label: Text('Collecteur')),
                                      ],
                                      rows: [
                                        for (final r in list)
                                          DataRow(
                                            selected: r.id == _selectedId,
                                            onSelectChanged: (_) => setState(() {
                                              _selectedId = r.id;
                                              _collectorId = r.assignedCollectorId;
                                            }),
                                            cells: [
                                              DataCell(Text(r.scheduledAt != null ? DateFormat('dd/MM HH:mm').format(r.scheduledAt!) : (r.timeSlot.isEmpty ? '—' : r.timeSlot))),
                                              DataCell(Text(r.address.isEmpty ? r.city : r.address, overflow: TextOverflow.ellipsis)),
                                              DataCell(Text(r.wasteType.labelFr)),
                                              DataCell(Text(r.estimatedVolume.labelFr.split(' ').first)),
                                              DataCell(RequestStatusChip(r.status)),
                                              DataCell(Text(_collectorName(fleet.value, r.assignedCollectorId))),
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
                    ? const Center(child: Text('Sélectionnez une demande pour la dispatcher', textAlign: TextAlign.center))
                    : _DetailPanel(
                        request: selected,
                        fleet: fleet.value ?? const [],
                        collectorId: _collectorId,
                        busy: _busy,
                        onCollectorChanged: (v) => setState(() => _collectorId = v),
                        onAssign: () => _assign(selected, fleet.value ?? const []),
                        onCancel: () => _cancel(selected),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _collectorName(List<Collector>? fleet, String? id) {
    if (id == null) return '—';
    final c = fleet?.where((c) => c.id == id).firstOrNull;
    return c == null ? id.substring(0, id.length.clamp(0, 6)) : (c.displayName.isEmpty ? c.company : c.displayName);
  }

  Future<void> _assign(CollectionRequest r, List<Collector> fleet) async {
    final c = fleet.where((c) => c.id == _collectorId).firstOrNull;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(collectorActionsProvider).accept(r, c);
      _refreshCompany(ref);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demande affectée à ${c.displayName}.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Affectation impossible : $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(CollectionRequest r) async {
    setState(() => _busy = true);
    try {
      await ref.read(collectorActionsProvider).cancel(r, reason: 'Votre demande a été annulée par l’entreprise de collecte.');
      _refreshCompany(ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.request,
    required this.fleet,
    required this.collectorId,
    required this.busy,
    required this.onCollectorChanged,
    required this.onAssign,
    required this.onCancel,
  });

  final CollectionRequest request;
  final List<Collector> fleet;
  final String? collectorId;
  final bool busy;
  final ValueChanged<String?> onCollectorChanged;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final sorted = [...fleet]..sort((a, b) => (b.isAvailable ? 1 : 0) - (a.isAvailable ? 1 : 0));
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: Text('Demande ${r.id.substring(0, r.id.length.clamp(0, 8)).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            RequestStatusChip(r.status),
          ],
        ),
        const SizedBox(height: 12),
        if (r.hasPosition) MiniMap(pins: [MapPin(LatLng(r.lat!, r.lng!), color: _statusColor(r.status))], zoom: 14, height: 140, interactive: false),
        const SizedBox(height: 12),
        _kv('Adresse', r.address.isEmpty ? r.city : '${r.address}, ${r.city}'),
        _kv('Type', r.wasteType.labelFr),
        _kv('Volume', r.estimatedVolume.labelFr),
        _kv('Créneau', r.scheduledAt != null ? DateFormat('EEE d MMM · HH:mm', 'fr').format(r.scheduledAt!) : (r.timeSlot.isEmpty ? 'Flexible' : r.timeSlot)),
        _kv('Paiement', '${_fcfa(r.amountPaid)} · ${r.paymentProvider ?? 'Mobile Money'}'),
        if (r.notes.isNotEmpty) _kv('Consignes', r.notes),
        if (r.weightKg != null) _kv('Poids collecté', '${r.weightKg} kg'),
        const Divider(height: 28),
        const Text('Affectation à un collecteur', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: sorted.any((c) => c.id == collectorId) ? collectorId : null,
          isExpanded: true,
          items: [
            for (final c in sorted)
              DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: c.isAvailable ? AppColors.primaryGreen : AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${c.displayName.isEmpty ? c.company : c.displayName}${c.coveredZones.isEmpty ? '' : ' · ${c.coveredZones.first}'}', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
          ],
          onChanged: r.status.isOpen ? onCollectorChanged : null,
          decoration: const InputDecoration(hintText: 'Choisir un collecteur'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy || !r.status.isOpen || collectorId == null || collectorId == r.assignedCollectorId ? null : onAssign,
          icon: const Icon(Icons.assignment_ind_outlined),
          label: Text(r.assignedCollectorId == null ? 'Affecter' : 'Réaffecter'),
        ),
        const SizedBox(height: 8),
        if (r.status.isOpen)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: busy ? null : onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Annuler la demande'),
          ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(k, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

// ------------------------------------------------------------------- flotte

class CompanyFleetScreen extends ConsumerWidget {
  const CompanyFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleet = ref.watch(fleetProvider);
    final requests = ref.watch(allRequestsProvider).value ?? const <CollectionRequest>[];
    return _Frame(
      title: 'Flotte et collecteurs',
      subtitle: 'Disponibilité, zones couvertes et performance de vos équipes',
      actions: [
        FilledButton.icon(
          onPressed: () => _editCollector(context, ref, null),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Ajouter un collecteur'),
        ),
      ],
      child: fleet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                Kpi(title: 'Collecteurs', value: '${list.length}', hint: 'enregistrés', color: Colors.white, icon: Icons.groups_outlined),
                Kpi(title: 'Disponibles', value: '${list.where((c) => c.isAvailable).length}', hint: 'en ligne maintenant', color: AppColors.paleGreen, icon: Icons.wifi_tethering),
                Kpi(title: 'Interventions', value: '${list.fold(0, (s, c) => s + c.interventionsCount)}', hint: 'cumulées', color: AppColors.paleOchre, icon: Icons.task_alt),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: list.isEmpty
                  ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun collecteur. Ajoutez votre première équipe.')))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Collecteur')),
                          DataColumn(label: Text('Entreprise')),
                          DataColumn(label: Text('Téléphone')),
                          DataColumn(label: Text('Zones')),
                          DataColumn(label: Text('En cours')),
                          DataColumn(label: Text('Interventions')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('')),
                        ],
                        rows: [
                          for (final c in list)
                            DataRow(cells: [
                              DataCell(Row(children: [
                                const CircleAvatar(radius: 14, backgroundColor: AppColors.paleGreen, child: Icon(Icons.person, size: 16, color: AppColors.primaryGreen)),
                                const SizedBox(width: 8),
                                Text(c.displayName.isEmpty ? '—' : c.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ])),
                              DataCell(Text(c.company.isEmpty ? '—' : c.company)),
                              DataCell(Text(c.phone.isEmpty ? '—' : c.phone)),
                              DataCell(Text(c.coveredZones.isEmpty ? '—' : c.coveredZones.join(', '))),
                              DataCell(Text('${requests.where((r) => r.assignedCollectorId == c.id && r.status.isOpen).length}')),
                              DataCell(Text('${c.interventionsCount}')),
                              DataCell(Switch(
                                value: c.isAvailable,
                                onChanged: (v) async {
                                  await ref.read(collectorRepositoryProvider).setAvailability(c.id, v);
                                  ref.invalidate(fleetProvider);
                                },
                              )),
                              DataCell(IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editCollector(context, ref, c))),
                            ]),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCollector(BuildContext context, WidgetRef ref, Collector? existing) async {
    final name = TextEditingController(text: existing?.displayName ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final company = TextEditingController(text: existing?.company ?? '');
    final zones = TextEditingController(text: existing?.coveredZones.join(', ') ?? '');
    final userId = TextEditingController(text: existing?.userId ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nouveau collecteur' : 'Modifier le collecteur'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom complet')),
              const SizedBox(height: 10),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 10),
              TextField(controller: company, decoration: const InputDecoration(labelText: 'Entreprise')),
              const SizedBox(height: 10),
              TextField(controller: zones, decoration: const InputDecoration(labelText: 'Zones couvertes (séparées par des virgules)')),
              const SizedBox(height: 10),
              TextField(
                controller: userId,
                decoration: const InputDecoration(
                  labelText: 'ID utilisateur Appwrite (optionnel)',
                  helperText: 'Lie la fiche au compte mobile du collecteur',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ref.read(collectorRepositoryProvider).upsert(Collector(
            id: existing?.id ?? '',
            userId: userId.text.trim(),
            coveredZones: zones.text.split(',').map((z) => z.trim()).where((z) => z.isNotEmpty).toList(),
            isAvailable: existing?.isAvailable ?? true,
            interventionsCount: existing?.interventionsCount ?? 0,
            displayName: name.text.trim(),
            phone: phone.text.trim(),
            company: company.text.trim(),
          ));
      ref.invalidate(fleetProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $e')));
    }
  }
}

// ------------------------------------------------------------------ revenus

class CompanyRevenueScreen extends ConsumerWidget {
  const CompanyRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(allRequestsProvider);
    final fleet = ref.watch(fleetProvider).value ?? const <Collector>[];
    return _Frame(
      title: 'Revenus',
      subtitle: 'Chiffre d’affaires des collectes validées et répartition par collecteur',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _exportCsv(context, requests.value ?? const [], fleet),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exporter CSV'),
        ),
      ],
      child: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final done = list.where((r) => r.status == RequestStatus.collected).toList();
          final now = DateTime.now();
          final days = List.generate(30, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 29 - i)));
          final perDay = [
            for (final d in days)
              done.where((r) {
                final c = r.collectedAt ?? r.scheduledAt ?? r.createdAt;
                return c != null && c.year == d.year && c.month == d.month && c.day == d.day;
              }).fold(0, (s, r) => s + _feeFor(r)),
          ];
          final total = done.fold(0, (s, r) => s + _feeFor(r));
          final last30 = perDay.fold(0, (s, v) => s + v);
          final byCollector = <String, (int, int, double)>{};
          for (final r in done) {
            final k = r.assignedCollectorId ?? '—';
            final prev = byCollector[k] ?? (0, 0, 0.0);
            byCollector[k] = (prev.$1 + 1, prev.$2 + _feeFor(r), prev.$3 + (r.weightKg ?? 0));
          }
          final rows = byCollector.entries.toList()..sort((a, b) => b.value.$2.compareTo(a.value.$2));
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Kpi(title: 'Total encaissé', value: _fcfa(total), hint: '${done.length} collecte(s)', color: AppColors.paleGreen, icon: Icons.payments_outlined),
                  Kpi(title: '30 derniers jours', value: _fcfa(last30), hint: 'collectes validées', color: const Color(0xFFFFF8E1), icon: Icons.calendar_month_outlined),
                  Kpi(title: 'Panier moyen', value: done.isEmpty ? '—' : _fcfa(total ~/ done.length), hint: 'par collecte', color: Colors.white, icon: Icons.receipt_long_outlined),
                ],
              ),
              const SizedBox(height: 24),
              _Card(
                title: 'Revenus par jour · 30 jours',
                child: SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48)),
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
                          color: AppColors.primaryGreen,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppColors.primaryGreen.withValues(alpha: .12)),
                          spots: [for (var i = 0; i < 30; i++) FlSpot(i.toDouble(), perDay[i].toDouble())],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Répartition par collecteur',
                child: rows.isEmpty
                    ? const Text('Aucune collecte validée pour le moment.')
                    : DataTable(
                        columns: const [
                          DataColumn(label: Text('Collecteur')),
                          DataColumn(label: Text('Collectes'), numeric: true),
                          DataColumn(label: Text('Volume (kg)'), numeric: true),
                          DataColumn(label: Text('Revenus'), numeric: true),
                          DataColumn(label: Text('Part')),
                        ],
                        rows: [
                          for (final e in rows)
                            DataRow(cells: [
                              DataCell(Text(_name(fleet, e.key))),
                              DataCell(Text('${e.value.$1}')),
                              DataCell(Text(e.value.$3.toStringAsFixed(1))),
                              DataCell(Text(_fcfa(e.value.$2), style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(SizedBox(
                                width: 120,
                                child: LinearProgressIndicator(value: total == 0 ? 0 : e.value.$2 / total, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                              )),
                            ]),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _name(List<Collector> fleet, String id) {
    final c = fleet.where((c) => c.id == id).firstOrNull;
    return c == null ? (id == '—' ? 'Non affecté' : id) : (c.displayName.isEmpty ? c.company : c.displayName);
  }

  Future<void> _exportCsv(BuildContext context, List<CollectionRequest> list, List<Collector> fleet) async {
    final buffer = StringBuffer('id;date;statut;ville;adresse;type;volume;poids_kg;montant_fcfa;collecteur\n');
    for (final r in list) {
      final date = r.collectedAt ?? r.scheduledAt ?? r.createdAt;
      buffer.writeln([
        r.id,
        date == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(date),
        r.status.labelFr,
        r.city,
        r.address.replaceAll(';', ','),
        r.wasteType.labelFr,
        r.estimatedVolume.wire,
        r.weightKg?.toString() ?? '',
        _feeFor(r),
        _name(fleet, r.assignedCollectorId ?? '—'),
      ].join(';'));
    }
    final bytes = utf8.encode('\uFEFF${buffer.toString()}');
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'eco_responsable_revenus_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
        bytes: bytes,
        mimeType: 'text/csv',
        dialogTitle: 'Exporter les revenus',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uri == null ? 'Export annulé.' : 'Export enregistré : ${uri.pathSegments.lastOrNull ?? uri}')),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copié dans le presse-papiers.')));
    }
  }
}

/// Illustration réutilisable pour les états vides des back-offices.
class EmptyIllustration extends StatelessWidget {
  const EmptyIllustration({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AssetImageBox(asset: AppAssets.collectorTruck, height: 96, width: 96, radius: 24),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDark)),
      ],
    );
  }
}
