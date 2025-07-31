import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/activity_providers.dart';
import '../../../components/interactive_map_widget.dart';
import '../../../components/fitness_tracking_widgets.dart';
import '../../../services/navigation_service.dart';
import '../../../services/haptic_service.dart';

/// Million-dollar level fitness tracking screen with real-time GPS integration
class EnhancedRunScreen extends ConsumerStatefulWidget {
  const EnhancedRunScreen({super.key});

  @override
  ConsumerState<EnhancedRunScreen> createState() => _EnhancedRunScreenState();
}

class _EnhancedRunScreenState extends ConsumerState<EnhancedRunScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ActivityType _selectedActivityType = ActivityType.running;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeActivityController();

    // Check for auto-start parameter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoStartParameter();
    });
  }

  Future<void> _checkAutoStartParameter() async {
    final uri = Uri.base;
    final autoStart = uri.queryParameters['autoStart'] == 'true';

    if (autoStart && _isInitialized) {
      // Auto-start the activity after a brief delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        final actions = ref.read(activityActionsProvider);
        await _handleStartActivity(actions);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeActivityController() async {
    try {
      final actions = ref.read(activityActionsProvider);
      await actions.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing activity controller: $e');
      // Show user-friendly error but don't block the UI
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityState = ref.watch(activityStateProvider);
    final fitnessStats = ref.watch(fitnessStatsProvider);
    final routePoints = ref.watch(routePointsProvider);
    final actions = ref.read(activityActionsProvider);
    final mediaQuery = MediaQuery.of(context);

    if (!_isInitialized) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // PERFORMANCE FIX: Simple loading indicator
                CircularProgressIndicator(color: theme.primaryColor),
                SizedBox(height: mediaQuery.size.height * 0.02),
                Text('Initializing GPS...', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // App bar with activity status
                _buildAppBar(theme, activityState, actions),

                // Tab bar for Map/Stats view
                if (activityState != ActivityState.idle)
                  _buildTabBar(theme)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.1, end: 0),

                // Main content area
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: activityState == ActivityState.idle
                        ? _buildIdleView(theme, actions)
                        : _buildActiveTrackingView(
                            theme,
                            activityState,
                            fitnessStats,
                            routePoints,
                            actions,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(
    ThemeData theme,
    ActivityState state,
    ActivityActions actions,
  ) {
    final statusText = _getStatusText(state);
    final statusColor = _getStatusColor(state, theme);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 700;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        isCompact ? 8 : 16,
        20,
        isCompact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getActivityIcon(actions.activityType),
                  color: statusColor,
                  size: isCompact ? 24 : 28,
                ),
              )
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 2000.ms, color: statusColor.withOpacity(0.3)),

          SizedBox(width: isCompact ? 10 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${actions.activityType.displayName} Tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 18 : null,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

                SizedBox(height: isCompact ? 1 : 2),

                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 12 : null,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),

          if (state != ActivityState.idle)
            AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 12,
                    vertical: isCompact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 800.ms)
                          .fadeOut(duration: 800.ms),

                      SizedBox(width: isCompact ? 6 : 8),

                      Text(
                        state.displayName.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontSize: isCompact ? 10 : 11,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms)
                .slideX(begin: 0.3, end: 0, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.cardColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: theme.primaryColor,
        labelColor: theme.primaryColor,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        tabs: const [
          Tab(icon: Icon(Icons.map), text: 'Map'),
          Tab(icon: Icon(Icons.analytics), text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildIdleView(ThemeData theme, ActivityActions actions) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 700;
    final horizontalPadding = mediaQuery.size.width * 0.05;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding.clamp(16.0, 24.0),
        vertical: isCompact ? 16 : 20,
      ),
      child: Column(
        children: [
          SizedBox(height: isCompact ? 16 : 24),

          // Welcome message with better responsive design
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isCompact ? 20 : 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor.withOpacity(0.12),
                  theme.primaryColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_run,
                        size: isCompact ? 48 : 64,
                        color: theme.primaryColor,
                      ),
                    )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(
                      duration: 2000.ms,
                      color: theme.primaryColor.withOpacity(0.3),
                    ),

                SizedBox(height: isCompact ? 16 : 20),

                Text(
                  'Ready to Track Your Fitness!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 20 : null,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                SizedBox(height: isCompact ? 8 : 12),

                Text(
                  'Choose your activity type and start tracking your route, pace, distance, and calories burned in real-time.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                    height: 1.5,
                    fontSize: isCompact ? 13 : null,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

          SizedBox(height: isCompact ? 28 : 36),

          // Activity controls with enhanced animations
          ActivityControlsWidget(
            state: ActivityState.idle,
            activityType: _selectedActivityType,
            onStart: () => _handleStartActivity(actions),
            onActivityTypeChanged: (type) {
              setState(() {
                _selectedActivityType = type;
              });
            },
            accentColor: theme.primaryColor,
            isLoading: _isLoading,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

          SizedBox(height: isCompact ? 28 : 36),

          // Features showcase with staggered animations
          _buildFeaturesShowcase(theme),

          SizedBox(height: isCompact ? 16 : 24),
        ],
      ),
    );
  }

  Widget _buildActiveTrackingView(
    ThemeData theme,
    ActivityState state,
    FitnessStats stats,
    List<LatLng> routePoints,
    ActivityActions actions,
  ) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Map view
        _buildMapView(theme, state, stats, routePoints, actions),

        // Stats view
        _buildStatsView(theme, state, stats, actions),
      ],
    );
  }

  Widget _buildMapView(
    ThemeData theme,
    ActivityState state,
    FitnessStats stats,
    List<LatLng> routePoints,
    ActivityActions actions,
  ) {
    return Stack(
      children: [
        // Interactive map
        Positioned.fill(
          child: InteractiveMapWidget(
            showCurrentLocation: true,
            showRoute: true,
            enableTracking: state.isActive,
            routeColor: theme.primaryColor,
            accentColor: theme.primaryColor,
          ),
        ),

        // Floating timer
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: FitnessTimerWidget(
            duration: stats.activeDuration,
            state: state,
            accentColor: theme.primaryColor,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.3, end: 0),
        ),

        // Bottom controls
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: ActivityControlsWidget(
            state: state,
            activityType: actions.activityType,
            onPause: () => _handlePauseActivity(actions),
            onResume: () => _handleResumeActivity(actions),
            onStop: () => _handleStopActivity(actions),
            accentColor: theme.primaryColor,
            isLoading: _isLoading,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
        ),
      ],
    );
  }

  Widget _buildStatsView(
    ThemeData theme,
    ActivityState state,
    FitnessStats stats,
    ActivityActions actions,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Large timer display
          FitnessTimerWidget(
            duration: stats.activeDuration,
            state: state,
            accentColor: theme.primaryColor,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Main fitness stats
          FitnessStatsWidget(
            stats: stats,
            state: state,
            accentColor: theme.primaryColor,
            showDetailedStats: true,
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          // Control buttons
          ActivityControlsWidget(
            state: state,
            activityType: actions.activityType,
            onPause: () => _handlePauseActivity(actions),
            onResume: () => _handleResumeActivity(actions),
            onStop: () => _handleStopActivity(actions),
            accentColor: theme.primaryColor,
            isLoading: _isLoading,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeaturesShowcase(ThemeData theme) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 700;

    final features = [
      {
        'icon': Icons.gps_fixed,
        'title': 'Real-time GPS',
        'description': 'Accurate location tracking with live route mapping',
        'delay': 800,
      },
      {
        'icon': Icons.speed,
        'title': 'Live Metrics',
        'description':
            'Distance, pace, time, and calories updated every second',
        'delay': 900,
      },
      {
        'icon': Icons.save,
        'title': 'Session History',
        'description': 'Save and review your workout sessions',
        'delay': 1000,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 18 : null,
          ),
        ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),

        SizedBox(height: isCompact ? 16 : 20),

        ...features.asMap().entries.map((entry) {
          final feature = entry.value;

          return Container(
                margin: EdgeInsets.only(bottom: isCompact ? 16 : 20),
                child: InkWell(
                  onTap: () async {
                    // Add haptic feedback for interactions
                    await HapticFeedback.lightImpact();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.all(isCompact ? 16 : 20),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isCompact ? 12 : 16),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            color: theme.primaryColor,
                            size: isCompact ? 20 : 24,
                          ),
                        ),

                        SizedBox(width: isCompact ? 16 : 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feature['title'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isCompact ? 14 : null,
                                ),
                              ),
                              SizedBox(height: isCompact ? 4 : 6),
                              Text(
                                feature['description'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  height: 1.4,
                                  fontSize: isCompact ? 12 : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: feature['delay'] as int))
              .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
        }).toList(),
      ],
    );
  }

  // Helper methods
  String _getStatusText(ActivityState state) {
    switch (state) {
      case ActivityState.idle:
        return 'Ready to start tracking';
      case ActivityState.running:
        return 'Activity in progress';
      case ActivityState.paused:
        return 'Activity paused';
      case ActivityState.completed:
        return 'Activity completed';
    }
  }

  Color _getStatusColor(ActivityState state, ThemeData theme) {
    switch (state) {
      case ActivityState.idle:
        return theme.colorScheme.onSurface.withOpacity(0.7);
      case ActivityState.running:
        return theme.primaryColor;
      case ActivityState.paused:
        return Colors.orange;
      case ActivityState.completed:
        return Colors.green;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.hiking:
        return Icons.terrain;
    }
  }

  // Action handlers with enhanced UX
  Future<void> _handleStartActivity(ActivityActions actions) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Haptic feedback for start action
      await HapticFeedback.mediumImpact();

      final success = await actions.startActivity(_selectedActivityType);
      if (!success) {
        await HapticFeedback.mediumImpact();
        _showErrorSnackBar(
          'Failed to start activity. Please check GPS and permissions.',
        );
      } else {
        // Success haptic feedback
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      await HapticFeedback.mediumImpact();
      _showErrorSnackBar('Error starting activity: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePauseActivity(ActivityActions actions) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await HapticFeedback.mediumImpact();
      await actions.pauseActivity();
    } catch (e) {
      await HapticFeedback.mediumImpact();
      _showErrorSnackBar('Error pausing activity: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResumeActivity(ActivityActions actions) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await HapticFeedback.mediumImpact();
      await actions.resumeActivity();
    } catch (e) {
      await HapticFeedback.mediumImpact();
      _showErrorSnackBar('Error resuming activity: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStopActivity(ActivityActions actions) async {
    final shouldStop = await _showStopConfirmation();
    if (!shouldStop) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await HapticFeedback.mediumImpact();

      // Stop the activity and get the completed session
      final success = await actions.stopActivity();
      if (!success) {
        await HapticFeedback.mediumImpact();
        _showErrorSnackBar('Failed to stop activity. Please try again.');
        return;
      }

      // Get the completed session from the controller
      final completedSession = ref
          .read(activityControllerProvider)
          .currentSession;
      if (completedSession == null) {
        await HapticFeedback.mediumImpact();
        _showErrorSnackBar('Session data not available. Activity stopped.');
        return;
      }

      // Success feedback
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.mediumImpact();

      // Navigate to session summary screen with session data
      if (mounted) {
        NavigationService.goToSessionSummary(context, completedSession);
      }
    } catch (e) {
      await HapticFeedback.mediumImpact();
      _showErrorSnackBar('Error stopping activity: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showStopConfirmation() async {
    // Haptic feedback for important dialog
    await HapticFeedback.mediumImpact();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Stop Activity?')),
              ],
            ),
            content: const Text(
              'Are you sure you want to stop and save this activity? Your progress will be saved.',
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await HapticService.fitnessHaptic('light');
                  Navigator.of(context).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  await HapticService.fitnessHaptic('light');
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.stop, size: 18),
                label: const Text(
                  'Stop & Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
