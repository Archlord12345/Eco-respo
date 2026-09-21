import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app/app_target.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/enums.dart';
import 'auth_controller.dart';

/// Affiché quand le profil connecté n'a pas d'espace sur cette cible
/// (ex. un citoyen sur l'application desktop réservée aux organisations).
class RestrictedScreen extends ConsumerWidget {
  const RestrictedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final target = ref.watch(appTargetProvider);
    final canChangeRole = user != null && target == AppTarget.desktop;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AssetImageBox(asset: AppAssets.logo, height: 96, width: 96, radius: 24),
                const SizedBox(height: 24),
                Text(
                  'Espace ${target.label} réservé aux organisations',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Le profil « ${user?.role.labelFr ?? 'Citoyen'} » utilise l’application mobile. '
                  'Cette application desktop est destinée aux municipalités et aux entreprises de collecte.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDark),
                ),
                const SizedBox(height: 28),
                if (canChangeRole) ...[
                  PrimaryButton(
                    label: 'Je gère une entreprise de collecte',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () async {
                      await ref.read(authProvider.notifier).saveProfile(user.copyWith(role: UserRole.operator));
                      if (context.mounted) context.go('/company');
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).saveProfile(user.copyWith(role: UserRole.admin));
                      if (context.mounted) context.go('/admin');
                    },
                    icon: const Icon(Icons.account_balance_outlined),
                    label: const Text('Je représente la municipalité'),
                  ),
                  const SizedBox(height: 10),
                ],
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/welcome');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
