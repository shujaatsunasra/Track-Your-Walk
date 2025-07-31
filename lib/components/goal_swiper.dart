import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fitness_models.dart';
import '../providers/goal_provider.dart';
import '../theme/global_theme.dart';
import 'neon_card.dart';

class GoalSwiper extends ConsumerStatefulWidget {
  final VoidCallback? onGoalSelected;

  const GoalSwiper({super.key, this.onGoalSelected});

  @override
  ConsumerState<GoalSwiper> createState() => _GoalSwiperState();
}

class _GoalSwiperState extends ConsumerState<GoalSwiper>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.8, // Better spacing
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350), // Faster animation
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return SizedBox(
      height: 320, // Increased height for better proportions
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(), // Better scroll physics
        onPageChanged: (index) {
          ref.read(goalProvider.notifier).setCurrentIndex(index);
        },
        itemCount: goalState.goals.length,
        itemBuilder: (context, index) {
          final goal = goalState.goals[index];
          final isActive = index == goalState.currentIndex;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..scale(isActive ? 1.0 : 0.85), // Better scaling
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GoalCard(
                    goal: goal,
                    isActive: isActive,
                    onTap: () {
                      ref.read(goalProvider.notifier).selectGoal(goal);
                      widget.onGoalSelected?.call();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class GoalCard extends StatefulWidget {
  final Goal goal;
  final bool isActive;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNeonCard = widget.goal.type == GoalType.tenK && widget.isActive;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return NeonCard(
          onTap: widget.onTap,
          isGlowing: isNeonCard,
          gradient: isNeonCard ? GlobalTheme.primaryGradient : null,
          backgroundColor: isNeonCard ? null : GlobalTheme.surfaceCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal type indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isNeonCard
                      ? Colors.black.withOpacity(0.2)
                      : GlobalTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '1/4',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isNeonCard
                        ? Colors.black
                        : GlobalTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              // Goal title
              Text(
                widget.goal.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isNeonCard ? Colors.black : GlobalTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // Goal description
              Text(
                widget.goal.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isNeonCard
                      ? Colors.black.withOpacity(0.7)
                      : GlobalTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Goal details
              Row(
                children: [
                  _buildDetailChip('Level', widget.goal.levelText, isNeonCard),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    'Duration',
                    widget.goal.durationText,
                    isNeonCard,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(String label, String value, bool isNeonCard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isNeonCard
            ? Colors.black.withOpacity(0.2)
            : GlobalTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isNeonCard
                  ? Colors.black.withOpacity(0.6)
                  : GlobalTheme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isNeonCard ? Colors.black : GlobalTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to get goalState from provider
extension GoalCardExt on _GoalCardState {
  int get currentIndex => 0; // simplified for now
}
