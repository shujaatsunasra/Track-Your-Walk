import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../theme/global_theme.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/activity_providers.dart';
import '../../../services/navigation_service.dart';

/// Session summary screen shown after completing a run
class SessionSummaryScreen extends ConsumerStatefulWidget {
  final ActivitySession session;

  const SessionSummaryScreen({super.key, required this.session});

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.session.stats;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GlobalTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(
                theme,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(GlobalTheme.spacing24),
                  child: Column(
                    children: [
                      // Celebration header
                      _buildCelebrationHeader(theme, stats),

                      const SizedBox(height: GlobalTheme.spacing32),

                      // Main stats grid
                      _buildMainStats(theme, stats),

                      const SizedBox(height: GlobalTheme.spacing32),

                      // Route preview (if available)
                      if (widget.session.routePoints.isNotEmpty)
                        _buildRoutePreview(theme),

                      const SizedBox(height: GlobalTheme.spacing32),

                      // Detailed metrics
                      _buildDetailedMetrics(theme, stats),

                      const SizedBox(height: GlobalTheme.spacing40),

                      // Action buttons
                      _buildActionButtons(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(GlobalTheme.spacing16),
      child: Row(
        children: [
          // Close button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.surfaceCard,
              borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
              boxShadow: GlobalTheme.cardShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
                onTap: () {
                  // Smart navigation back - if we can pop, do it, otherwise go to history
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    NavigationService.goToHistory(context);
                  }
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: GlobalTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Share button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: GlobalTheme.primaryGradient,
              borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
              boxShadow: GlobalTheme.neonGlow(
                GlobalTheme.primaryNeon,
                opacity: 0.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
                onTap: _shareSession,
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationHeader(ThemeData theme, FitnessStats stats) {
    return Column(
      children: [
        // Achievement icon
        Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: GlobalTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: GlobalTheme.neonGlow(
                  GlobalTheme.primaryNeon,
                  opacity: 0.4,
                ),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 60,
                color: Colors.black,
              ),
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.elasticOut)
            .then()
            .shimmer(duration: 1500.ms),

        const SizedBox(height: GlobalTheme.spacing24),

        // Congratulations text
        Text(
          'Run Complete!',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: GlobalTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: GlobalTheme.spacing8),

        Text(
          'Great job on completing your ${widget.session.activityType.displayName.toLowerCase()}!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: GlobalTheme.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildMainStats(ThemeData theme, FitnessStats stats) {
    final mainStats = [
      {
        'label': 'Distance',
        'value': stats.formattedDistance,
        'icon': Icons.route_rounded,
        'color': GlobalTheme.primaryAccent,
      },
      {
        'label': 'Time',
        'value': _formatModernDuration(stats.totalDuration),
        'icon': Icons.timer_rounded,
        'color': GlobalTheme.primaryAction,
      },
      {
        'label': 'Pace',
        'value': stats.formattedAveragePace,
        'icon': Icons.speed_rounded,
        'color': GlobalTheme.statusWarning,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(GlobalTheme.spacing24),
      decoration: BoxDecoration(
        gradient: GlobalTheme.cardGradient,
        borderRadius: BorderRadius.circular(GlobalTheme.radiusXLarge),
        border: Border.all(color: GlobalTheme.surfaceBorder, width: 1),
        boxShadow: GlobalTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Header
          Text(
            'SESSION SUMMARY',
            style: theme.textTheme.labelLarge?.copyWith(
              color: GlobalTheme.primaryNeon,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: GlobalTheme.spacing24),

          // Stats grid
          Row(
            children: mainStats.asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value;

              return Expanded(
                child:
                    Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: (stat['color'] as Color).withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  GlobalTheme.radiusLarge,
                                ),
                              ),
                              child: Icon(
                                stat['icon'] as IconData,
                                color: stat['color'] as Color,
                                size: 28,
                              ),
                            ),

                            const SizedBox(height: GlobalTheme.spacing12),

                            Text(
                              stat['value'] as String,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: GlobalTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: GlobalTheme.spacing4),

                            Text(
                              stat['label'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: GlobalTheme.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 700 + (index * 200)),
                          duration: 500.ms,
                        )
                        .slideY(begin: 0.3, end: 0),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePreview(ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: GlobalTheme.cardGradient,
        borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
        border: Border.all(color: GlobalTheme.surfaceBorder, width: 1),
        boxShadow: GlobalTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
        child: Stack(
          children: [
            // Actual route map
            if (widget.session.routePoints.isNotEmpty)
              FlutterMap(
                options: MapOptions(
                  initialCenter: widget.session.routePoints.first,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.fitness_mobile',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.session.routePoints,
                        strokeWidth: 4.0,
                        color: GlobalTheme.primaryAccent,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Start marker
                      if (widget.session.routePoints.isNotEmpty)
                        Marker(
                          point: widget.session.routePoints.first,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GlobalTheme.statusSuccess,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      // End marker
                      if (widget.session.routePoints.length > 1)
                        Marker(
                          point: widget.session.routePoints.last,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GlobalTheme.statusError,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              )
            else
              // Fallback for empty route
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GlobalTheme.primaryAccent.withOpacity(0.1),
                      GlobalTheme.primaryAction.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 48,
                        color: GlobalTheme.textTertiary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No route data',
                        style: TextStyle(
                          color: GlobalTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Overlay with route info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(GlobalTheme.spacing16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: GlobalTheme.spacing8),
                    Text(
                      'Route: ${widget.session.routePoints.length} points',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GlobalTheme.primaryNeon.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'View Details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDetailedMetrics(ThemeData theme, FitnessStats stats) {
    final detailedMetrics = [
      {
        'label': 'Calories Burned',
        'value': stats.formattedCalories,
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'label': 'Steps',
        'value': stats.formattedSteps,
        'icon': Icons.directions_walk_rounded,
      },
      {
        'label': 'Elevation Gain',
        'value': stats.formattedElevation,
        'icon': Icons.trending_up_rounded,
      },
      {
        'label': 'Average Speed',
        'value': '${(stats.averageSpeedMps * 3.6).toStringAsFixed(1)} km/h',
        'icon': Icons.speed_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Metrics',
          style: theme.textTheme.titleLarge?.copyWith(
            color: GlobalTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: GlobalTheme.spacing16),

        ...detailedMetrics.asMap().entries.map((entry) {
          final index = entry.key;
          final metric = entry.value;

          return Container(
                margin: const EdgeInsets.only(bottom: GlobalTheme.spacing12),
                padding: const EdgeInsets.all(GlobalTheme.spacing16),
                decoration: BoxDecoration(
                  color: GlobalTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
                  border: Border.all(
                    color: GlobalTheme.surfaceBorder.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(GlobalTheme.spacing8),
                      decoration: BoxDecoration(
                        color: GlobalTheme.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          GlobalTheme.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        metric['icon'] as IconData,
                        color: GlobalTheme.primaryAccent,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: GlobalTheme.spacing16),

                    Expanded(
                      child: Text(
                        metric['label'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: GlobalTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    Text(
                      metric['value'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: GlobalTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 1400 + (index * 100)),
                duration: 400.ms,
              )
              .slideX(begin: 0.3, end: 0);
        }),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Primary action - Save and continue
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveAndContinue,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Save Activity'),
            style: theme.elevatedButtonTheme.style?.copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: GlobalTheme.spacing16),
              ),
            ),
          ),
        ),

        const SizedBox(height: GlobalTheme.spacing16),

        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareSession,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
              ),
            ),

            const SizedBox(width: GlobalTheme.spacing16),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: _viewAnalytics,
                icon: const Icon(Icons.analytics_rounded),
                label: const Text('Analytics'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 1800.ms).slideY(begin: 0.2, end: 0);
  }

  void _saveAndContinue() async {
    // Save the session to history
    // In a real app, this would save to a database or local storage

    // Reset the activity controller so users can start a new activity
    ref.read(activityControllerProvider).resetActivity();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(GlobalTheme.spacing6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(GlobalTheme.radiusSmall),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: GlobalTheme.spacing12),
            const Text(
              'Activity saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: GlobalTheme.statusSuccess,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(GlobalTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate to history screen to show the saved activity
    NavigationService.goToHistory(context);
  }

  void _shareSession() {
    // In a real app, this would open the system share sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 18),
            SizedBox(width: GlobalTheme.spacing8),
            Text('Sharing feature coming soon!'),
          ],
        ),
        backgroundColor: GlobalTheme.statusInfo,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(GlobalTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
        ),
      ),
    );
  }

  void _viewAnalytics() {
    // In a real app, this would navigate to analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
            SizedBox(width: GlobalTheme.spacing8),
            Text('Analytics feature coming soon!'),
          ],
        ),
        backgroundColor: GlobalTheme.statusInfo,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(GlobalTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
        ),
      ),
    );
  }

  /// Modern, user-friendly duration formatting
  String _formatModernDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (minutes > 0) {
      if (seconds > 0 && minutes < 10) {
        return '${minutes}m ${seconds}s';
      }
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
