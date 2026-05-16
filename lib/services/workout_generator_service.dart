import 'plan_engine.dart';

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
    // Simulate network/AI delay as requested in task 3
    // However, the task says "In the PlannerFormScreen... show a loading screen for a random duration"
    // So we just return the result here.
    
    return PlanEngine.generatePersonalizedPlan(
      name: name,
      goal: goal,
      level: level,
      equipment: equipment,
      focusArea: focusArea,
      injury: injury,
      timePerSession: timePerSession,
    );
  }
}
