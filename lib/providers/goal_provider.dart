import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fitness_models.dart';

class GoalState {
  final List<Goal> goals;
  final Goal? selectedGoal;
  final int currentIndex;

  const GoalState({
    required this.goals,
    this.selectedGoal,
    this.currentIndex = 0,
  });

  GoalState copyWith({
    List<Goal>? goals,
    Goal? selectedGoal,
    int? currentIndex,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class GoalNotifier extends StateNotifier<GoalState> {
  GoalNotifier() : super(GoalState(goals: sampleGoals));

  void selectGoal(Goal goal) {
    final updatedGoals = state.goals
        .map((g) => g.copyWith(isSelected: g.id == goal.id))
        .toList();

    state = state.copyWith(goals: updatedGoals, selectedGoal: goal);
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void nextGoal() {
    if (state.currentIndex < state.goals.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousGoal() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }
}

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  return GoalNotifier();
});
