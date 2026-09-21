import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/reward_item.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reporting/data/appwrite_report_repository.dart';

/// Flux temps réel des notifications de l'utilisateur connecté.
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchMine(userId);
});

final unreadCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(notificationsStreamProvider).whenData(
        (items) => items.where((n) => !n.read).length,
      );
});

enum NotificationFilter {
  all('Toutes', null),
  alerts('Alertes', {'alert', 'zone', 'map'}),
  collections('Collectes', {'collecte', 'collection', 'request', 'status'}),
  infos('Infos', {'info', 'points', 'campaign', 'reward'});

  const NotificationFilter(this.label, this.kinds);
  final String label;
  final Set<String>? kinds;

  bool accepts(AppNotification n) => kinds == null || kinds!.contains(n.kind);
}

/// Écran « Notifications » (planche 7, écran 3).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsStreamProvider);
    final userId = ref.watch(authProvider).user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Tout marquer comme lu',
            onPressed: userId == null
                ? null
                : () => ref.read(notificationRepositoryProvider).markAllRead(userId),
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Préférences',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: items.when(
        data: (list) {
          final counts = {
            for (final f in NotificationFilter.values) f: list.where(f.accepts).length,
          };
          final visible = list.where(_filter.accepts).toList();
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    for (final f in NotificationFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${f.label} (${counts[f]})'),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const _EmptyNotifications()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => NotificationCard(notification: visible[i]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Notifications indisponibles : $e', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          AssetImageBox(asset: AppAssets.notifCollecte, height: 96, width: 96),
          SizedBox(height: 12),
          Text('Aucune notification pour le moment.', style: TextStyle(color: AppColors.textDark)),
        ],
      ),
    );
  }
}

/// Carte de notification (icône par type, horodatage relatif, lien contextuel).
class NotificationCard extends ConsumerWidget {
  const NotificationCard({super.key, required this.notification, this.dense = false});

  final AppNotification notification;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    final (icon, color, asset) = switch (n.kind) {
      'alert' || 'zone' || 'map' => (Icons.warning_amber_rounded, AppColors.earthOchre, AppAssets.notifMap),
      'collecte' || 'collection' || 'request' => (Icons.local_shipping_outlined, AppColors.primaryGreen, AppAssets.notifCollecte),
      'status' => (Icons.check_circle_outline, AppColors.primaryGreen, AppAssets.notifCollecte),
      'points' || 'reward' => (Icons.star_outline, AppColors.earthOchre, AppAssets.notifPoints),
      'campaign' => (Icons.campaign_outlined, AppColors.earthOchre, AppAssets.notifMap),
      _ => (Icons.info_outline, AppColors.institutionalBlue, AppAssets.notifPoints),
    };
    final route = n.targetRoute;
    return Material(
      color: n.read ? Colors.white : AppColors.paleGreen,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!n.read) ref.read(notificationRepositoryProvider).markRead(n.id);
          if (route != null) context.push(route);
        },
        child: Padding(
          padding: EdgeInsets.all(dense ? 10 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dense
                  ? Icon(icon, color: color)
                  : AssetImageBox(asset: asset, height: 44, width: 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.read ? FontWeight.w600 : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(relativeTime(n.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                    if (route != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Voir le détail →',
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'à l’instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return DateFormat('dd MMM', 'fr').format(date);
}

/// Panneau latéral de notifications pour les écrans back-office.
Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.8,
      child: NotificationsScreen(),
    ),
  );
}
