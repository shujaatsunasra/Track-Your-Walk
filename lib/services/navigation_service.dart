import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation service for smooth and consistent app navigation
class NavigationService {
  /// Navigate to welcome screen
  static void goToWelcome(BuildContext context) {
    context.go('/');
  }

  /// Navigate to goals screen with smooth transition
  static void goToGoals(BuildContext context) {
    context.go('/goals');
  }

  /// Navigate to run screen with smooth transition
  static void goToRun(BuildContext context) {
    context.go('/run');
  }

  /// Navigate to history screen
  static void goToHistory(BuildContext context) {
    context.go('/history');
  }

  /// Navigate to session summary with session data
  static void goToSessionSummary(BuildContext context, dynamic session) {
    context.push('/session-summary', extra: session);
  }

  /// Navigate back with haptic feedback
  static void goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Fallback to run screen if can't pop (session summary edge case)
      context.go('/run');
    }
  }

  /// Check if we can navigate back
  static bool canGoBack(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Navigate and replace current route
  static void goAndReplace(BuildContext context, String route) {
    context.go(route);
  }

  /// Push a new route (for modal/overlay navigation)
  static Future<T?> pushRoute<T>(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => screen));
  }
}

/// Enhanced page transition that provides smooth animations
class SmoothPageTransition extends CustomTransitionPage<void> {
  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  const SmoothPageTransition({
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.reverseTransitionDuration = const Duration(milliseconds: 400),
    super.key,
  }) : super(
         child: child,
         transitionDuration: transitionDuration,
         reverseTransitionDuration: reverseTransitionDuration,
         transitionsBuilder: _transitionsBuilder,
       );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Smooth slide and fade transition
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(opacity: fadeAnimation, child: child),
      ),
    );
  }
}
