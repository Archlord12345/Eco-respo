import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/eco_app_bar.dart';
import '../../../core/widgets/impact_gauge.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = (user?.name.isNotEmpty ?? false) ? user!.name.split(' ').first : 'Citoyen';
    final impact = ref.watch(myImpactProvider(user?.id)).value;
    final kg = impact?.kg ?? 0;
    const monthlyGoalKg = 16.0;
    return Scaffold(
      appBar: EcoAppBar(subtitle: null, city: user?.city ?? AppConstants.defaultCity),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myImpactProvider(user?.id));
          await ref.read(authProvider.notifier).restore();
        },
        child: ListView(
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
                const Text('Votre impact', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat(Icons.star, '${user?.points ?? 0}', 'points', 'Récompenses citoyennes', const Color(0xFFFFF8E1)),
                    _stat(Icons.inventory_2, _kg(kg), 'collectés', 'Déchets valorisés', const Color(0xFFE8F5E9)),
                    _stat(Icons.co2, _kg(impact?.co2Kg ?? 0), 'CO₂ évité', 'Pour un air plus pur', const Color(0xFFFFF3E0)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ImpactGauge(percent: (kg / monthlyGoalKg).clamp(0, 1), label: 'de votre objectif mensuel'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Objectif mensuel ${monthlyGoalKg.toInt()} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (kg / monthlyGoalKg).clamp(0, 1),
                            minHeight: 10,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kg == 0 ? 'Demandez votre première collecte pour démarrer.' : 'Collecté : ${_kg(kg)}',
                            style: const TextStyle(fontSize: 12),
                          ),
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
          SectionTitle('Notifications récentes', action: 'Voir tout', onAction: () => context.push('/notifications')),
          ref.watch(notificationsStreamProvider).when(
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aucune notification récente.'),
                  )
                : Column(
                    children: [
                      for (final n in items.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NotificationCard(notification: n),
                        ),
                    ],
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
          const SizedBox(height: 16),
          SectionTitle('Récompenses', action: 'Échanger', onAction: () => context.push('/rewards')),
          Row(
            children: [
              Expanded(child: RewardBadgeCard(title: 'Bronze', subtitle: 'Premier geste', asset: AppAssets.badgeBronze, highlighted: (user?.points ?? 0) > 0)),
              const SizedBox(width: 8),
              Expanded(child: RewardBadgeCard(title: 'Argent', subtitle: '1 000 pts', asset: AppAssets.badgeSilver, highlighted: (user?.points ?? 0) >= 1000)),
              const SizedBox(width: 8),
              Expanded(child: RewardBadgeCard(title: 'Or', subtitle: '3 000 pts', asset: AppAssets.badgeGold, highlighted: (user?.points ?? 0) >= 3000)),
            ],
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  String _kg(double v) => v >= 10 ? '${v.toStringAsFixed(0)} kg' : '${v.toStringAsFixed(1).replaceAll('.', ',')} kg';

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

}

