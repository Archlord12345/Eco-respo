import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/city_select_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_phone_screen.dart';
import '../../features/auth/presentation/restricted_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/collection_request/presentation/collection_request_screen.dart';
import '../../features/collection_request/presentation/request_tracking_screen.dart';
import '../../features/collector/presentation/collector_screens.dart';
import '../../features/company/presentation/company_screens.dart';
import '../../features/dashboard_admin/presentation/admin_screens.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reporting/presentation/report_detail_screen.dart';
import '../../features/reporting/presentation/report_screen.dart';
import '../../features/rewards/presentation/rewards_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../app/app_target.dart';
import '../widgets/app_scaffold.dart';
import 'route_names.dart';

CustomTransitionPage<void> _animatedPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

const _publicRoutes = ['/welcome', '/login', '/register'];

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  final target = ref.watch(appTargetProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.loading) return null;
      final loc = state.matchedLocation;
      final user = auth.user;
      final isPublic = _publicRoutes.any((p) => loc == p || loc.startsWith('$p/'));

      if (user == null) return isPublic ? null : '/welcome';
      if (isPublic) return target.homeFor(user.role);

      // Espaces absents de cette cible → page d'entrée du profil.
      if (!target.hasBackOffice && (loc.startsWith('/admin') || loc.startsWith('/company'))) {
        return target.homeFor(user.role);
      }
      if (!target.hasCollectorSpace && loc.startsWith('/collector')) {
        return target.homeFor(user.role);
      }
      if (!target.hasCitizenSpace && _isCitizenRoute(loc)) {
        return target.homeFor(user.role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        pageBuilder: (_, state) => _animatedPage(state: state, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        pageBuilder: (_, state) => _animatedPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        pageBuilder: (_, state) => _animatedPage(
          state: state,
          child: RegisterPhoneScreen(login: state.uri.queryParameters['login'] == '1'),
        ),
      ),
      GoRoute(
        path: '/city',
        name: RouteNames.city,
        pageBuilder: (_, state) => _animatedPage(state: state, child: const CitySelectScreen()),
      ),
      GoRoute(
        path: '/restricted',
        name: RouteNames.restricted,
        pageBuilder: (_, state) => _animatedPage(state: state, child: const RestrictedScreen()),
      ),

      // ------------------------------------------------------------ Citoyen
      if (target.hasCitizenSpace) ...[
        GoRoute(
          path: '/rewards',
          name: RouteNames.rewards,
          pageBuilder: (_, state) => _animatedPage(state: state, child: const RewardsScreen()),
        ),
        GoRoute(
          path: '/history',
          name: RouteNames.history,
          pageBuilder: (_, state) => _animatedPage(state: state, child: const HistoryScreen()),
        ),
        GoRoute(
          path: '/notifications',
          name: RouteNames.notifications,
          pageBuilder: (_, state) => _animatedPage(state: state, child: const NotificationsScreen()),
        ),
        GoRoute(
          path: '/report/:id',
          name: RouteNames.reportDetail,
          pageBuilder: (_, state) => _animatedPage(
            state: state,
            child: ReportDetailScreen(reportId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/collect/:id',
          name: RouteNames.collectDetail,
          pageBuilder: (_, state) => _animatedPage(
            state: state,
            child: RequestTrackingScreen(requestId: state.pathParameters['id']!),
          ),
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
      ],

      // --------------------------------------------------------- Collecteur
      if (target.hasCollectorSpace) ...[
        GoRoute(
          path: '/collector/stop/:id',
          name: RouteNames.collectorStop,
          pageBuilder: (_, state) => _animatedPage(
            state: state,
            child: CollectorStopDetailScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/collector/confirm/:id',
          name: RouteNames.collectorConfirm,
          pageBuilder: (_, state) => _animatedPage(
            state: state,
            child: CollectorConfirmScreen(requestId: state.pathParameters['id']!),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => CollectorShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/collector', name: RouteNames.collector, builder: (_, _) => const CollectorHomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/collector/tour', name: RouteNames.collectorTour, builder: (_, _) => const CollectorTourScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/collector/history', name: RouteNames.collectorHistory, builder: (_, _) => const CollectorHistoryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/collector/earnings', name: RouteNames.collectorEarnings, builder: (_, _) => const CollectorEarningsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/collector/profile', name: RouteNames.collectorProfile, builder: (_, _) => const ProfileScreen()),
            ]),
          ],
        ),
      ],

      // -------------------------------------------------------- Back-office
      if (target.hasBackOffice) ...[
        ShellRoute(
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(path: '/admin', name: RouteNames.admin, builder: (_, _) => const AdminDashboardScreen()),
            GoRoute(path: '/admin/reports', builder: (_, _) => const AdminReportsScreen()),
            GoRoute(path: '/admin/zones', builder: (_, _) => const AdminZonesScreen()),
            GoRoute(path: '/admin/reports-comm', builder: (_, _) => const AdminReportsCommScreen()),
            GoRoute(
              path: '/admin/settings',
              builder: (_, _) => const SettingsScreen(embedded: true, title: 'Paramètres — Municipalité'),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => CompanyShell(child: child),
          routes: [
            GoRoute(path: '/company', name: RouteNames.company, builder: (_, _) => const CompanyDashboardScreen()),
            GoRoute(path: '/company/dispatch', builder: (_, _) => const CompanyDispatchScreen()),
            GoRoute(path: '/company/fleet', builder: (_, _) => const CompanyFleetScreen()),
            GoRoute(path: '/company/revenue', builder: (_, _) => const CompanyRevenueScreen()),
            GoRoute(
              path: '/company/settings',
              builder: (_, _) => const SettingsScreen(embedded: true, title: 'Paramètres — Entreprise'),
            ),
          ],
        ),
      ],
    ],
  );
});

bool _isCitizenRoute(String loc) {
  const roots = ['/home', '/report', '/collect', '/map', '/profile', '/rewards', '/history', '/notifications'];
  return roots.any((r) => loc == r || loc.startsWith('$r/'));
}
