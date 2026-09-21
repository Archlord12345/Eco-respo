import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/reward_item.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final catalog = ref.watch(catalogProvider);
    final pts = user?.points ?? 2450;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Éco-Responsable'),
            Text('Ensemble pour un Cameroun plus propre', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(backgroundImage: AssetImage(AppAssets.avatarPlaceholder)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF43A047)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('Mon solde de points', style: TextStyle(color: Colors.white70)),
                Text('$pts pts', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const Text('Plus tu agis, plus tu gagnes !', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (pts % 3000) / 3000,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.earthOchre,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(height: 6),
                Text('Niveau actuel Éco-Citoyen ${user?.levelLabel ?? 'Argent'}  •  $pts / 3 000', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('Catalogue de récompenses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              TextButton(onPressed: () {}, child: const Text('Voir tout')),
            ],
          ),
          catalog.when(
            data: (items) {
              final enabled = items.where((item) => item.enabled).take(3).toList();
              return enabled.isEmpty
                  ? const Text('Aucune récompense disponible.')
                  : Row(
                      children: enabled.map((e) => Expanded(child: _item(context, ref, e, pts))).toList(),
                    );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text(
              'Catalogue indisponible : $error',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nos niveaux éco-citoyen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              RewardBadgeCard(title: 'Bronze', subtitle: '0 – 999 pts', asset: AppAssets.badgeBronze),
              RewardBadgeCard(title: 'Argent', subtitle: '1 000 – 2 999 pts', asset: AppAssets.badgeSilver, highlighted: true),
              RewardBadgeCard(title: 'Or', subtitle: '3 000+ pts', asset: AppAssets.badgeGold),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Échanger mes points',
            icon: Icons.card_giftcard,
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (i) {
          const paths = ['/home', '/report', '/rewards', '/profile'];
          context.go(paths[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.place_outlined), label: 'Signalement'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Récompenses'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, WidgetRef ref, RewardItem e, int pts) {
    final asset = switch (e.imageKey) {
      'reward_mtn' => AppAssets.rewardMtn,
      'reward_partner' => AppAssets.rewardPartner,
      _ => AppAssets.rewardVoucher,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            AssetImageBox(asset: asset, height: 64, width: double.infinity, radius: 8),
            Text(e.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text('À partir de ${e.pointsCost} pts', style: const TextStyle(fontSize: 10)),
            TextButton(
              onPressed: pts < e.pointsCost
                  ? null
                  : () async {
                      try {
                        await ref.read(rewardRepositoryProvider).redeem(
                              userId: ref.read(authProvider).user?.id ?? '',
                              itemId: e.id,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Échange enregistré.')),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Échange impossible : $error')),
                        );
                      }
                    },
              child: const Text('Échanger'),
            ),
          ],
        ),
      ),
    );
  }

}

final catalogProvider = FutureProvider<List<RewardItem>>((ref) {
  return ref.watch(rewardRepositoryProvider).catalog();
});
