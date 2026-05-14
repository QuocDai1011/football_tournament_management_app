import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/tournaments/presentation/screens/tournaments_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_detail_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_form_screen.dart';
import '../../features/teams/presentation/screens/teams_screen.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
import '../../features/teams/presentation/screens/team_form_screen.dart';
import '../../features/players/presentation/screens/players_screen.dart';
import '../../features/players/presentation/screens/player_detail_screen.dart';
import '../../features/players/presentation/screens/player_form_screen.dart';
import '../../features/matches/presentation/screens/matches_screen.dart';
import '../../features/matches/presentation/screens/match_detail_screen.dart';
import '../../features/matches/presentation/screens/match_form_screen.dart';
import '../../features/standings/presentation/screens/standings_screen.dart';
import '../../features/awards/presentation/screens/awards_screen.dart';
import '../../features/seasons/presentation/screens/seasons_screen.dart';
import '../../features/registrations/presentation/screens/registrations_screen.dart';
import '../../shared/presentation/screens/main_shell_screen.dart';
import '../../features/auth/domain/providers/auth_providers.dart';
import 'app_routes.dart';

// Re-export AppRoutes để các file cũ import app_router.dart vẫn hoạt động
export 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider.
/// KEY FIX: Dùng ref.read trong redirect (không watch) + ref.listen để refresh.
/// Điều này tránh router bị recreate mỗi khi auth state thay đổi.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authAsync = ref.read(currentAdminProvider);
      final location = state.matchedLocation;

      // Khi auth state đang loading (chưa biết user có login không)
      // → ở lại splash để chờ
      if (authAsync.isLoading) {
        if (location == AppRoutes.splash) return null;
        return AppRoutes.splash;
      }

      // Nếu có lỗi từ auth stream → về login
      if (authAsync.hasError) {
        if (location == AppRoutes.login) return null;
        return AppRoutes.login;
      }

      final admin = authAsync.valueOrNull;
      final isAuthenticated = admin != null;
      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;

      // Chưa đăng nhập
      if (!isAuthenticated) {
        // Đang ở splash hoặc login → không redirect
        if (isSplash || isLogin) return null;
        // Ở màn hình khác → về login
        return AppRoutes.login;
      }

      // Đã đăng nhập
      // Đang ở splash hoặc login → về dashboard
      if (isSplash || isLogin) {
        return AppRoutes.dashboard;
      }

      // Đang ở màn hình khác → không redirect
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          // Tournaments
          GoRoute(
            path: AppRoutes.tournaments,
            builder: (_, __) => const TournamentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.tournamentCreate,
            builder: (_, __) => const TournamentFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.tournamentDetail,
            builder: (context, state) =>
                TournamentDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.tournamentEdit,
            builder: (context, state) =>
                TournamentFormScreen(tournamentId: state.pathParameters['id']),
          ),
          // Teams
          GoRoute(
            path: AppRoutes.teams,
            builder: (_, __) => const TeamsScreen(),
          ),
          GoRoute(
            path: AppRoutes.teamCreate,
            builder: (_, __) => const TeamFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.teamDetail,
            builder: (context, state) =>
                TeamDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.teamEdit,
            builder: (context, state) =>
                TeamFormScreen(teamId: state.pathParameters['id']),
          ),
          // Players
          GoRoute(
            path: AppRoutes.players,
            builder: (_, __) => const PlayersScreen(),
          ),
          GoRoute(
            path: AppRoutes.playerCreate,
            builder: (_, __) => const PlayerFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.playerDetail,
            builder: (context, state) =>
                PlayerDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.playerEdit,
            builder: (context, state) =>
                PlayerFormScreen(playerId: state.pathParameters['id']),
          ),
          // Matches
          GoRoute(
            path: AppRoutes.matches,
            builder: (_, __) => const MatchesScreen(),
          ),
          GoRoute(
            path: AppRoutes.matchCreate,
            builder: (_, __) => const MatchFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.matchEdit,
            builder: (context, state) =>
                MatchFormScreen(matchId: state.pathParameters['id']),
          ),
          GoRoute(
            path: AppRoutes.matchDetail,
            builder: (context, state) =>
                MatchDetailScreen(id: state.pathParameters['id']!),
          ),
          // Standings
          GoRoute(
            path: AppRoutes.standings,
            builder: (_, __) => const StandingsScreen(),
          ),
          // Awards
          GoRoute(
            path: AppRoutes.awards,
            builder: (_, __) => const AwardsScreen(),
          ),
          // Seasons
          GoRoute(
            path: AppRoutes.seasons,
            builder: (_, __) => const SeasonsScreen(),
          ),
          // Registrations
          GoRoute(
            path: AppRoutes.registrations,
            builder: (context, state) {
              final tournamentId =
                  state.uri.queryParameters['tournamentId'] ?? '';
              final seasonId = state.uri.queryParameters['seasonId'];
              return RegistrationsScreen(
                tournamentId: tournamentId,
                seasonId: seasonId,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );

  // Khi auth state thay đổi → chỉ gọi refresh (không recreate router)
  ref.listen<AsyncValue>(currentAdminProvider, (previous, next) {
    // Chỉ refresh khi state đã resolve (không còn loading)
    if (!next.isLoading) {
      router.refresh();
    }
  });

  return router;
});

/// Fade transition
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Error screen
class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
