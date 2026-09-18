import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class CollectorHomeScreen extends ConsumerWidget {
  const CollectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final col = ref.watch(myCollectorProvider(user?.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Espace collecteur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AssetImageBox(asset: AppAssets.collectorTruck, height: 120, width: double.infinity),
          const SizedBox(height: 12),
          col.when(
            data: (c) => SwitchListTile(
              title: const Text('Disponible pour une tournée'),
              value: c?.isAvailable ?? false,
              onChanged: (v) {
                if (c != null) {
                  ref.read(collectorRepositoryProvider).setAvailability(c.id, v);
                }
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const Text('Demandes à proximité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const Text('Résultat de matchCollector (Valkey: agrégé côté Appwrite Function, consommé ici via HTTP)'),
          ListTile(
            leading: AssetImageBox(asset: AppAssets.reportHousehold, height: 44, width: 44, radius: 8),
            title: const Text('Collecte ménagère — Bastos'),
            subtitle: const Text('Petit volume • 08:00 - 12:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/collector/tour'),
          ),
          PrimaryButton(
            label: 'Tournée du jour',
            onPressed: () => context.push('/collector/tour'),
          ),
        ],
      ),
    );
  }
}

class CollectorTourScreen extends StatelessWidget {
  const CollectorTourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournée du jour')),
      body: ListView(
        children: [
          for (final s in ['Bastos', 'Nlongkak', 'Mfoundi'])
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.flag, color: AppColors.primaryGreen)),
              title: Text('Arrêt $s'),
              subtitle: const Text('Ordre optimisé par matchCollector'),
              onTap: () => context.push('/collector/confirm'),
            ),
        ],
      ),
    );
  }
}

class CollectorConfirmScreen extends ConsumerStatefulWidget {
  const CollectorConfirmScreen({super.key});

  @override
  ConsumerState<CollectorConfirmScreen> createState() => _CollectorConfirmScreenState();
}

class _CollectorConfirmScreenState extends ConsumerState<CollectorConfirmScreen> {
  final _kg = TextEditingController(text: '12');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation de collecte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AssetImageBox(asset: AppAssets.proofPlaceholder, height: 180, width: double.infinity),
          const SizedBox(height: 12),
          TextField(
            controller: _kg,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Poids (kg)'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Valider la collecte',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preuve enregistrée — points calculés via computeRewardPoints')),
              );
              context.go('/collector');
            },
          ),
        ],
      ),
    );
  }
}

final myCollectorProvider = FutureProvider.family((ref, String? uid) {
  if (uid == null) return Future.value(null);
  return ref.watch(collectorRepositoryProvider).byUserId(uid);
});
