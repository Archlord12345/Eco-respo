import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/mini_map.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/enums.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../collector/data/collector_actions.dart';
import '../../reporting/data/appwrite_report_repository.dart';
import '../../reporting/presentation/report_detail_screen.dart';

/// Suivi temps réel d'une demande (Realtime Appwrite sur la ligne).
final requestStreamProvider = StreamProvider.family<CollectionRequest, String>((ref, id) {
  return ref.watch(requestRepositoryProvider).watchOne(id);
});

/// « Ma demande de collecte » (planche 7, écran 2) : collecteur assigné, ETA,
/// statut en temps réel, détails et paiement Mobile Money.
class RequestTrackingScreen extends ConsumerWidget {
  const RequestTrackingScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(requestStreamProvider(requestId));
    final me = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma demande de collecte'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: AssetImageBox(asset: AppAssets.leafDeco, height: 28, width: 28, radius: 6),
          ),
        ],
      ),
      body: request.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Demande introuvable : $e')),
        data: (r) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderBanner(request: r),
                const SizedBox(height: 16),
                const _Label(icon: Icons.person_outline, text: 'Collecteur assigné'),
                const SizedBox(height: 8),
                if (r.assignedCollectorId == null)
                  const _Card(
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.earthOchre),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Recherche d’un collecteur disponible dans votre zone…'),
                        ),
                      ],
                    ),
                  )
                else
                  ref.watch(collectorByIdProvider(r.assignedCollectorId!)).when(
                        data: (c) => _Card(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.paleGreen,
                                child: Icon(Icons.local_shipping, color: AppColors.primaryGreen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c?.displayName.isNotEmpty == true ? c!.displayName : 'Collecteur',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      c?.company.isNotEmpty == true ? c!.company : 'Éco-Responsable',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: AppColors.earthOchre),
                                        Text(
                                          ' ${c?.interventionsCount ?? 0} intervention(s)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (c != null && c.phone.isNotEmpty)
                                Column(
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: () => launchUrl(Uri.parse('tel:${c.phone}')),
                                      icon: const Icon(Icons.call_outlined, size: 20),
                                    ),
                                    Text(c.phone, style: const TextStyle(fontSize: 10)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const _Card(child: Text('Collecteur assigné')),
                      ),
                const SizedBox(height: 16),
                _Card(
                  color: AppColors.paleGreen,
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 40, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ETA (heure d’arrivée estimée)',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text(_eta(r), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(_etaHint(r), style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _Label(icon: Icons.track_changes, text: 'Statut en temps réel'),
                const SizedBox(height: 8),
                _Card(child: _StatusStepper(request: r)),
                const SizedBox(height: 16),
                if (r.hasPosition)
                  MiniMap(
                    pins: [MapPin(LatLng(r.lat!, r.lng!))],
                    zoom: 15,
                    height: 150,
                    interactive: false,
                  ),
                const SizedBox(height: 16),
                const _Label(icon: Icons.info_outline, text: 'Détails de la collecte'),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    children: [
                      _Detail(icon: Icons.delete_outline, label: 'Type de déchets', value: r.wasteType.labelFr),
                      _Detail(icon: Icons.inventory_2_outlined, label: 'Estimation du volume', value: r.estimatedVolume.labelFr),
                      _Detail(icon: Icons.place_outlined, label: 'Adresse', value: r.address.isEmpty ? r.city : r.address),
                      if (r.timeSlot.isNotEmpty) _Detail(icon: Icons.access_time, label: 'Créneau', value: r.timeSlot),
                      if (r.notes.isNotEmpty) _Detail(icon: Icons.notes, label: 'Commentaires', value: r.notes),
                      if (r.weightKg != null)
                        _Detail(icon: Icons.scale_outlined, label: 'Poids collecté', value: '${r.weightKg} kg'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _Label(icon: Icons.account_balance_wallet_outlined, text: 'Paiement Mobile Money'),
                const SizedBox(height: 8),
                _Card(
                  color: AppColors.paleOchre,
                  child: Row(
                    children: [
                      AssetImageBox(
                        asset: r.paymentProvider == 'orange' ? AppAssets.orangeMoney : AppAssets.mtnMomo,
                        height: 40,
                        width: 40,
                        radius: 10,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${NumberFormat.decimalPattern('fr').format(r.amountPaid)} FCFA',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(
                              r.paymentProvider == 'orange' ? 'Orange Money' : 'MTN Mobile Money',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(r.status == RequestStatus.collected ? 'Payé' : 'Paiement à la livraison'),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                if (r.status.isOpen && me?.id == r.authorId) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () => _cancel(context, ref, r),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler la demande'),
                  ),
                ],
                if (r.status == RequestStatus.collected) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/rewards'),
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Voir mes points et récompenses'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _eta(CollectionRequest r) {
    if (r.status == RequestStatus.collected && r.collectedAt != null) {
      return 'Collectée le ${DateFormat('dd MMM à HH:mm', 'fr').format(r.collectedAt!)}';
    }
    if (r.status == RequestStatus.cancelled) return 'Demande annulée';
    final at = r.scheduledAt;
    if (at == null) return r.timeSlot.isEmpty ? 'À planifier' : r.timeSlot;
    final now = DateTime.now();
    final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
    final day = sameDay ? 'Aujourd’hui' : DateFormat('EEEE d MMM', 'fr').format(at);
    return '$day · ${DateFormat('HH:mm').format(at)}';
  }

  String _etaHint(CollectionRequest r) {
    final at = r.scheduledAt;
    if (at == null || !r.status.isOpen) return r.status.labelFr;
    final diff = at.difference(DateTime.now());
    if (diff.isNegative) return 'Créneau en cours';
    if (diff.inMinutes < 60) return 'Soit dans ${diff.inMinutes} min';
    if (diff.inHours < 48) return 'Soit dans ${diff.inHours} h ${diff.inMinutes % 60} min';
    return 'Soit dans ${diff.inDays} jour(s)';
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, CollectionRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Le collecteur sera prévenu. Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Garder')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Annuler la demande')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(collectorActionsProvider).cancel(r, reason: 'Vous avez annulé votre demande de collecte.');
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.request});
  final CollectionRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const AssetImageBox(asset: AppAssets.collectorTruck, height: 56, width: 56, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Collecte des déchets',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  'Ensemble pour des villes plus propres · ${request.status.labelFr}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const AssetImageBox(asset: AppAssets.logoWhite, height: 32, width: 32, radius: 8),
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.request});
  final CollectionRequest request;

  static const _steps = ['Assigné', 'En route', 'Sur site', 'Collecte\nterminée'];

  @override
  Widget build(BuildContext context) {
    final current = request.status.step;
    if (request.status == RequestStatus.cancelled) {
      return const Row(
        children: [
          Icon(Icons.cancel, color: AppColors.danger),
          SizedBox(width: 8),
          Text('Demande annulée', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }
    if (request.status == RequestStatus.pending) {
      return const Row(
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Expanded(child: Text('En attente d’un collecteur. Vous serez notifié dès l’affectation.')),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Icon(
                  i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: i <= current ? AppColors.primaryGreen : AppColors.outline,
                ),
                const SizedBox(height: 4),
                Text(
                  _steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                    color: i <= current ? AppColors.textBlack : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (i < _steps.length - 1)
            Container(
              width: 24,
              height: 2,
              margin: const EdgeInsets.only(bottom: 22),
              color: i < current ? AppColors.primaryGreen : AppColors.outline,
            ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
