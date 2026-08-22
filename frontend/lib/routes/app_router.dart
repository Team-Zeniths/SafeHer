import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/ai/screens/ai_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/contacts/screens/contacts_screen.dart';
import '../features/emergency/screens/emergency_screen.dart';
import '../features/emergency/screens/sos_screen.dart';
import '../features/emergency/screens/siren_screen.dart';
import '../features/emergency/screens/incident_report_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/journey/screens/journey_screen.dart';
import '../features/journey/screens/journey_map_screen.dart';
import '../models/journey_model.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../shared/widgets/main_shell.dart';
import 'route_names.dart';

/// Builds the app's [GoRouter] instance.
///
/// Uses a [StatefulShellRoute] with [MainShell] for the five bottom-nav
/// tabs. All other screens are full-page push routes outside the shell.
GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authProvider,
    routes: [
      // ── Splash & Auth (no shell) ───────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.extra as String?,
        ),
      ),

      // ── Full-page push routes (outside bottom nav) ─────────────────────
      GoRoute(path: RouteNames.sos, builder: (context, _) => const SosScreen()),
      GoRoute(path: RouteNames.siren, builder: (context, _) => const SirenScreen()),
      GoRoute(path: RouteNames.incidentReport, builder: (context, _) => const IncidentReportScreen()),
      GoRoute(path: RouteNames.notifications, builder: (context, _) => const NotificationsScreen()),
      GoRoute(path: RouteNames.contacts, builder: (context, _) => const ContactsScreen()),
      GoRoute(path: RouteNames.history, builder: (context, _) => const HistoryScreen()),
      GoRoute(path: RouteNames.aiAssistant, builder: (context, _) => const AiScreen()),
      GoRoute(path: RouteNames.editProfile, builder: (context, _) => const EditProfileScreen()),
      GoRoute(path: RouteNames.settings, builder: (context, _) => const SettingsScreen()),
      GoRoute(
        path: '/journey/map',
        builder: (_, state) {
          final journey = state.extra;
          // `extra` is only ever an in-memory object — it does not survive
          // state restoration (e.g. Android reclaiming the app in the
          // background). A hard `as JourneyModel` cast throws in that case
          // and takes the whole route down with it. Fall back to a clear
          // in-app screen instead of crashing.
          if (journey is! JourneyModel) {
            return Scaffold(
              appBar: AppBar(title: const Text('Journey Route')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        "This journey's map couldn't be reopened directly — "
                        'please go back to History and tap the journey again.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return JourneyMapScreen(journey: journey);
        },
      ),
      GoRoute(
        path: RouteNames.about,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('About SafeHer')),
          body: const Center(child: Text('Version 1.0.0 — Built with ❤️ for women\'s safety.')),
        ),
      ),

      // ── Shell (bottom navigation) ──────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.home, builder: (context, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.journey, builder: (context, _) => const JourneyScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.emergency, builder: (context, _) => const EmergencyScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.community, builder: (context, _) => const CommunityScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.profile, builder: (context, _) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final status = authProvider.status;
      final currentPath = state.matchedLocation;

      // Still restoring session — keep the splash screen up.
      if (status == AuthStatus.unknown) {
        return currentPath == RouteNames.splash ? null : RouteNames.splash;
      }

      // Splash screen manages its own timed navigation.
      if (currentPath == RouteNames.splash) return null;

      final isAuthRoute = currentPath == RouteNames.login ||
          currentPath == RouteNames.register ||
          currentPath == RouteNames.forgotPassword;

      if (status == AuthStatus.unauthenticated && !isAuthRoute) {
        return RouteNames.login;
      }

      if (status == AuthStatus.authenticated && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
