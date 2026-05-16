import 'dart:math';
import '../models/diet_model.dart';

class DietService {
  static Map<String, dynamic> calculateNutrition(DietProfile profile) {
    // BMR Calculation (Mifflin-St Jeor Equation)
    double bmr;
    if (profile.gender == 'Male') {
      bmr = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) + 5;
    } else {
      bmr = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) - 161;
    }

    // TDEE Calculation based on activity level
    double tdee;
    switch (profile.activityLevel) {
      case 'Beginner':
        tdee = bmr * 1.2; // Sedentary
        break;
      case 'Moderate':
        tdee = bmr * 1.55; // Moderate exercise
        break;
      case 'Active':
        tdee = bmr * 1.725; // Heavy exercise
        break;
      default:
        tdee = bmr * 1.2;
    }

    // Adjust calories based on goal
    double dailyCalories;
    switch (profile.goal) {
      case 'Weight Loss':
        dailyCalories = tdee - 500;
        break;
      case 'Weight Gain':
        dailyCalories = tdee + 500;
        break;
      case 'Muscle Gain':
        dailyCalories = tdee + 300;
        break;
      case 'Maintain Weight':
        dailyCalories = tdee;
        break;
      default:
        dailyCalories = tdee;
    }

    // Macro distribution
    // Protein: depends on goal and weight (g/kg)
    double proteinPerKg;
    if (profile.goal == 'Muscle Gain') {
      proteinPerKg = profile.activityLevel == 'Active' ? 2.2 : 1.8;
    } else if (profile.goal == 'Weight Loss') {
      proteinPerKg = 1.6;
    } else {
      proteinPerKg = 1.2;
    }

    double proteinGrams = profile.weight * proteinPerKg;
    double proteinCalories = proteinGrams * 4;

    // Fats: 25% of total calories
    double fatCalories = dailyCalories * 0.25;
    double fatGrams = fatCalories / 9;

    // Carbs: Remaining calories
    double carbCalories = dailyCalories - proteinCalories - fatCalories;
    double carbGrams = carbCalories / 4;

    return {
      'calories': dailyCalories.round(),
      'protein': proteinGrams.round(),
      'carbs': carbGrams.round(),
      'fats': fatGrams.round(),
    };
  }

  static Map<String, DailyDietPlan> generateWeeklyPlan(DietProfile profile) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    Map<String, DailyDietPlan> weeklyPlan = {};
    final nutrition = calculateNutrition(profile);
    
    for (var day in days) {
      weeklyPlan[day] = _generateDailyPlan(profile, nutrition);
    }
    
    return weeklyPlan;
  }

  static DailyDietPlan _generateDailyPlan(DietProfile profile, Map<String, dynamic> nutrition) {
    bool isVeg = profile.mealPreference == 'Vegetarian' || profile.mealPreference == 'Vegan' || profile.mealPreference == 'Indian Diet';
    bool isVegan = profile.mealPreference == 'Vegan';

    // Scale quantities based on calories (base 2000 kcal)
    double scale = nutrition['calories'] / 2000.0;

    List<Meal> breakfastOptions = [
      Meal(
        name: 'Oats with Fruits',
        description: '${(50 * scale).round()}g Oats, ${(250 * scale).round()}ml ${isVegan ? 'Almond Milk' : 'Milk'}, 1 medium Banana',
        calories: (350 * scale).round(),
        protein: 12 * scale,
        carbs: 60 * scale,
        fats: 8 * scale,
      ),
      Meal(
        name: 'Vegetable Poha',
        description: '${(100 * scale).round()}g Poha with veggies and peanuts',
        calories: (300 * scale).round(),
        protein: 8 * scale,
        carbs: 50 * scale,
        fats: 10 * scale,
      ),
      if (!isVegan)
        Meal(
          name: 'Paneer Paratha',
          description: '2 Whole wheat bread stuffed with ${(80 * scale).round()}g paneer',
          calories: (400 * scale).round(),
          protein: 18 * scale,
          carbs: 45 * scale,
          fats: 15 * scale,
        ),
      if (!isVeg)
        Meal(
          name: 'Egg Omelette',
          description: '${max(2, (3 * scale).round())} eggs with 2 slices whole wheat toast',
          calories: (350 * scale).round(),
          protein: 22 * scale,
          carbs: 20 * scale,
          fats: 18 * scale,
        ),
    ];

    List<Meal> lunchOptions = [
      Meal(
        name: 'Dal Rice & Sabzi',
        description: '${(150 * scale).round()}g Brown rice, 1 bowl Yellow dal and seasonal vegetable',
        calories: (500 * scale).round(),
        protein: 15 * scale,
        carbs: 80 * scale,
        fats: 12 * scale,
      ),
      if (!isVegan)
        Meal(
          name: 'Paneer Bhurji with Roti',
          description: '${(100 * scale).round()}g Scrambled paneer with ${max(1, (2 * scale).round())} whole wheat rotis',
          calories: (550 * scale).round(),
          protein: 25 * scale,
          carbs: 50 * scale,
          fats: 20 * scale,
        ),
      if (!isVeg)
        Meal(
          name: 'Grilled Chicken & Quinoa',
          description: '${(150 * scale).round()}g chicken breast with ${(100 * scale).round()}g quinoa and salad',
          calories: (500 * scale).round(),
          protein: 45 * scale,
          carbs: 40 * scale,
          fats: 10 * scale,
        ),
      Meal(
        name: 'Chickpea Curry (Chole)',
        description: '${(150 * scale).round()}g Chickpeas in tomato gravy with ${(100 * scale).round()}g rice',
        calories: (450 * scale).round(),
        protein: 18 * scale,
        carbs: 70 * scale,
        fats: 10 * scale,
      ),
    ];

    List<Meal> snackOptions = [
      Meal(
        name: 'Mixed Nuts',
        description: '${(15 * scale).round()} pieces of Mixed Nuts (Almonds, Walnuts)',
        calories: (200 * scale).round(),
        protein: 5 * scale,
        carbs: 8 * scale,
        fats: 18 * scale,
      ),
      Meal(
        name: 'Fruit Salad',
        description: '1 medium Apple or ${max(1, (1.5 * scale).round().toInt())} bowls Seasonal mixed fruits',
        calories: (150 * scale).round(),
        protein: 2 * scale,
        carbs: 35 * scale,
        fats: 0 * scale,
      ),
      if (!isVegan)
        Meal(
          name: 'Greek Yogurt',
          description: '${(200 * scale).round()}g Low fat yogurt with berries',
          calories: (180 * scale).round(),
          protein: 15 * scale,
          carbs: 15 * scale,
          fats: 5 * scale,
        ),
      Meal(
        name: 'Peanut Butter Toast',
        description: '1 slice Whole wheat toast with ${(20 * scale).round()}g natural peanut butter',
        calories: (250 * scale).round(),
        protein: 10 * scale,
        carbs: 25 * scale,
        fats: 14 * scale,
      ),
    ];

    List<Meal> dinnerOptions = [
      Meal(
        name: 'Vegetable Soup & Salad',
        description: '1 bowl Mixed veg soup with large green salad',
        calories: (300 * scale).round(),
        protein: 10 * scale,
        carbs: 40 * scale,
        fats: 8 * scale,
      ),
      if (!isVegan)
        Meal(
          name: 'Paneer Tikka Salad',
          description: '${(120 * scale).round()}g Grilled paneer cubes with lots of veggies',
          calories: (400 * scale).round(),
          protein: 22 * scale,
          carbs: 20 * scale,
          fats: 25 * scale,
        ),
      if (!isVeg)
        Meal(
          name: 'Grilled Fish',
          description: '${(150 * scale).round()}g Grilled fish with steamed broccoli',
          calories: (350 * scale).round(),
          protein: 35 * scale,
          carbs: 10 * scale,
          fats: 12 * scale,
      ),
      Meal(
        name: 'Lentil Soup (Moong Dal)',
        description: '1 bowl Light moong dal with ${max(1, (1 * scale).round())} roti',
        calories: (350 * scale).round(),
        protein: 16 * scale,
        carbs: 45 * scale,
        fats: 8 * scale,
      ),
    ];

    final random = Random();
    return DailyDietPlan(
      breakfast: [breakfastOptions[random.nextInt(breakfastOptions.length)]],
      lunch: [lunchOptions[random.nextInt(lunchOptions.length)]],
      snacks: [snackOptions[random.nextInt(snackOptions.length)]],
      dinner: [dinnerOptions[random.nextInt(dinnerOptions.length)]],
    );
  }

  static double calculateWaterGoal(DietProfile profile) {
    if (!profile.autoWater && profile.customWaterGoal != null) {
      return profile.customWaterGoal!;
    }
    // General rule: 35ml per kg of body weight
    return (profile.weight * 0.035); // in Liters
  }
}
