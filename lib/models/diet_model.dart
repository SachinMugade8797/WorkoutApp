class DietProfile {
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String goal;
  final String activityLevel;
  final String mealPreference;
  final bool autoWater;
  final double? customWaterGoal;

  DietProfile({
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.mealPreference,
    required this.autoWater,
    this.customWaterGoal,
  });

  Map<String, dynamic> toJson() => {
    'age': age,
    'weight': weight,
    'height': height,
    'gender': gender,
    'goal': goal,
    'activityLevel': activityLevel,
    'mealPreference': mealPreference,
    'autoWater': autoWater,
    'customWaterGoal': customWaterGoal,
  };

  factory DietProfile.fromJson(Map<String, dynamic> json) => DietProfile(
    age: json['age'],
    weight: json['weight'].toDouble(),
    height: json['height'].toDouble(),
    gender: json['gender'],
    goal: json['goal'],
    activityLevel: json['activityLevel'],
    mealPreference: json['mealPreference'],
    autoWater: json['autoWater'],
    customWaterGoal: json['customWaterGoal']?.toDouble(),
  );
}

class Meal {
  final String name;
  final String description;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  Meal({
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
  };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    name: json['name'],
    description: json['description'],
    calories: json['calories'],
    protein: json['protein'].toDouble(),
    carbs: json['carbs'].toDouble(),
    fats: json['fats'].toDouble(),
  );
}

class DailyDietPlan {
  final List<Meal> breakfast;
  final List<Meal> lunch;
  final List<Meal> snacks;
  final List<Meal> dinner;

  DailyDietPlan({
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  Map<String, dynamic> toJson() => {
    'breakfast': breakfast.map((m) => m.toJson()).toList(),
    'lunch': lunch.map((m) => m.toJson()).toList(),
    'snacks': snacks.map((m) => m.toJson()).toList(),
    'dinner': dinner.map((m) => m.toJson()).toList(),
  };

  factory DailyDietPlan.fromJson(Map<String, dynamic> json) => DailyDietPlan(
    breakfast: (json['breakfast'] as List).map((m) => Meal.fromJson(m)).toList(),
    lunch: (json['lunch'] as List).map((m) => Meal.fromJson(m)).toList(),
    snacks: (json['snacks'] as List).map((m) => Meal.fromJson(m)).toList(),
    dinner: (json['dinner'] as List).map((m) => Meal.fromJson(m)).toList(),
  );
}
