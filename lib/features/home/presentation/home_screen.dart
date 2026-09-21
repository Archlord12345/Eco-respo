import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/appwrite/appwrite_client.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/eco_app_bar.dart';
import '../../../core/widgets/impact_gauge.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../shared/models/reward_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name.split(' ').first ?? 'Moussa';
    return Scaffold(
      appBar: EcoAppBar(subtitle: null, city: user?.city ?? 'Yaoundé'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, $name !', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const Text('Merci pour votre engagement !', style: TextStyle(color: AppColors.primaryGreen)),
                  ],
                ),
              ),
              const AssetImageBox(
                asset: AppAssets.leafDeco,
                height: 56,
                width: 72,
                fit: BoxFit.cover,
                alignment: Alignment.bottomRight,
                radius: 12,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Votre impact cette semaine', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat(Icons.star, '${user?.points ?? 320}', 'points', 'Récompenses citoyennes', const Color(0xFFFFF8E1)),
                    _stat(Icons.inventory_2, '12,5 kg', 'triés', 'Déchets valorisés', const Color(0xFFE8F5E9)),
                    _stat(Icons.co2, '8,7 kg', 'CO₂ évité', 'Pour un air plus pur', const Color(0xFFFFF3E0)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const ImpactGauge(percent: 0.78, label: 'de votre objectif mensuel'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Objectif mensuel 16 kg', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          LinearProgressIndicator(value: 12.5 / 16, minHeight: 10, borderRadius: BorderRadius.all(Radius.circular(8))),
                          SizedBox(height: 4),
                          Text('Trié ce mois-ci 12,5 kg', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _action(context, AppColors.primaryGreen, Icons.campaign, 'Signaler un dépôt sauvage', '/report')),
              const SizedBox(width: 8),
              Expanded(child: _action(context, AppColors.earthOchre, Icons.local_shipping, 'Demander une collecte', '/collect')),
              const SizedBox(width: 8),
              Expanded(child: _action(context, const Color(0xFFC8E6C9), Icons.map, 'Carte des points de collecte', '/map', dark: true)),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle('Notifications récentes', action: 'Voir tout', onAction: () => context.push('/history')),
          ref.watch(notificationsProvider).when(
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aucune notification récente.'),
                  )
                : Column(
                    children: items.take(3).map(_notification).toList(),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              'Notifications indisponibles : $error',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String unit, String caption, Color bg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.earthOchre),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(unit, style: const TextStyle(fontSize: 11)),
            Text(caption, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, Color color, IconData icon, String label, String path, {bool dark = false}) {
    return InkWell(
      onTap: () => context.go(path),
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: dark ? AppColors.primaryGreen : Colors.white),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: dark ? AppColors.textBlack : Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _notification(AppNotification notification) {
    final asset = switch (notification.kind) {
      'collecte' => AppAssets.notifCollecte,
      'points' => AppAssets.notifPoints,
      'map' => AppAssets.notifMap,
      _ => AppAssets.notifCollecte,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AssetImageBox(asset: asset, height: 40, width: 40, radius: 10),
      title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(notification.body, style: const TextStyle(fontSize: 11)),
    );
  }
}

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return const [];
  final response = await ref.watch(tablesProvider).listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.notificationsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(10),
        ],
      );
  return response.rows
      .map((row) => AppNotification.fromMap(row.data, id: row.$id))
      .toList();
});
