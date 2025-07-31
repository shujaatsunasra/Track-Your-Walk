import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core theme and models
import 'theme/global_theme.dart';
import 'models/fitness_models.dart';

// Core screens for the single flow
import 'features/welcome/welcome_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/fitness/screens/enhanced_run_screen.dart';
import 'features/fitness/screens/session_summary_screen.dart';
import 'features/fitness/screens/history_screen.dart';
import 'features/fitness/screens/permission_denied_screen.dart';
import 'features/onboarding/permission_onboarding.dart';

// Essential services
import 'services/enterprise_logger.dart';
import 'services/performance_service.dart';
import 'services/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only essential services
  final logger = EnterpriseLogger();
  logger.initialize();

  final performanceService = PerformanceService();
  performanceService.init();

  final cacheManager = CacheManager();
  await cacheManager.preloadCriticalData();

  logger.logInfo('App Startup', 'Fitness tracking app initialized');

  runApp(const ProviderScope(child: FitnessApp()));
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fitness Tracker',
      theme: GlobalTheme.themeData,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Clean, focused router with single app flow
final GoRouter _router = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: GlobalTheme.backgroundGradient),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: GlobalTheme.statusError,
            ),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(
                color: GlobalTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    // Main app flow: Welcome → Goals → Run → Summary → History
    GoRoute(
      path: '/',
      name: 'welcome',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const WelcomeScreen(),
      ),
    ),

    GoRoute(
      path: '/goals',
      name: 'goals',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const GoalsScreen(),
      ),
    ),

    GoRoute(
      path: '/run',
      name: 'run',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const EnhancedRunScreen(),
      ),
    ),

    GoRoute(
      path: '/session-summary',
      name: 'session-summary',
      pageBuilder: (context, state) {
        final session = state.extra as ActivitySession?;
        if (session == null) {
          // Redirect to history if no session provided
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/history');
          });
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return _buildPageWithTransition(
          key: state.pageKey,
          child: SessionSummaryScreen(session: session),
        );
      },
    ),

    GoRoute(
      path: '/history',
      name: 'history',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const HistoryScreen(),
      ),
    ),

    // Permission flow
    GoRoute(
      path: '/permission-onboarding',
      name: 'permission-onboarding',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: PermissionOnboardingFlow(onComplete: () => context.go('/goals')),
      ),
    ),

    GoRoute(
      path: '/permission-denied',
      name: 'permission-denied',
      pageBuilder: (context, state) => _buildPageWithTransition(
        key: state.pageKey,
        child: const PermissionDeniedScreen(),
      ),
    ),
  ],
);

// Unified page transition for consistent UX
CustomTransitionPage _buildPageWithTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );

      return SlideTransition(
        position: tween.animate(curvedAnimation),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}
