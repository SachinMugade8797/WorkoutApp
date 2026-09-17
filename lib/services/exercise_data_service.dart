import '../models/exercise_model.dart';

class ExerciseDataService {
  static List<WorkoutExercise> exercises = const [];

  static Future<void> initialize() async {
    exercises = await loadExercises();
  }
}