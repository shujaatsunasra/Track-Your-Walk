import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/global_theme.dart';
import '../../../models/fitness_models.dart';
import '../../../providers/activity_providers.dart';
import '../../../components/modern_ui_components.dart';
import '../../../services/navigation_service.dart';

/// Production-quality history screen for viewing past runs
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'This Week',
    'This Month',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runHistory = ref.watch(runHistoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GlobalTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              _buildHeader(
                theme,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

              // Filter chips
              _buildFilterChips(
                theme,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              // History list or empty state
              Expanded(
                child: runHistory.when(
                  data: (runs) => runs.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildHistoryList(theme, runs),
                  loading: () => _buildLoadingState(theme),
                  error: (error, stack) =>
                      _buildErrorState(theme, error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () => NavigationService.goToRun(context),
            backgroundColor: GlobalTheme.primaryAction,
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'New Activity',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ).animate().scale(
            delay: 800.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(GlobalTheme.spacing16),
      child: Row(
        children: [
          // Back button
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
                onTap: () => NavigationService.goBack(context),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: GlobalTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: GlobalTheme.spacing16),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Run History',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GlobalTheme.textPrimary,
                  ),
                ),
                Text(
                  'Track your progress over time',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GlobalTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Stats summary badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GlobalTheme.spacing12,
              vertical: GlobalTheme.spacing8,
            ),
            decoration: BoxDecoration(
              gradient: GlobalTheme.primaryGradient,
              borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
              boxShadow: GlobalTheme.neonGlow(
                GlobalTheme.primaryNeon,
                opacity: 0.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.black,
                  size: 16,
                ),
                const SizedBox(width: GlobalTheme.spacing4),
                Consumer(
                  builder: (context, ref, child) {
                    final totalRuns = ref.watch(totalRunsProvider);
                    return Text(
                      '$totalRuns runs',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: GlobalTheme.spacing16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;

          return Padding(
            padding: EdgeInsets.only(
              right: index < _filterOptions.length - 1
                  ? GlobalTheme.spacing12
                  : 0,
            ),
            child:
                FilterChip(
                      label: Text(
                        option,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? Colors.black
                              : GlobalTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = option;
                        });
                      },
                      backgroundColor: theme.surfaceCard,
                      selectedColor: GlobalTheme.primaryNeon,
                      side: BorderSide(
                        color: isSelected
                            ? GlobalTheme.primaryNeon
                            : GlobalTheme.surfaceBorder,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          GlobalTheme.radiusLarge,
                        ),
                      ),
                      elevation: 0,
                      pressElevation: 0,
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 300 + (index * 100)),
                      duration: 400.ms,
                    )
                    .slideX(begin: 0.3, end: 0),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(ThemeData theme, List<ActivitySession> runs) {
    final filteredRuns = _filterRuns(runs);

    if (filteredRuns.isEmpty) {
      return _buildEmptyFilterState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(GlobalTheme.spacing16),
      itemCount: filteredRuns.length,
      itemBuilder: (context, index) {
        final run = filteredRuns[index];
        return _buildRunCard(theme, run, index);
      },
    );
  }

  Widget _buildRunCard(ThemeData theme, ActivitySession run, int index) {
    return Container(
          margin: const EdgeInsets.only(bottom: GlobalTheme.spacing16),
          decoration: BoxDecoration(
            gradient: GlobalTheme.cardGradient,
            borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
            border: Border.all(color: GlobalTheme.surfaceBorder, width: 1),
            boxShadow: GlobalTheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
              onTap: () => _showRunDetails(run),
              child: Padding(
                padding: const EdgeInsets.all(GlobalTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with date and activity type
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(GlobalTheme.spacing8),
                          decoration: BoxDecoration(
                            color: _getActivityColor(
                              run.activityType,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              GlobalTheme.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            _getActivityIcon(run.activityType),
                            color: _getActivityColor(run.activityType),
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: GlobalTheme.spacing12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatActivityType(run.activityType),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: GlobalTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDate(run.stats.startTime),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: GlobalTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Duration
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GlobalTheme.spacing12,
                            vertical: GlobalTheme.spacing6,
                          ),
                          decoration: BoxDecoration(
                            color: GlobalTheme.backgroundTertiary,
                            borderRadius: BorderRadius.circular(
                              GlobalTheme.radiusLarge,
                            ),
                            border: Border.all(
                              color: GlobalTheme.surfaceBorder.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _formatDuration(run.stats.totalDuration),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: GlobalTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: GlobalTheme.spacing20),

                    // Stats row
                    Row(
                      children: [
                        _buildStatItem(
                          theme,
                          'Distance',
                          '${(run.stats.totalDistanceMeters / 1000).toStringAsFixed(2)} km',
                          Icons.route_rounded,
                        ),
                        const SizedBox(width: GlobalTheme.spacing24),
                        _buildStatItem(
                          theme,
                          'Pace',
                          _formatPace(run.stats.averagePaceSecondsPerKm / 60),
                          Icons.speed_rounded,
                        ),
                        const SizedBox(width: GlobalTheme.spacing24),
                        _buildStatItem(
                          theme,
                          'Calories',
                          '${run.stats.estimatedCalories}',
                          Icons.local_fire_department_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + (index * 50)),
          duration: 500.ms,
        )
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: GlobalTheme.primaryAccent),
              const SizedBox(width: GlobalTheme.spacing4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: GlobalTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: GlobalTheme.spacing4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: GlobalTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GlobalTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: GlobalTheme.surfaceCard,
                borderRadius: BorderRadius.circular(GlobalTheme.radiusXLarge),
                boxShadow: GlobalTheme.cardShadow,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 60,
                color: GlobalTheme.textTertiary,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: GlobalTheme.spacing24),

            Text(
              'No runs yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: GlobalTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: GlobalTheme.spacing8),

            Text(
              'Start your first run to see your\nprogress and achievements here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GlobalTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: GlobalTheme.spacing32),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                NavigationService.goToRun(context);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Running'),
              style: theme.elevatedButtonTheme.style?.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: GlobalTheme.spacing24,
                    vertical: GlobalTheme.spacing16,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GlobalTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 80,
              color: GlobalTheme.textTertiary,
            ).animate().scale(duration: 600.ms),

            const SizedBox(height: GlobalTheme.spacing24),

            Text(
              'No runs found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: GlobalTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: GlobalTheme.spacing8),

            Text(
              'Try adjusting your filter or\nstart a new run',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GlobalTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: LoadingStateCard(
        message: 'Loading your run history...',
        accentColor: GlobalTheme.primaryAccent,
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GlobalTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(GlobalTheme.spacing20),
              decoration: BoxDecoration(
                color: GlobalTheme.statusError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
                border: Border.all(
                  color: GlobalTheme.statusError.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: GlobalTheme.statusError,
              ),
            ),

            const SizedBox(height: GlobalTheme.spacing20),

            Text(
              'Error loading history',
              style: theme.textTheme.titleLarge?.copyWith(
                color: GlobalTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: GlobalTheme.spacing8),

            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: GlobalTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: GlobalTheme.spacing24),

            OutlinedButton.icon(
              onPressed: () {
                // Refresh the data
                final _ = ref.refresh(runHistoryProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<ActivitySession> _filterRuns(List<ActivitySession> runs) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return runs
            .where((run) => run.stats.startTime.isAfter(weekStart))
            .toList();
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return runs
            .where((run) => run.stats.startTime.isAfter(monthStart))
            .toList();
      case 'This Year':
        final yearStart = DateTime(now.year, 1, 1);
        return runs
            .where((run) => run.stats.startTime.isAfter(yearStart))
            .toList();
      default:
        return runs;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return GlobalTheme.primaryAccent;
      case ActivityType.walking:
        return GlobalTheme.statusInfo;
      case ActivityType.cycling:
        return GlobalTheme.primaryAction;
      case ActivityType.hiking:
        return GlobalTheme.statusWarning;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run_rounded;
      case ActivityType.walking:
        return Icons.directions_walk_rounded;
      case ActivityType.cycling:
        return Icons.directions_bike_rounded;
      case ActivityType.hiking:
        return Icons.hiking_rounded;
    }
  }

  String _formatActivityType(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Morning Run';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.hiking:
        return 'Hiking';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatPace(double pace) {
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}/km';
  }

  void _showRunDetails(ActivitySession run) {
    // Navigate to detailed run view
    // This would typically navigate to a detailed screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: GlobalTheme.backgroundGradient,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(GlobalTheme.radiusXLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: GlobalTheme.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GlobalTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(GlobalTheme.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Run Details',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: GlobalTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),

                      const SizedBox(height: GlobalTheme.spacing24),

                      // More detailed stats would go here
                      Text(
                        'Detailed analytics and route map would be shown here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: GlobalTheme.textSecondary,
                        ),
                      ),
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
}

// Provider for total runs count
final totalRunsProvider = Provider<int>((ref) {
  final history = ref.watch(runHistoryProvider);
  return history.when(
    data: (runs) => runs.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
