import '../../models/exercise_model.dart';
import '../../models/user_profile.dart';
import 'plan_generator_interface.dart';
import 'plan_models.dart';

/// Placeholder for a future ML-model-backed plan generator.
///
/// (e.g. a recommendation model trained on workout data). Wire it up by
/// returning an instance of this class from
/// `PlanGeneratorFactory.getActivePlanGenerator()`. The requirements for the
/// main plan (multi-muscle-group days, muscle rest between heavy sessions) and
/// the fixed plan types must be preserved for users.
class MlPlanGenerator implements PlanGeneratorInterface {
  @override
  Future<WeeklyPlan> generatePlan({
    required UserProfile profile,
    required String planType,
    required List<WorkoutExercise> availableExercises,
  }) {
    throw UnimplementedError('MlPlanGenerator is not implemented yet.');
  }
}