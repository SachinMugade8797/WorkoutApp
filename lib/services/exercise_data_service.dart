import '../models/exercise_model.dart';

class ExerciseDataService {
  static List<WorkoutExercise> exercises = const [];

  static Future<List<WorkoutExercise>> initialize() async {
    exercises = await loadExercises();
    return exercises;
  }
}