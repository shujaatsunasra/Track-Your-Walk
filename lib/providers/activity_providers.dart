import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/fitness_models.dart';
import '../services/activity_controller.dart';

/// Provider for the activity controller singleton
final activityControllerProvider = Provider<ActivityController>((ref) {
  return ActivityController();
});

/// Provider for current activity session
final currentActivitySessionProvider =
    StateNotifierProvider<ActivitySessionNotifier, ActivitySession?>((ref) {
      final controller = ref.watch(activityControllerProvider);
      return ActivitySessionNotifier(controller);
    });

/// Provider for activity state
final activityStateProvider =
    StateNotifierProvider<ActivityStateNotifier, ActivityState>((ref) {
      final controller = ref.watch(activityControllerProvider);
      return ActivityStateNotifier(controller);
    });

/// Provider for fitness stats
final fitnessStatsProvider =
    StateNotifierProvider<FitnessStatsNotifier, FitnessStats>((ref) {
      final controller = ref.watch(activityControllerProvider);
      return FitnessStatsNotifier(controller);
    });

/// Provider for route points
final routePointsProvider =
    StateNotifierProvider<RoutePointsNotifier, List<LatLng>>((ref) {
      final controller = ref.watch(activityControllerProvider);
      return RoutePointsNotifier(controller);
    });

/// Activity session state notifier
class ActivitySessionNotifier extends StateNotifier<ActivitySession?> {
  final ActivityController _controller;

  ActivitySessionNotifier(this._controller) : super(null) {
    _controller.addListener(_onControllerUpdate);
    state = _controller.currentSession;
  }

  void _onControllerUpdate() {
    if (mounted) {
      state = _controller.currentSession;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

/// Activity state notifier
class ActivityStateNotifier extends StateNotifier<ActivityState> {
  final ActivityController _controller;

  ActivityStateNotifier(this._controller) : super(ActivityState.idle) {
    _controller.addListener(_onControllerUpdate);
    state = _controller.state;
  }

  void _onControllerUpdate() {
    if (mounted) {
      state = _controller.state;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

/// Fitness stats state notifier
class FitnessStatsNotifier extends StateNotifier<FitnessStats> {
  final ActivityController _controller;

  FitnessStatsNotifier(this._controller)
    : super(FitnessStats(startTime: DateTime.now())) {
    _controller.addListener(_onControllerUpdate);
    state = _controller.stats;
  }

  void _onControllerUpdate() {
    if (mounted) {
      state = _controller.stats;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

/// Route points state notifier
class RoutePointsNotifier extends StateNotifier<List<LatLng>> {
  final ActivityController _controller;

  RoutePointsNotifier(this._controller) : super([]) {
    _controller.addListener(_onControllerUpdate);
    state = _controller.routePoints;
  }

  void _onControllerUpdate() {
    if (mounted) {
      state = _controller.routePoints;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

/// Activity actions provider
final activityActionsProvider = Provider<ActivityActions>((ref) {
  final controller = ref.watch(activityControllerProvider);
  return ActivityActions(controller);
});

/// Activity actions class for UI interaction
class ActivityActions {
  final ActivityController _controller;

  ActivityActions(this._controller);

  /// Initialize the activity controller
  Future<bool> initialize() => _controller.initialize();

  /// Start a new activity
  Future<bool> startActivity(ActivityType type) =>
      _controller.startActivity(type);

  /// Pause current activity
  Future<bool> pauseActivity() => _controller.pauseActivity();

  /// Resume paused activity
  Future<bool> resumeActivity() => _controller.resumeActivity();

  /// Stop current activity
  Future<bool> stopActivity() => _controller.stopActivity();

  /// Reset activity to idle
  void resetActivity() => _controller.resetActivity();

  /// Check if action is available
  bool get canStart => _controller.canStart;
  bool get canPause => _controller.canPause;
  bool get canResume => _controller.canResume;
  bool get canStop => _controller.canStop;
  bool get isTracking => _controller.isTracking;
  bool get isPaused => _controller.isPaused;
  ActivityType get activityType => _controller.activityType;
}

/// Provider for run history (mock data for now)
final runHistoryProvider = FutureProvider<List<ActivitySession>>((ref) async {
  // Return mock completed sessions for demonstration
  // In a real app, this would fetch from local storage or API
  await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

  return [
    ActivitySession(
      id: '1',
      activityType: ActivityType.running,
      state: ActivityState.completed,
      stats: FitnessStats(
        totalDistanceMeters: 5200,
        totalDuration: const Duration(minutes: 28, seconds: 15),
        activeDuration: const Duration(minutes: 26, seconds: 42),
        averageSpeedMps: 3.1,
        estimatedCalories: 312,
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        endTime: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
        averagePaceSecondsPerKm: 324, // 5:24 min/km
        totalSteps: 6240,
        elevationGain: 48.0,
      ),
    ),
    ActivitySession(
      id: '2',
      activityType: ActivityType.walking,
      state: ActivityState.completed,
      stats: FitnessStats(
        totalDistanceMeters: 3800,
        totalDuration: const Duration(minutes: 42, seconds: 8),
        activeDuration: const Duration(minutes: 40, seconds: 30),
        averageSpeedMps: 1.5,
        estimatedCalories: 156,
        startTime: DateTime.now().subtract(const Duration(days: 5)),
        endTime: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
        averagePaceSecondsPerKm: 662, // 11:02 min/km
        totalSteps: 4560,
        elevationGain: 22.0,
      ),
    ),
    ActivitySession(
      id: '3',
      activityType: ActivityType.running,
      state: ActivityState.completed,
      stats: FitnessStats(
        totalDistanceMeters: 10100,
        totalDuration: const Duration(minutes: 52, seconds: 34),
        activeDuration: const Duration(minutes: 48, seconds: 12),
        averageSpeedMps: 3.5,
        estimatedCalories: 624,
        startTime: DateTime.now().subtract(const Duration(days: 8)),
        endTime: DateTime.now().subtract(const Duration(days: 8, hours: -1)),
        averagePaceSecondsPerKm: 286, // 4:46 min/km
        totalSteps: 12120,
        elevationGain: 95.0,
      ),
    ),
  ];
});
