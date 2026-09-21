import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../theme/colors.dart';
import '../utils/responsive_helper.dart';
import 'reward_badge_card.dart';

class CitizenShell extends StatelessWidget {
  const CitizenShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.isCompact(context);
    if (compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.place_outlined), selectedIcon: Icon(Icons.place), label: 'Signaler'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Collecte'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Carte'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width > 1100,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppColors.primaryGreen),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Accueil')),
              NavigationRailDestination(icon: Icon(Icons.place_outlined), label: Text('Signaler')),
              NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), label: Text('Collecte')),
              NavigationRailDestination(icon: Icon(Icons.map_outlined), label: Text('Carte')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profil')),
            ],
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: AssetImageBox(asset: AppAssets.logo, height: 48, width: 48, radius: 12),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/admin/reports')) return 1;
    if (loc.startsWith('/admin/zones')) return 2;
    if (loc.startsWith('/admin/reports-comm')) return 3;
    if (loc.startsWith('/admin/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: AppColors.sidebar,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AssetImageBox(asset: AppAssets.logoWhite, height: 36, width: 36, radius: 8),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Éco-Responsable',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _tile(context, 0, idx, Icons.dashboard_outlined, 'Tableau de bord', '/admin'),
                _tile(context, 1, idx, Icons.campaign_outlined, 'Signalements', '/admin/reports'),
                _tile(context, 2, idx, Icons.map_outlined, 'Zones et opérateurs', '/admin/zones'),
                _tile(context, 3, idx, Icons.description_outlined, 'Rapports et communication', '/admin/reports-comm'),
                _tile(context, 4, idx, Icons.settings_outlined, 'Paramètres', '/admin/settings'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const AssetImageBox(asset: AppAssets.iconCity, height: 72, width: 72, radius: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Une ville plus propre,\nun avenir durable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    int i,
    int selected,
    IconData icon,
    String label,
    String path,
  ) {
    final on = i == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: on,
        selectedTileColor: AppColors.sidebarSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        onTap: () => context.go(path),
      ),
    );
  }
}
