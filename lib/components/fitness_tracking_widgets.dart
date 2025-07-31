import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/fitness_models.dart';
import '../services/haptic_service.dart';

/// Real-time fitness stats display widget
class FitnessStatsWidget extends StatelessWidget {
  final FitnessStats stats;
  final ActivityState state;
  final Color? accentColor;
  final bool showDetailedStats;

  const FitnessStatsWidget({
    super.key,
    required this.stats,
    required this.state,
    this.accentColor,
    this.showDetailedStats = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State indicator with enhanced animations
          Row(
            children: [
              _buildStateIndicator(state, accent),
              const SizedBox(width: 12),
              Text(
                state.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
              const Spacer(),
              if (state == ActivityState.running)
                _buildPulsingDot(
                  accent,
                ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
            ],
          ),

          const SizedBox(height: 28),

          // Primary stats grid with staggered animations
          _buildStatsGrid(theme, accent),

          if (showDetailedStats) ...[
            const SizedBox(height: 24),
            _buildDetailedStats(
              theme,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStateIndicator(ActivityState state, Color accent) {
    IconData icon;
    Color color;

    switch (state) {
      case ActivityState.idle:
        icon = Icons.play_circle_outline;
        color = Colors.grey;
        break;
      case ActivityState.running:
        icon = Icons.play_circle_filled;
        color = accent;
        break;
      case ActivityState.paused:
        icon = Icons.pause_circle_filled;
        color = Colors.orange;
        break;
      case ActivityState.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildPulsingDot(Color accent) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 1.seconds)
        .fadeOut(duration: 1.seconds);
  }

  Widget _buildStatsGrid(ThemeData theme, Color accent) {
    final stats = [
      {
        'label': 'Distance',
        'value': this.stats.formattedDistance,
        'icon': Icons.straighten,
        'delay': 200,
      },
      {
        'label': 'Duration',
        'value': this.stats.formattedActiveDuration,
        'icon': Icons.timer,
        'delay': 300,
      },
      {
        'label': 'Pace',
        'value': this.stats.formattedCurrentPace,
        'icon': Icons.speed,
        'delay': 400,
      },
      {
        'label': 'Calories',
        'value': this.stats.formattedCalories,
        'icon': Icons.local_fire_department,
        'delay': 500,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: stats.map((stat) {
        return _buildStatCard(
              stat['label'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              accent,
              theme,
            )
            .animate(delay: Duration(milliseconds: stat['delay'] as int))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
            .then()
            .shimmer(duration: 2000.ms, color: accent.withOpacity(0.1));
      }).toList(),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color accent,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Stats',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailedStatItem(
                'Max Speed',
                stats.formattedCurrentSpeed,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailedStatItem(
                'Steps',
                stats.formattedSteps,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailedStatItem(
                'Elevation',
                stats.formattedElevation,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailedStatItem(
                'Avg Pace',
                stats.formattedAveragePace,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStatItem(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Activity control buttons widget
class ActivityControlsWidget extends StatelessWidget {
  final ActivityState state;
  final ActivityType activityType;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final ValueChanged<ActivityType>? onActivityTypeChanged;
  final Color? accentColor;
  final bool isLoading;

  const ActivityControlsWidget({
    super.key,
    required this.state,
    required this.activityType,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onActivityTypeChanged,
    this.accentColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.primaryColor;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 700;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Activity type selector
          if (state == ActivityState.idle) ...[
            _buildActivityTypeSelector(theme, accent),
            SizedBox(height: isCompact ? 16 : 20),
          ],

          // Control buttons
          _buildControlButtons(theme, accent),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActivityTypeSelector(ThemeData theme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ActivityType.values.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              final isSelected = type == activityType;

              return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: onActivityTypeChanged != null
                          ? () async {
                              await HapticService.fitnessHaptic('light');
                              onActivityTypeChanged!(type);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(25),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? accent
                                : theme.dividerColor.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accent.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getActivityIcon(type),
                              size: 16,
                              color: isSelected ? Colors.white : accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 300 + (index * 100)))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(ThemeData theme, Color accent) {
    return Row(
      children: [
        // Secondary action button
        if (state == ActivityState.running || state == ActivityState.paused)
          Expanded(child: _buildSecondaryButton(theme, accent)),

        if (state == ActivityState.running || state == ActivityState.paused)
          const SizedBox(width: 16),

        // Primary action button
        Expanded(
          flex: state == ActivityState.idle ? 1 : 2,
          child: _buildPrimaryButton(theme, accent),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(ThemeData theme, Color accent) {
    String text;
    IconData icon;
    VoidCallback? onPressed;
    Color color;

    switch (state) {
      case ActivityState.idle:
        text = 'Start ${activityType.displayName}';
        icon = Icons.play_arrow;
        onPressed = onStart;
        color = accent;
        break;
      case ActivityState.running:
        text = 'Pause';
        icon = Icons.pause;
        onPressed = onPause;
        color = Colors.orange;
        break;
      case ActivityState.paused:
        text = 'Resume';
        icon = Icons.play_arrow;
        onPressed = onResume;
        color = accent;
        break;
      case ActivityState.completed:
        text = 'Start New';
        icon = Icons.refresh;
        onPressed = onStart;
        color = accent;
        break;
    }

    return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: isLoading
                ? null
                : () async {
                    // Add haptic feedback before action
                    await HapticService.fitnessHaptic('light');
                    onPressed?.call();
                  },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.symmetric(vertical: isLoading ? 18 : 16),
              decoration: BoxDecoration(
                color: isLoading ? color.withOpacity(0.7) : color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isLoading ? 0.2 : 0.3),
                    blurRadius: isLoading ? 8 : 12,
                    offset: Offset(0, isLoading ? 2 : 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    )
                  else
                    Icon(icon, color: Colors.white, size: 20)
                        .animate()
                        .scale(duration: 200.ms)
                        .then()
                        .shimmer(
                          duration: 1500.ms,
                          color: Colors.white.withOpacity(0.4),
                        ),

                  SizedBox(width: isLoading ? 12 : 8),

                  Text(
                    isLoading ? 'Processing...' : text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                ],
              ),
            ),
          ),
        )
        .animate()
        .scale(duration: 300.ms, curve: Curves.elasticOut)
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildSecondaryButton(ThemeData theme, Color accent) {
    return InkWell(
          onTap: isLoading
              ? null
              : () async {
                  await HapticService.fitnessHaptic('light');
                  onStop?.call();
                },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLoading
                    ? theme.colorScheme.error.withOpacity(0.5)
                    : theme.colorScheme.error,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stop,
                  size: 18,
                  color: isLoading
                      ? theme.colorScheme.error.withOpacity(0.5)
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stop',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isLoading
                        ? theme.colorScheme.error.withOpacity(0.5)
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic);
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
}

/// Large timer display widget
class FitnessTimerWidget extends StatelessWidget {
  final Duration duration;
  final ActivityState state;
  final Color? accentColor;

  const FitnessTimerWidget({
    super.key,
    required this.duration,
    required this.state,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.primaryColor;

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final timeText = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Duration',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 12),

          Text(
                timeText,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 52,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms)
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 3000.ms, color: accent.withOpacity(0.3)),

          const SizedBox(height: 16),

          if (state == ActivityState.running)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(3, (index) {
                  return Container(
                        margin: EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        duration: Duration(milliseconds: 800 + (index * 200)),
                      );
                }),
              ],
            ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
