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

    // Track used exercises globally for the week to ensure variety
    Set<String> usedInWeek = {};

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

      // 2. Goal-based prioritization logic
      if (goal == 'Lose Weight') {
        // Boost priority for high-intensity exercises
        availableExercises.sort((a, b) {
          // Check for high-burn exercises like Mountain Climbers (ab_05), Diamond Pushups (ar_04), etc.
          bool isAHighIntensity = a.caloriesPerMinute >= 7.5 || a.id == 'ab_05';
          bool isBHighIntensity = b.caloriesPerMinute >= 7.5 || b.id == 'ab_05';
          if (isAHighIntensity && !isBHighIntensity) return -1;
          if (!isAHighIntensity && isBHighIntensity) return 1;
          return b.caloriesPerMinute.compareTo(a.caloriesPerMinute);
        });
      } else if (goal == 'Build Muscle') {
        // Prioritize strength movements and equipment-based exercises
        availableExercises.sort((a, b) {
          bool isAStrength = a.equipment != 'None' || a.category == 'Chest' || a.category == 'Back';
          bool isBStrength = b.equipment != 'None' || b.category == 'Chest' || b.category == 'Back';
          if (isAStrength && !isBStrength) return -1;
          if (!isAStrength && isBStrength) return 1;
          return 0;
        });
      }

      // 3. Focus Area filtering
      List<WorkoutExercise> focusPool = availableExercises.where((ex) {
        if (focusArea == 'Full Body') return true;
        if (focusArea == 'Chest & Arms') return ex.category == 'Chest' || ex.category == 'Arms';
        if (focusArea == 'Legs & Glutes') return ex.category == 'Legs';
        if (focusArea == 'Core & Abs') return ex.category == 'Abs';
        return true;
      }).toList();

      List<WorkoutExercise> varietyPool = availableExercises.where((ex) => !focusPool.contains(ex)).toList();

      // 4. Injury Filtering (Stricter)
      if (injury == 'Knee Pain') {
        focusPool = _filterKneePain(focusPool);
        varietyPool = _filterKneePain(varietyPool);
      } else if (injury == 'Back Pain') {
        focusPool = focusPool.where((ex) => !_isBackStrain(ex.id)).toList();
        varietyPool = varietyPool.where((ex) => !_isBackStrain(ex.id)).toList();
      }

      // 5. Select exercises with variety tracking
      List<WorkoutExercise> dailySelection = [];
      
      // Shuffle pools to avoid same top-sorted results every time
      focusPool.shuffle(random);
      varietyPool.shuffle(random);

      void pickFromPool(List<WorkoutExercise> pool, int count) {
        int pickedCount = 0;
        // First Pass: Try to pick items NOT used yet this week
        for (var ex in pool) {
          if (pickedCount >= count) break;
          if (!usedInWeek.contains(ex.id) && !dailySelection.any((e) => e.id == ex.id)) {
            dailySelection.add(ex);
            usedInWeek.add(ex.id);
            pickedCount++;
          }
        }
        // Second Pass: If we need more, pick previously used items (avoiding duplicates in the SAME day)
        if (pickedCount < count) {
          for (var ex in pool) {
            if (pickedCount >= count) break;
            if (!dailySelection.any((e) => e.id == ex.id)) {
              dailySelection.add(ex);
              pickedCount++;
            }
          }
        }
      }

      int varietyTarget = (exercisesPerDay * 0.2).round();
      int focusTarget = exercisesPerDay - varietyTarget;

      pickFromPool(focusPool, focusTarget);
      pickFromPool(varietyPool, exercisesPerDay - dailySelection.length);

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

  static List<WorkoutExercise> _filterKneePain(List<WorkoutExercise> list) {
    // Remove high impact knee moves
    const kneeStrainIds = {'lg_01', 'lg_05', 'lg_02', 'ab_05'}; 
    return list.where((ex) => !kneeStrainIds.contains(ex.id)).toList();
  }

  static bool _isBackStrain(String id) {
    const backStrainIds = {'bk_01', 'ab_05', 'bk_05', 'lg_05'};
    return backStrainIds.contains(id);
  }
}
