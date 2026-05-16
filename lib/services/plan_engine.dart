import '../models/exercise_model.dart';
import 'dart:math';

class PlanEngine {
  static Map<String, dynamic> generatePersonalizedPlan({
    required String name,
    required String goal,
    required String level,
    required String equipment,
    required String focusArea,
    required String injury,
    required String timePerSession,
  }) {
    final random = Random();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    Map<String, List<String>> weeklyPlan = {};
    double totalWeeklyCalories = 0;

    int sessionMinutes = int.parse(timePerSession.split(' ')[0]);

    // Volume based on level
    int exercisesPerDay = level == 'Beginner' ? 5 : (level == 'Intermediate' ? 6 : 8);

    for (var day in days) {
      if (day == 'Sun') {
        weeklyPlan[day] = [];
        continue;
      }

      // 1. Filter exercises based on equipment
      List<WorkoutExercise> availableExercises = masterExerciseList.where((ex) {
        if (equipment == 'None') return ex.equipment == 'None';
        if (equipment == 'Dumbbells Only') return ex.equipment == 'None' || ex.equipment == 'Dumbbells' || ex.equipment == 'Chair/Bench';
        return true; // Full Gym
      }).toList();

      // 2. Focus Area logic with "AI" variety
      // We prioritize focusArea but include 20% variety from other areas for balance
      List<WorkoutExercise> focusPool = availableExercises.where((ex) {
        if (focusArea == 'Full Body') return true;
        if (focusArea == 'Chest & Arms') return ex.category == 'Chest' || ex.category == 'Arms';
        if (focusArea == 'Legs & Glutes') return ex.category == 'Legs';
        if (focusArea == 'Core & Abs') return ex.category == 'Abs';
        return true;
      }).toList();

      List<WorkoutExercise> varietyPool = availableExercises.where((ex) => !focusPool.contains(ex)).toList();

      // 3. Goal-based prioritization
      if (goal == 'Weight Loss') {
        // Prioritize higher calorie exercises
        focusPool.sort((a, b) => b.caloriesPerMinute.compareTo(a.caloriesPerMinute));
      } else if (goal == 'Muscle Gain') {
        // Keep focus area strict
      }

      // 4. Injury Filtering
      if (injury == 'Knee Pain') {
        focusPool = _handleKneePain(focusPool);
        varietyPool = _handleKneePain(varietyPool);
      } else if (injury == 'Back Pain') {
        focusPool = focusPool.where((ex) => ex.id != 'bk_01' && ex.id != 'ab_05' && ex.id != 'bk_05').toList();
        varietyPool = varietyPool.where((ex) => ex.id != 'bk_01' && ex.id != 'ab_05' && ex.id != 'bk_05').toList();
      }

      // 5. Select exercises
      List<WorkoutExercise> dailySelection = [];
      focusPool.shuffle(random);
      varietyPool.shuffle(random);

      // Take mostly from focus, but some from variety
      int varietyCount = (exercisesPerDay * 0.2).round();
      int focusCount = exercisesPerDay - varietyCount;

      dailySelection.addAll(focusPool.take(focusCount));
      if (dailySelection.length < exercisesPerDay) {
        dailySelection.addAll(varietyPool.take(exercisesPerDay - dailySelection.length));
      }

      weeklyPlan[day] = dailySelection.map((e) => e.id).toList();

      // 6. Calculate calories for this day
      for (var ex in dailySelection) {
        double minutesPerExercise = sessionMinutes / dailySelection.length;
        totalWeeklyCalories += ex.caloriesPerMinute * minutesPerExercise;
      }
    }

    return {
      'plan': weeklyPlan,
      'totalBurn': totalWeeklyCalories.round(),
      'userName': name,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  static List<WorkoutExercise> _handleKneePain(List<WorkoutExercise> list) {
    return list.map((ex) {
      if (ex.id == 'lg_01' || ex.id == 'lg_05' || ex.id == 'lg_02') {
        // Replace high-impact leg moves with Glute Bridges (lg_03) or Calf Raises (lg_04)
        return masterExerciseList.firstWhere((e) => e.id == 'lg_03');
      }
      return ex;
    }).toList();
  }
}
