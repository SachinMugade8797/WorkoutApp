import 'dart:convert';
import 'package:flutter/services.dart';

class WorkoutExercise {
  final String id;
  final String name;
  final String category;
  final List<String> muscleGroup;
  final String equipment;
  final bool equipmentRequired;
  final String difficulty;
  final int defaultSets;
  final int defaultReps;
  final double caloriesPerMinute;
  final List<String> injuryRisk;
  final String description;
  final Map<String, String> gifPaths;
  final List<String> tags;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.equipmentRequired,
    required this.difficulty,
    required this.defaultSets,
    required this.defaultReps,
    required this.caloriesPerMinute,
    required this.injuryRisk,
    required this.description,
    required this.gifPaths,
    required this.tags,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      muscleGroup: List<String>.from(json['muscleGroup'] as List),
      equipment: json['equipment'] as String,
      equipmentRequired: json['equipmentRequired'] as bool,
      difficulty: json['difficulty'] as String,
      defaultSets: json['defaultSets'] as int,
      defaultReps: json['defaultReps'] as int,
      caloriesPerMinute: (json['caloriesPerMinute'] as num).toDouble(),
      injuryRisk: List<String>.from(json['injuryRisk'] as List),
      description: json['description'] as String,
      gifPaths: Map<String, String>.from(json['gifPaths'] as Map),
      tags: List<String>.from(json['tags'] as List),
    );
  }

  String getGifPath(String gender) {
    return gifPaths[gender] ?? gifPaths['male'] ?? '';
  }
}

Future<List<WorkoutExercise>> loadExercises() async {
  final jsonStr = await rootBundle.loadString('assets/exercises.json');
  final List data = json.decode(jsonStr);
  return data
      .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
      .toList();
}
