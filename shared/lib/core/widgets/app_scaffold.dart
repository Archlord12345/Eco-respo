import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../shared/models/enums.dart';
import '../constants/app_assets.dart';
import '../theme/colors.dart';
import '../utils/responsive_helper.dart';
import 'reward_badge_card.dart';

/// Coque citoyenne : barre de navigation basse (mobile) ou rail (large).
class CitizenShell extends StatelessWidget {
  const CitizenShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (Icons.home_outlined, Icons.home, 'Accueil'),
    (Icons.campaign_outlined, Icons.campaign, 'Signaler'),
    (Icons.local_shipping_outlined, Icons.local_shipping, 'Collecte'),
    (Icons.map_outlined, Icons.map, 'Carte'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return _AdaptiveShell(
      navigationShell: navigationShell,
      destinations: _destinations,
      railExtras: const [
        _RailLink(icon: Icons.emoji_events_outlined, label: 'Récompenses', path: '/rewards'),
        _RailLink(icon: Icons.history, label: 'Historique', path: '/history'),
        _RailLink(icon: Icons.notifications_outlined, label: 'Notifications', path: '/notifications'),
      ],
    );
  }
}

/// Coque collecteur (planches 5 et 6).
class CollectorShell extends StatelessWidget {
  const CollectorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (Icons.home_outlined, Icons.home, 'Accueil'),
    (Icons.route_outlined, Icons.route, 'Tournée'),
    (Icons.history_outlined, Icons.history, 'Historique'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Revenus'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return _AdaptiveShell(navigationShell: navigationShell, destinations: _destinations);
  }
}

class _RailLink {
  const _RailLink({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;
}

class _AdaptiveShell extends StatelessWidget {
  const _AdaptiveShell({
    required this.navigationShell,
    required this.destinations,
    this.railExtras = const [],
  });

  final StatefulNavigationShell navigationShell;
  final List<(IconData, IconData, String)> destinations;
  final List<_RailLink> railExtras;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isCompact(context)) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
          ],
        ),
      );
    }
    final extended = MediaQuery.sizeOf(context).width > 1100;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppColors.primaryGreen),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
            ],
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const AssetImageBox(asset: AppAssets.logo, height: 48, width: 48, radius: 12),
                  if (extended) ...[
                    const SizedBox(height: 8),
                    const Text('Éco-Responsable', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
            trailing: railExtras.isEmpty
                ? null
                : Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final l in railExtras)
                              extended
                                  ? TextButton.icon(
                                      onPressed: () => context.push(l.path),
                                      icon: Icon(l.icon, size: 20),
                                      label: Text(l.label),
                                    )
                                  : IconButton(
                                      tooltip: l.label,
                                      onPressed: () => context.push(l.path),
                                      icon: Icon(l.icon),
                                    ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// Entrée de menu d'une barre latérale back-office.
class SidebarItem {
  const SidebarItem({required this.icon, required this.label, required this.path, this.exact = false});
  final IconData icon;
  final String label;
  final String path;

  /// `true` pour la racine (`/admin`) afin de ne pas matcher tous les sous-chemins.
  final bool exact;

  bool matches(String loc) => exact ? loc == path : loc.startsWith(path);
}

/// Coque back-office municipal (planche 4).
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const items = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', path: '/admin', exact: true),
    SidebarItem(icon: Icons.campaign_outlined, label: 'Signalements', path: '/admin/reports'),
    SidebarItem(icon: Icons.map_outlined, label: 'Zones et opérateurs', path: '/admin/zones'),
    SidebarItem(icon: Icons.description_outlined, label: 'Rapports et communication', path: '/admin/reports-comm'),
    SidebarItem(icon: Icons.settings_outlined, label: 'Paramètres', path: '/admin/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return BackOfficeShell(
      items: items,
      subtitle: 'Gestion des déchets · Commune',
      footerAsset: AppAssets.iconCity,
      footerText: 'Une ville plus propre,\nun avenir durable.',
      switchLabel: 'Espace entreprise',
      switchPath: '/company',
      child: child,
    );
  }
}

/// Coque back-office « entreprise de collecte » (desktop).
class CompanyShell extends StatelessWidget {
  const CompanyShell({super.key, required this.child});
  final Widget child;

  static const items = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', path: '/company', exact: true),
    SidebarItem(icon: Icons.alt_route_outlined, label: 'Dispatch des demandes', path: '/company/dispatch'),
    SidebarItem(icon: Icons.local_shipping_outlined, label: 'Flotte et collecteurs', path: '/company/fleet'),
    SidebarItem(icon: Icons.payments_outlined, label: 'Revenus', path: '/company/revenue'),
    SidebarItem(icon: Icons.settings_outlined, label: 'Paramètres', path: '/company/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return BackOfficeShell(
      items: items,
      subtitle: 'Entreprise de collecte',
      footerAsset: AppAssets.collectorTruck,
      footerText: 'Ensemble pour un Cameroun\nplus propre.',
      switchLabel: 'Espace municipal',
      switchPath: '/admin',
      switchAdminOnly: true,
      child: child,
    );
  }
}

/// Barre latérale sombre + zone de contenu, commune aux deux back-offices.
class BackOfficeShell extends ConsumerWidget {
  const BackOfficeShell({
    super.key,
    required this.items,
    required this.subtitle,
    required this.footerAsset,
    required this.footerText,
    required this.child,
    this.switchLabel,
    this.switchPath,
    this.switchAdminOnly = false,
  });

  final List<SidebarItem> items;
  final String subtitle;
  final String footerAsset;
  final String footerText;
  final Widget child;
  final String? switchLabel;
  final String? switchPath;
  final bool switchAdminOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.path;
    final user = ref.watch(authProvider).user;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final canSwitch = switchPath != null &&
        (!switchAdminOnly || user?.role.name == 'admin');

    final sidebar = Container(
      width: compact ? 72 : 250,
      color: AppColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const AssetImageBox(asset: AppAssets.logoWhite, height: 36, width: 36, radius: 8),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Éco-Responsable',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (final item in items)
            _SidebarTile(item: item, selected: item.matches(loc), compact: compact),
          const Spacer(),
          if (canSwitch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: compact
                  ? IconButton(
                      tooltip: switchLabel,
                      onPressed: () => context.go(switchPath!),
                      icon: const Icon(Icons.swap_horiz, color: Colors.white70),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      onPressed: () => context.go(switchPath!),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(switchLabel!, style: const TextStyle(fontSize: 12)),
                    ),
            ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AssetImageBox(asset: footerAsset, height: 72, width: 72, radius: 36),
                  const SizedBox(height: 8),
                  Text(
                    footerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          sidebar,
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.selected, required this.compact});
  final SidebarItem item;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IconButton(
          tooltip: item.label,
          isSelected: selected,
          style: IconButton.styleFrom(
            backgroundColor: selected ? AppColors.sidebarSelected : Colors.transparent,
          ),
          onPressed: () => context.go(item.path),
          icon: Icon(item.icon, color: Colors.white),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.sidebarSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(item.icon, color: Colors.white),
        title: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        onTap: () => context.go(item.path),
      ),
    );
  }
}

/// En-tête blanc des écrans back-office : titre, sous-titre, organisation,
/// cloche de notifications et utilisateur connecté.
class BackOfficeHeader extends ConsumerWidget {
  const BackOfficeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.organisation,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final String? organisation;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                Text(subtitle, style: const TextStyle(color: AppColors.textDark, fontSize: 12)),
              ],
            ),
          ),
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: 16),
          if (organisation != null) ...[
            const AssetImageBox(asset: AppAssets.cameroonFlag, height: 20, width: 28, radius: 3),
            const SizedBox(width: 8),
            Text(organisation!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 16),
          ],
          Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => showNotificationsSheet(context),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.paleGreen,
            child: Text(
              (user?.name.isNotEmpty ?? false) ? user!.name.characters.first.toUpperCase() : 'A',
              style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(user?.role.labelFr ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
