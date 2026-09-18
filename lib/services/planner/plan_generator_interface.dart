import '../../models/exercise_model.dart';
import '../../models/user_profile.dart';
import 'plan_models.dart';

/// The single "brain" contract for generating workout plans.
///
/// Everything else in the app talks to this interface, so the implementation
/// can be swapped behind the scenes (rule-based now, LLM or custom ML later)
/// without touching any callers.
abstract class PlanGeneratorInterface {
  /// Generates a full weekly plan for [profile].
  ///
  /// [planType] selects which kind of plan to build (see [PlanTypes]) and
  /// [availableExercises] is the exercise catalog to pick from.
  Future<WeeklyPlan> generatePlan({
    required UserProfile profile,
    required String planType,
    required List<WorkoutExercise> availableExercises,
  });
}

/// Canonical plan type identifiers passed through [PlanGeneratorInterface.generatePlan].
///
/// The main ("personalized") plan is the only one eligible for the weekly
/// missed-day bonus; every type in here maps to a fixed routine that ignores it.
abstract final class PlanTypes {
  /// Main AI-generated personalized plan. An optional `:<focusSlug>` suffix
  /// (e.g. `main:chest_arms`, `main:legs_glutes`, `main:core_abs`) carries the
  /// user's focus-area preference as a light selection bias.
  static const String main = 'main';

  /// Fixed low-intensity stretching routine.
  static const String stretching = 'stretching';

  /// Fixed whole-body routine.
  static const String fullBody = 'full_body';

  /// Fixed arms-only routine.
  static const String armsOnly = 'arms_only';
}