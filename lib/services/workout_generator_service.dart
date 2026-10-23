import '../models/user_profile.dart';
import 'exercise_data_service.dart';
import 'planner/plan_generator_factory.dart';
import 'planner/plan_generator_interface.dart';
import 'planner/plan_models.dart';

/// App-facing wrapper around the active [PlanGeneratorInterface].
///
/// Converts the form's string-based inputs into a [UserProfile] and plan type,
/// delegates to the generator obtained from [PlanGeneratorFactory], then maps
/// the returned [WeeklyPlan] back into the legacy
/// `Map<String, List<String>>` (day -> exercise ids) shape the rest of the app
/// persists and renders.
class WorkoutGeneratorService {
  static Future<Map<String, dynamic>> generate7DayPlan({
    required String name,
    required String goal,
    required String level,
    required String equipment,
    required String focusArea,
    required String injury,
    required String timePerSession,
  }) async {
    final generator = PlanGeneratorFactory.getActivePlanGenerator();

    final profile = UserProfile(
      name: name,
      goal: goal,
      experienceLevel: level,
      equipment: equipment,
      timePerSession: timePerSession,
      injuries: injury == 'None' ? const <String>[] : <String>[injury],
    );

    final plan = await generator.generatePlan(
      profile: profile,
      planType: _planTypeForFocusArea(focusArea),
      availableExercises: ExerciseDataService.exercises,
    );

    return _toLegacyResult(plan, profile);
  }

  /// The main plan is always the current flow; the focus-area choice becomes a
  /// `main:<slug>` plan type used as a selection bias inside the generator.
  static String _planTypeForFocusArea(String focusArea) {
    switch (focusArea) {
      case 'Chest & Arms':
        return '${PlanTypes.main}:chest_arms';
      case 'Legs & Glutes':
        return '${PlanTypes.main}:legs_glutes';
      case 'Core & Abs':
        return '${PlanTypes.main}:core_abs';
      default:
        // 'Full Body' -> no focus bias.
        return PlanTypes.main;
    }
  }

  static Map<String, dynamic> _toLegacyResult(WeeklyPlan plan, UserProfile profile) {
    final weeklyPlan = <String, List<String>>{};
    double totalWeeklyCalories = 0;

    final sessionMinutes =
        int.parse((profile.timePerSession ?? '30 mins').split(' ').first);

    for (final day in plan.days) {
      weeklyPlan[day.dayLabel] = day.exercises.map((e) => e.exercise.id).toList();
      if (day.exercises.isEmpty) continue;
      final minutesPerExercise = sessionMinutes / day.exercises.length;
      for (final planned in day.exercises) {
        totalWeeklyCalories += planned.exercise.caloriesPerMinute * minutesPerExercise;
      }
    }

    return {
      'plan': weeklyPlan,
      'totalBurn': totalWeeklyCalories.round(),
      'userName': profile.name ?? 'Athlete',
      'goal': profile.goal ?? 'Build Muscle',
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}