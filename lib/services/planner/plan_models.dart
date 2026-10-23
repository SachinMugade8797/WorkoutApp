import '../../models/exercise_model.dart';

/// A full weekly plan produced by a [PlanGeneratorInterface] implementation.
class WeeklyPlan {
  final List<DayPlan> days;

  const WeeklyPlan({required this.days});
}

/// One scheduled day inside a [WeeklyPlan].
///
/// [dayLabel] is the display label (e.g. 'Mon', 'Tue', ... 'Sun') and
/// [exercises] holds every planned exercise for that day (empty = rest day).
class DayPlan {
  final String dayLabel;
  final List<PlannedExercise> exercises;

  const DayPlan({required this.dayLabel, required this.exercises});
}

/// A single exercise within a configured day.
///
/// [exercise] carries the source data, while [sets] / [reps] hold the final
/// prescription for that day (which generators may adjust, e.g. the
/// missed-day bonus in [RuleBasedPlanGenerator]).
class PlannedExercise {
  final WorkoutExercise exercise;
  final int sets;
  final int reps;

  const PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
  });
}