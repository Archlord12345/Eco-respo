import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
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
                    const CircleAvatar(radius: 36, backgroundImage: AssetImage(AppAssets.avatarSandrine)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name.isNotEmpty == true ? user!.name : 'Tchoua M. Sandrine',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          const Text('Éco-citoyenne engagée', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text('Niveau ${user?.levelLabel ?? 'Argent'}', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _kpi('${user?.points ?? 2450}', 'Points', Icons.eco),
                    _kpi('12', 'Signalements', Icons.recycling),
                    _kpi('8', 'Collectes', Icons.delete_outline),
                    _kpi('3', 'Badges', Icons.emoji_events),
                  ],
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
                _row(Icons.person_outline, 'Nom complet', user?.name ?? 'Tchoua M. Sandrine'),
                _row(Icons.phone_outlined, 'Téléphone', user?.phone.isNotEmpty == true ? user!.phone : '+237 6 75 32 18 90'),
                _row(Icons.place_outlined, 'Localisation', '${user?.city ?? 'Yaoundé'}, ${user?.district ?? 'Centre'}'),
                _row(Icons.mail_outline, 'Email', user?.email.isNotEmpty == true ? user!.email : 'sandrine.tchoua@gmail.com'),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historique'),
                  subtitle: const Text('Mes signalements et collectes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/history'),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Langue'),
                  subtitle: const Text('Français / English'),
                  trailing: Text(user?.language == 'en' ? 'English' : 'Français'),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Alertes et rappels'),
                  value: user?.notificationsEnabled ?? true,
                  onChanged: (v) {
                    if (user != null) {
                      ref.read(authProvider.notifier).saveProfile(user.copyWith(notificationsEnabled: v));
                    }
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Confidentialité'),
                  subtitle: Text('Données et sécurité'),
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
      subtitle: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textBlack)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
