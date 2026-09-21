import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/enums.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../collector/presentation/collector_screens.dart' show collectorRequestsProvider, myCollectorProvider;
import '../../settings/presentation/settings_screen.dart';
import 'history_screen.dart';

/// Profil (planche 3) — s'adapte au rôle : KPIs citoyen ou collecteur.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isCollector = user?.role == UserRole.collector;
    final impact = ref.watch(myImpactProvider(user?.id)).value;
    final collector = isCollector ? ref.watch(myCollectorProvider).value : null;
    final interventions = isCollector ? ref.watch(collectorRequestsProvider).value : null;
    final badges = user == null ? 0 : (user.points >= 3000 ? 3 : user.points >= 1000 ? 2 : user.points > 0 ? 1 : 0);

    return Scaffold(
      body: ListView(
        children: [
          Container(
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 36, backgroundImage: AppAssets.image(AppAssets.avatarPlaceholder)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name.isNotEmpty == true ? user!.name : 'Citoyen',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            isCollector
                                ? 'Collecteur${collector?.company.isNotEmpty == true ? ' · ${collector!.company}' : ''}'
                                : (user?.role == UserRole.citizen ? 'Éco-citoyen(ne) engagé(e)' : user?.role.labelFr ?? ''),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('Niveau ${user?.levelLabel ?? 'Bronze'}', style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    if (isCollector)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          collector?.isAvailable == true ? 'En ligne' : 'Hors ligne',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: isCollector
                      ? [
                          _kpi('${collector?.interventionsCount ?? 0}', 'Interventions', Icons.task_alt),
                          _kpi('${interventions?.where((r) => r.status.isOpen).length ?? 0}', 'En cours', Icons.route),
                          _kpi('${collector?.coveredZones.length ?? 0}', 'Zones', Icons.map_outlined),
                          _kpi('${user?.points ?? 0}', 'Points', Icons.eco),
                        ]
                      : [
                          _kpi('${user?.points ?? 0}', 'Points', Icons.eco),
                          _kpi('${impact?.reports ?? 0}', 'Signalements', Icons.campaign_outlined),
                          _kpi('${impact?.collections ?? 0}', 'Collectes', Icons.local_shipping_outlined),
                          _kpi('$badges', 'Badges', Icons.emoji_events),
                        ],
                ),
              ],
            ),
          ),
          if (!isCollector)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: RewardBadgeCard(
                      title: 'Bronze',
                      subtitle: 'Premier geste',
                      asset: AppAssets.badgeBronze,
                      highlighted: badges >= 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RewardBadgeCard(
                      title: 'Argent',
                      subtitle: '1 000 points',
                      asset: AppAssets.badgeSilver,
                      highlighted: badges >= 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RewardBadgeCard(
                      title: 'Or',
                      subtitle: '3 000 points',
                      asset: AppAssets.badgeGold,
                      highlighted: badges >= 3,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informations personnelles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                _row(Icons.person_outline, 'Nom complet', user?.name ?? '—'),
                _row(Icons.phone_outlined, 'Téléphone', user?.phone.isNotEmpty == true ? user!.phone : 'Non renseigné'),
                _row(
                  Icons.place_outlined,
                  'Localisation',
                  [user?.district ?? '', user?.city ?? ''].where((e) => e.isNotEmpty).join(', '),
                ),
                _row(Icons.mail_outline, 'Email', user?.email.isNotEmpty == true ? user!.email : 'Non renseigné'),
                const Divider(height: 24),
                if (!isCollector) ...[
                  ListTile(
                    leading: const Icon(Icons.emoji_events_outlined, color: AppColors.earthOchre),
                    title: const Text('Récompenses'),
                    subtitle: const Text('Échanger mes points'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/rewards'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Historique'),
                    subtitle: const Text('Mes signalements et collectes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history'),
                  ),
                ] else
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Historique des interventions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/collector/history'),
                  ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: Text(user?.notificationsEnabled == false ? 'Désactivées' : 'Alertes, collectes et infos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Langue'),
                  trailing: Text(user?.language == 'en' ? 'English' : 'Français'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Confidentialité'),
                  subtitle: const Text('Vos données restent hébergées sur Appwrite Cloud (région Francfort).'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/welcome');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String v, String l, IconData i) {
    return Column(
      children: [
        Icon(i, color: Colors.white),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _row(IconData i, String l, String v) {
    return ListTile(
      leading: Icon(i, color: AppColors.primaryGreen),
      title: Text(l, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
      subtitle: Text(v.isEmpty ? '—' : v, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textBlack)),
    );
  }
}
