import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/city_select_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/collection_request/presentation/collection_request_screen.dart';
import '../../features/collector/presentation/collector_screens.dart';
import '../../features/dashboard_admin/presentation/admin_screens.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reporting/presentation/report_screen.dart';
import '../../features/rewards/presentation/rewards_screen.dart';
import '../../shared/models/enums.dart';
import '../widgets/app_scaffold.dart';
import 'route_names.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.loading) return null;
      final loc = state.matchedLocation;
      final logged = auth.user != null;
      const public = ['/welcome', '/login'];
      if (!logged && !public.contains(loc)) return '/welcome';
      if (logged && public.contains(loc)) {
        return switch (auth.user!.role) {
          UserRole.admin => '/admin',
          UserRole.collector => '/collector',
          UserRole.citizen => '/home',
        };
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/city',
        name: RouteNames.city,
        builder: (_, _) => const CitySelectScreen(),
      ),
      GoRoute(
        path: '/rewards',
        name: RouteNames.rewards,
        builder: (_, _) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: RouteNames.history,
        builder: (_, _) => const HistoryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => CitizenShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', name: RouteNames.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/report', name: RouteNames.report, builder: (_, _) => const ReportScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/collect', name: RouteNames.collect, builder: (_, _) => const CollectionRequestScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', name: RouteNames.map, builder: (_, _) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', name: RouteNames.profile, builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/collector',
        name: RouteNames.collector,
        builder: (_, _) => const CollectorHomeScreen(),
        routes: [
          GoRoute(path: 'tour', builder: (_, _) => const CollectorTourScreen()),
          GoRoute(path: 'confirm', builder: (_, _) => const CollectorConfirmScreen()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', name: RouteNames.admin, builder: (_, _) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/reports', builder: (_, _) => const AdminReportsScreen()),
          GoRoute(path: '/admin/zones', builder: (_, _) => const AdminZonesScreen()),
          GoRoute(path: '/admin/reports-comm', builder: (_, _) => const AdminReportsCommScreen()),
          GoRoute(path: '/admin/settings', builder: (_, _) => const AdminSettingsScreen()),
        ],
      ),
    ],
  );
});
