import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/appwrite/appwrite_client.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/mini_map.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../core/utils/photo_picker.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/collector.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/reward_item.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reporting/data/appwrite_report_repository.dart';
import '../data/collector_actions.dart';

// ----------------------------------------------------------------- providers

/// Fiche collecteur de l'utilisateur connecté ; créée à la volée si absente
/// (profil « collecteur » fraîchement inscrit).
final myCollectorProvider = FutureProvider<Collector?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;
  final repo = ref.watch(collectorRepositoryProvider);
  final existing = await repo.byUserId(user.id);
  if (existing != null || user.role != UserRole.collector) return existing;
  return repo.upsert(Collector(
    id: '',
    userId: user.id,
    coveredZones: [if (user.district.isNotEmpty) user.district, user.city],
    isAvailable: true,
    displayName: user.name,
    phone: user.phone,
  ));
});

final pendingRequestsProvider = FutureProvider<List<CollectionRequest>>((ref) {
  final city = ref.watch(authProvider).user?.city;
  return ref.watch(requestRepositoryProvider).listPending(city: city);
});

final collectorRequestsProvider = FutureProvider<List<CollectionRequest>>((ref) async {
  final me = await ref.watch(myCollectorProvider.future);
  if (me == null) return const [];
  return ref.watch(requestRepositoryProvider).listForCollector(me.id);
});

final requestByIdProvider = FutureProvider.family<CollectionRequest, String>((ref, id) {
  return ref.watch(requestRepositoryProvider).getById(id);
});

void _refreshCollectorData(WidgetRef ref) {
  ref.invalidate(pendingRequestsProvider);
  ref.invalidate(collectorRequestsProvider);
}

String _fcfa(num v) => '${NumberFormat.decimalPattern('fr').format(v)} FCFA';

int _feeFor(CollectionRequest r) =>
    r.amountPaid > 0 ? r.amountPaid : ((r.weightKg ?? 0) * AppConstants.collectorFeePerKg).round();

String _wasteAsset(WasteCategory c) => switch (c) {
      WasteCategory.menager => AppAssets.reportHousehold,
      WasteCategory.plastique => AppAssets.reportBin,
      WasteCategory.electronique => AppAssets.iconRecycle,
      WasteCategory.encombrant => AppAssets.reportDump,
    };

// -------------------------------------------------------------------- accueil

/// Accueil collecteur (planche 5, écran 1).
class CollectorHomeScreen extends ConsumerWidget {
  const CollectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final col = ref.watch(myCollectorProvider);
    final pending = ref.watch(pendingRequestsProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final firstName = (user?.name ?? 'Collecteur').split(' ').first;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const AssetImageBox(asset: AppAssets.logoWhite, height: 32, width: 32, radius: 8),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Éco-Responsable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Ensemble pour un Cameroun plus propre', style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: IconButton(
              onPressed: () => showNotificationsSheet(context),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshCollectorData(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Bonjour $firstName !', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            Text(
              'Collecteur · ${user?.city ?? AppConstants.defaultCity}',
              style: const TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            col.when(
              data: (c) => _OnlineCard(collector: c),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Demandes à proximité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                ),
                pending.maybeWhen(
                  data: (l) => Badge.count(count: l.length, backgroundColor: AppColors.primaryGreen),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            pending.when(
              data: (list) => list.isEmpty
                  ? const _EmptyCard(text: 'Aucune demande en attente dans votre ville pour l’instant.')
                  : Column(
                      children: [
                        for (final r in list.take(6))
                          _RequestTile(
                            request: r,
                            trailing: _timeChip(r),
                            onTap: () => context.push('/collector/stop/${r.id}'),
                          ),
                      ],
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _EmptyCard(text: 'Demandes indisponibles : $e'),
            ),
            const SizedBox(height: 16),
            pending.maybeWhen(
              data: (list) {
                final pins = [
                  for (final r in list.where((r) => r.hasPosition))
                    MapPin(LatLng(r.lat!, r.lng!), color: AppColors.earthOchre),
                ];
                return MiniMap(
                  pins: pins,
                  center: AppConstants.centerFor(user?.city ?? AppConstants.defaultCity),
                  zoom: 12,
                  height: 170,
                  interactive: false,
                  overlay: Positioned(
                    right: 10,
                    top: 10,
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.go('/collector/tour'),
                      icon: const Icon(Icons.route, size: 16),
                      label: const Text('Ma tournée'),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(CollectionRequest r) {
    final at = r.scheduledAt;
    final label = at == null
        ? (r.timeSlot.isEmpty ? 'Flexible' : r.timeSlot)
        : (at.difference(DateTime.now()).inHours.abs() < 24
            ? DateFormat('HH:mm').format(at)
            : DateFormat('dd/MM').format(at));
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.paleGreen,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}

class _OnlineCard extends ConsumerWidget {
  const _OnlineCard({required this.collector});
  final Collector? collector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = collector;
    final online = c?.isAvailable ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? AppColors.primaryGreen : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(online ? 'En ligne' : 'Hors ligne', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  online ? 'Vous recevez les demandes de collecte' : 'Activez pour recevoir des demandes',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          Switch(
            value: online,
            onChanged: c == null
                ? null
                : (v) async {
                    await ref.read(collectorRepositoryProvider).setAvailability(c.id, v);
                    ref.invalidate(myCollectorProvider);
                  },
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, this.trailing, this.onTap, this.index});
  final CollectionRequest request;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: index == null
            ? AssetImageBox(asset: _wasteAsset(r.wasteType), height: 44, width: 44, radius: 12)
            : CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
        title: Text(r.wasteType.labelFr, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${r.address.isEmpty ? r.city : r.address}\n${r.estimatedVolume.labelFr}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailing,
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const AssetImageBox(asset: AppAssets.collectorTruck, height: 48, width: 48, radius: 12),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textDark))),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------- tournée

/// Tournée du jour (planche 5, écran 2) : arrêts assignés, carte et itinéraire.
class CollectorTourScreen extends ConsumerStatefulWidget {
  const CollectorTourScreen({super.key});

  @override
  ConsumerState<CollectorTourScreen> createState() => _CollectorTourScreenState();
}

class _CollectorTourScreenState extends ConsumerState<CollectorTourScreen> {
  bool _mapExpanded = false;

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(collectorRequestsProvider);
    final today = DateFormat('EEE d MMM y', 'fr').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournée du jour'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 6),
                Text(today, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: mine.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Tournée indisponible : $e')),
        data: (all) {
          final stops = all.where((r) => r.status == RequestStatus.matched || r.status == RequestStatus.enRoute).toList()
            ..sort((a, b) => (a.scheduledAt ?? DateTime(2100)).compareTo(b.scheduledAt ?? DateTime(2100)));
          final pins = [
            for (var i = 0; i < stops.length; i++)
              if (stops[i].hasPosition) MapPin(LatLng(stops[i].lat!, stops[i].lng!), label: '${i + 1}'),
          ];
          final totalKm = _estimateKm(pins.map((p) => p.point).toList());
          return RefreshIndicator(
            onRefresh: () async => _refreshCollectorData(ref),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.alt_route, color: AppColors.primaryGreen, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Itinéraire optimisé', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${stops.length} arrêt(s) · ${totalKm.toStringAsFixed(1)} km · ≈ ${_duration(stops.length, totalKm)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
                        icon: Icon(_mapExpanded ? Icons.expand_less : Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MiniMap(
                  pins: pins,
                  center: AppConstants.centerFor(ref.read(authProvider).user?.city ?? AppConstants.defaultCity),
                  polyline: true,
                  zoom: pins.isEmpty ? 12 : 13,
                  height: _mapExpanded ? 360 : 200,
                ),
                const SizedBox(height: 16),
                Text('Liste des arrêts (${stops.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                if (stops.isEmpty)
                  const _EmptyCard(
                    text: 'Aucun arrêt planifié. Acceptez des demandes depuis l’accueil ou attendez le dispatch de votre entreprise.',
                  ),
                for (var i = 0; i < stops.length; i++)
                  _RequestTile(
                    index: i + 1,
                    request: stops[i],
                    trailing: stops[i].status == RequestStatus.enRoute
                        ? const Chip(label: Text('En route', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero)
                        : null,
                    onTap: () => context.push('/collector/stop/${stops[i].id}'),
                  ),
                const SizedBox(height: 12),
                if (pins.isNotEmpty)
                  PrimaryButton(
                    label: 'Voir l’itinéraire sur la carte',
                    icon: Icons.map_outlined,
                    onPressed: () => _openRoute(pins.map((p) => p.point).toList()),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  double _estimateKm(List<LatLng> pts) {
    const d = Distance();
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      total += d.as(LengthUnit.Kilometer, pts[i - 1], pts[i]);
    }
    return total * 1.3; // facteur voirie
  }

  String _duration(int stops, double km) {
    final minutes = (km / 25 * 60 + stops * 12).round();
    return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _openRoute(List<LatLng> pts) async {
    final route = pts.map((p) => '${p.latitude},${p.longitude}').join('/');
    final uri = Uri.parse('https://www.google.com/maps/dir/$route');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ---------------------------------------------------------------------- arrêt

/// Détail d'un arrêt (planche 5, écran 3) avec actions Accepter / Démarrer /
/// Confirmer / Itinéraire / Contacter.
class CollectorStopDetailScreen extends ConsumerWidget {
  const CollectorStopDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(requestByIdProvider(requestId));
    final me = ref.watch(myCollectorProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’arrêt')),
      body: request.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Demande introuvable : $e')),
        data: (r) {
          final mine = me != null && r.assignedCollectorId == me.id;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (r.hasPosition)
                    MiniMap(
                      pins: [MapPin(LatLng(r.lat!, r.lng!), label: '•')],
                      zoom: 15,
                      height: 180,
                      overlay: Positioned(
                        right: 10,
                        bottom: 10,
                        child: FloatingActionButton.small(
                          heroTag: null,
                          onPressed: () => _navigate(r),
                          child: const Icon(Icons.navigation_outlined),
                        ),
                      ),
                    )
                  else
                    MiniMap(
                      pins: const [],
                      center: AppConstants.centerFor(r.city),
                      zoom: 12,
                      height: 160,
                      interactive: false,
                      overlay: const Positioned(
                        left: 10,
                        bottom: 10,
                        child: Chip(label: Text('Position non renseignée'), backgroundColor: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      AssetImageBox(asset: _wasteAsset(r.wasteType), height: 52, width: 52, radius: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.status == RequestStatus.pending ? 'Demande en attente' : 'Arrêt · ${r.status.labelFr}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            Text(
                              r.address.isEmpty ? r.city : r.address,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                                Text(' ${r.city}', style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StopInfo(icon: Icons.delete_outline, label: 'Type de déchet', value: r.wasteType.labelFr),
                  _StopInfo(icon: Icons.inventory_2_outlined, label: 'Volume estimé', value: r.estimatedVolume.labelFr),
                  _StopInfo(
                    icon: Icons.schedule,
                    label: 'Créneau',
                    value: r.scheduledAt != null
                        ? DateFormat('EEE d MMM · HH:mm', 'fr').format(r.scheduledAt!)
                        : (r.timeSlot.isEmpty ? 'Flexible' : r.timeSlot),
                  ),
                  if (r.notes.isNotEmpty) _StopInfo(icon: Icons.notes, label: 'Consignes', value: r.notes),
                  _StopInfo(
                    icon: Icons.payments_outlined,
                    label: 'Rémunération',
                    value: r.amountPaid > 0 ? _fcfa(r.amountPaid) : 'Selon poids (${AppConstants.collectorFeePerKg} FCFA/kg)',
                  ),
                  const SizedBox(height: 8),
                  _CitizenContact(request: r),
                  const SizedBox(height: 20),
                  ..._actions(context, ref, r, me, mine),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: r.hasPosition ? () => _navigate(r) : null,
                    icon: const Icon(Icons.turn_right),
                    label: const Text('Itinéraire'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      children: [
                        Icon(Icons.eco, color: AppColors.primaryGreen),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Un geste aujourd’hui, un environnement plus sain demain.',
                            style: TextStyle(fontSize: 12, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref, CollectionRequest r, Collector? me, bool mine) {
    Future<void> run(Future<void> Function() action, String success) async {
      try {
        await action();
        ref.invalidate(requestByIdProvider(r.id));
        _refreshCollectorData(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action impossible : $e')));
        }
      }
    }

    switch (r.status) {
      case RequestStatus.pending:
        return [
          PrimaryButton(
            label: 'Accepter',
            icon: Icons.check_circle_outline,
            onPressed: me == null
                ? null
                : () => run(
                      () => ref.read(collectorActionsProvider).accept(r, me),
                      'Demande acceptée et ajoutée à votre tournée.',
                    ),
          ),
          if (me == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Votre fiche collecteur n’est pas encore créée : passez votre profil en « Collecteur ».',
                style: TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
        ];
      case RequestStatus.matched:
        return [
          if (mine)
            PrimaryButton(
              label: 'Démarrer (en route)',
              icon: Icons.play_arrow,
              onPressed: () => run(
                () => ref.read(collectorActionsProvider).start(r),
                'Le citoyen est prévenu de votre arrivée.',
              ),
            )
          else
            const _EmptyCard(text: 'Cette demande est déjà affectée à un autre collecteur.'),
        ];
      case RequestStatus.enRoute:
        return [
          if (mine)
            PrimaryButton(
              label: 'Confirmer la collecte',
              icon: Icons.task_alt,
              onPressed: () => context.push('/collector/confirm/${r.id}'),
            )
          else
            const _EmptyCard(text: 'Collecte en cours par un autre collecteur.'),
        ];
      case RequestStatus.collected:
        return [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Collecte validée · ${r.weightKg ?? 0} kg · ${_fcfa(_feeFor(r))}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ];
      case RequestStatus.cancelled:
        return [const _EmptyCard(text: 'Cette demande a été annulée.')];
    }
  }

  Future<void> _navigate(CollectionRequest r) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StopInfo extends StatelessWidget {
  const _StopInfo({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 20, backgroundColor: AppColors.paleGreen, child: Icon(icon, color: AppColors.primaryGreen, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Coordonnées du citoyen (lecture de la table users).
class _CitizenContact extends ConsumerWidget {
  const _CitizenContact({required this.request});
  final CollectionRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(_userRowProvider(request.authorId));
    return author.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (u) {
        final name = u?['name'] as String? ?? 'Citoyen';
        final phone = u?['phone'] as String? ?? '';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: AppColors.paleGreen, child: Icon(Icons.person_outline, color: AppColors.primaryGreen)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact citoyen', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              if (phone.isNotEmpty) ...[
                IconButton.filledTonal(
                  tooltip: 'Appeler',
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                  icon: const Icon(Icons.call_outlined, size: 20),
                ),
                IconButton.filledTonal(
                  tooltip: 'WhatsApp',
                  onPressed: () => launchUrl(
                    Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'\D'), '')}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 20),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

final _userRowProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  try {
    final row = await ref.read(collectorRepositoryProvider).byUserId(userId);
    if (row != null && row.phone.isNotEmpty) return {'name': row.displayName, 'phone': row.phone};
  } catch (_) {}
  try {
    final tables = ref.read(tablesProvider);
    final row = await tables.getRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: AppwriteConfig.usersCollection,
      rowId: userId,
    );
    return row.data;
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------- confirmation

/// Confirmation de collecte (planche 6, écran 1) : preuve, poids, validation.
class CollectorConfirmScreen extends ConsumerStatefulWidget {
  const CollectorConfirmScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<CollectorConfirmScreen> createState() => _CollectorConfirmScreenState();
}

class _CollectorConfirmScreenState extends ConsumerState<CollectorConfirmScreen> {
  final _weight = TextEditingController(text: '25');
  bool _liters = false;
  Uint8List? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await PhotoPicker.pick(context);
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _confirm(CollectionRequest r) async {
    final raw = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indiquez un poids ou un volume valide.')));
      return;
    }
    final kg = _liters ? raw * 0.25 : raw; // densité moyenne déchets ménagers
    setState(() => _saving = true);
    try {
      await ref.read(collectorActionsProvider).confirm(
            r,
            weightKg: double.parse(kg.toStringAsFixed(1)),
            proofBytes: _photo,
            collector: ref.read(myCollectorProvider).value,
          );
      _refreshCollectorData(ref);
      ref.invalidate(requestByIdProvider(r.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collecte confirmée. En attente de validation par Éco-Responsable.')),
      );
      context.go('/collector/history');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Confirmation impossible : $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestByIdProvider(widget.requestId));
    final step = _photo == null ? 0 : (_weight.text.isEmpty ? 1 : 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation de collecte')),
      body: request.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (r) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Steps(current: step),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      if (_photo == null)
                        const AssetImageBox(asset: AppAssets.proofPlaceholder, height: 200, width: double.infinity)
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Chip(
                          avatar: Icon(
                            _photo == null ? Icons.add_a_photo_outlined : Icons.check_circle,
                            size: 16,
                            color: AppColors.primaryGreen,
                          ),
                          label: Text(_photo == null ? 'Ajouter une preuve photo' : 'Photo enregistrée'),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: IconButton.filled(onPressed: _pickPhoto, icon: const Icon(Icons.photo_camera_outlined)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const AssetImageBox(asset: AppAssets.iconTri, height: 40, width: 40, radius: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Poids ou volume estimé', style: TextStyle(fontWeight: FontWeight.w600)),
                            TextField(
                              controller: _weight,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(isDense: true, hintText: '25'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: false, label: Text('kg')),
                          ButtonSegment(value: true, label: Text('L')),
                        ],
                        selected: {_liters},
                        onSelectionChanged: (s) => setState(() => _liters = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Statut de validation', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Chip(
                              label: Text('En attente de validation', style: TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.paleOchre,
                              side: BorderSide.none,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Votre collecte sera vérifiée par l’équipe Éco-Responsable avant validation définitive. '
                              'Le citoyen recevra ses points immédiatement.',
                              style: TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Confirmer',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: () => _confirm(r),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.current});
  final int current;
  static const _labels = ['Preuve', 'Détails', 'Validation'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current ? AppColors.primaryGreen : AppColors.outline,
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Text(_labels[i], style: TextStyle(fontSize: 11, color: i <= current ? AppColors.textBlack : AppColors.textMuted)),
            ],
          ),
          if (i < _labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
                color: i < current ? AppColors.primaryGreen : AppColors.outline,
              ),
            ),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------------- historique

/// Historique des interventions (planche 6, écran 2).
class CollectorHistoryScreen extends ConsumerStatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  ConsumerState<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends ConsumerState<CollectorHistoryScreen> {
  String _filter = 'Toutes';

  bool _accept(CollectionRequest r) => switch (_filter) {
        'Validées' => r.status == RequestStatus.collected,
        'En cours' => r.status == RequestStatus.matched || r.status == RequestStatus.enRoute,
        'Rejetées' => r.status == RequestStatus.cancelled,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(collectorRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des interventions')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                for (final f in ['Toutes', 'Validées', 'En cours', 'Rejetées'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: mine.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                final items = list.where(_accept).toList();
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyCard(text: 'Aucune intervention dans cette catégorie.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshCollectorData(ref),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _HistoryCard(request: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.request});
  final CollectionRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final (label, bg, fg) = switch (r.status) {
      RequestStatus.collected => ('Validée', AppColors.paleGreen, AppColors.primaryGreen),
      RequestStatus.cancelled => ('Rejetée', const Color(0xFFFFEBEE), AppColors.danger),
      _ => ('En cours', AppColors.paleOchre, AppColors.earthOchre),
    };
    final date = r.collectedAt ?? r.scheduledAt ?? r.createdAt ?? DateTime.now();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/collector/stop/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AssetImageBox(asset: _wasteAsset(r.wasteType), height: 44, width: 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMM y · HH:mm', 'fr').format(date), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(r.address.isEmpty ? r.city : '${r.address}, ${r.city}', style: const TextStyle(fontSize: 12)),
                    Text(
                      '${r.weightKg != null ? '${r.weightKg} kg · ' : ''}${r.wasteType.labelFr}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.status == RequestStatus.cancelled ? '0 FCFA' : _fcfa(_feeFor(r)),
                    style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- revenus

/// Revenus générés (planche 6, écran 3).
class CollectorEarningsScreen extends ConsumerWidget {
  const CollectorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(collectorRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Revenus générés')),
      body: mine.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final done = list.where((r) => r.status == RequestStatus.collected).toList();
          final now = DateTime.now();
          int sumBetween(DateTime from, DateTime to) => done
              .where((r) => (r.collectedAt ?? r.scheduledAt ?? now).isAfter(from) && (r.collectedAt ?? r.scheduledAt ?? now).isBefore(to))
              .fold(0, (s, r) => s + _feeFor(r));
          final total = done.fold(0, (s, r) => s + _feeFor(r));
          final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          final thisWeek = sumBetween(startOfWeek, now.add(const Duration(days: 1)));
          final prevWeek = sumBetween(startOfWeek.subtract(const Duration(days: 7)), startOfWeek);
          final startOfMonth = DateTime(now.year, now.month);
          final prevMonth = sumBetween(DateTime(now.year, now.month - 1), startOfMonth);
          final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
          final daily = [for (final d in days) sumBetween(d, d.add(const Duration(days: 1)))];
          final maxY = (daily.fold(0, (m, v) => v > m ? v : m)).toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total des gains', style: TextStyle(color: AppColors.textDark)),
                          Text(_fcfa(total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                          Text('${done.length} collecte(s) validée(s) depuis le début',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                    const AssetImageBox(asset: AppAssets.leafDeco, height: 64, width: 64, radius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart, color: AppColors.primaryGreen, size: 18),
                        SizedBox(width: 6),
                        Expanded(child: Text('Évolution des gains', style: TextStyle(fontWeight: FontWeight.w700))),
                        Text('7 derniers jours', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          maxY: maxY == 0 ? 1000 : maxY * 1.2,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    DateFormat('d MMM', 'fr').format(days[v.toInt()]),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < 7; i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: daily[i].toDouble(),
                                  width: 18,
                                  color: i == 6 ? AppColors.primaryGreen : AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Détail par période', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _PeriodRow('Cette semaine', thisWeek, highlighted: true),
                    _PeriodRow('Semaine précédente', prevWeek),
                    _PeriodRow('Mois précédent', prevMonth),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.paleOchre, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        AssetImageBox(asset: AppAssets.mtnMomo, height: 36, width: 36, radius: 8),
                        SizedBox(width: 6),
                        AssetImageBox(asset: AppAssets.orangeMoney, height: 36, width: 36, radius: 8),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Retrait Mobile Money', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                'Transférez vos gains sur votre compte Mobile Money (MTN / Orange).',
                                style: TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.earthOchre),
                      onPressed: total <= 0 ? null : () => _requestPayout(context, ref, total),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Demander un retrait'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _requestPayout(BuildContext context, WidgetRef ref, int total) async {
    final user = ref.read(authProvider).user;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demander un retrait'),
        content: Text('Transférer ${_fcfa(total)} vers ${user?.phone.isNotEmpty == true ? user!.phone : 'votre numéro Mobile Money'} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (ok != true || user == null) return;
    await ref.read(notificationRepositoryProvider).create(
          AppNotification(
            id: '',
            userId: user.id,
            title: 'Demande de retrait enregistrée',
            body: '${_fcfa(total)} seront transférés sur votre compte Mobile Money sous 24 h ouvrées.',
            kind: 'info',
            createdAt: DateTime.now(),
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de retrait enregistrée. Traitement sous 24 h ouvrées.')),
      );
    }
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow(this.label, this.amount, {this.highlighted = false});
  final String label;
  final int amount;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.paleGreen : AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(_fcfa(amount), style: const TextStyle(fontWeight: FontWeight.w700)),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
