import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/ai/providers/ai_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/community/providers/community_provider.dart';
import 'features/contacts/providers/contacts_provider.dart';
import 'features/emergency/providers/emergency_provider.dart';
import 'features/emergency/providers/sos_history_provider.dart';
import 'features/home/providers/safety_score_provider.dart';
import 'features/journey/providers/journey_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SafeHerApp());
}

/// Root widget: wires up app-wide providers before the themed,
/// router-driven [_AppView] is built.
class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth (must be first — router depends on it)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Feature providers
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => SosHistoryProvider()),
        ChangeNotifierProvider(create: (_) => SafetyScoreProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // Built once (not on every rebuild) since it depends on AuthProvider
  // via refreshListenable rather than needing to be reconstructed.
  late final GoRouter _router = buildAppRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
