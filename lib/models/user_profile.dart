import 'dart:convert';

/// The user's fitness profile.
///
/// All fields are nullable because the profile is built up step-by-step
/// during onboarding, and most steps can be skipped. A field is only "filled"
/// once the user has actually provided a value.
class UserProfile {
  final String? name;
  final int? age;
  final String? gender;
  final double? height; // cm
  final double? weight; // kg
  final String? goal;
  final String? experienceLevel;
  final String? equipment;
  final String? workoutLocation;
  final String? timePerSession;
  final List<String>? injuries;

  const UserProfile({
    this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.goal,
    this.experienceLevel,
    this.equipment,
    this.workoutLocation,
    this.timePerSession,
    this.injuries,
  });

  /// Every field the profile can hold. Used by `getMissingFields()`.
  static const List<String> allFieldKeys = [
    'name',
    'age',
    'gender',
    'height',
    'weight',
    'goal',
    'experienceLevel',
    'equipment',
    'workoutLocation',
    'timePerSession',
    'injuries',
  ];

  /// Which fields are filled vs missing.
  ///
  /// Auto-derived from the profile itself — never stored separately.
  /// `injuries` counts as filled once answered (an empty list means "no injuries").
  Map<String, bool> get profileCompletionMap => {
        'name': name != null && name!.isNotEmpty,
        'age': age != null,
        'gender': gender != null && gender!.isNotEmpty,
        'height': height != null,
        'weight': weight != null,
        'goal': goal != null && goal!.isNotEmpty,
        'experienceLevel': experienceLevel != null && experienceLevel!.isNotEmpty,
        'equipment': equipment != null && equipment!.isNotEmpty,
        'workoutLocation': workoutLocation != null && workoutLocation!.isNotEmpty,
        'timePerSession': timePerSession != null && timePerSession!.isNotEmpty,
        'injuries': injuries != null,
      };

  /// 0.0 -> 1.0 percentage of profile completion.
  double get completionPercentage {
    final map = profileCompletionMap;
    final filled = map.values.where((v) => v).length;
    return filled / map.length;
  }

  /// Map needed to store this profile as a row in the `user_profile` table.
  /// `injuries` is JSON-encoded as a string so SQLite can hold it.
  Map<String, Object?> toDbMap() => {
        'id': 1,
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'goal': goal,
        'experience_level': experienceLevel,
        'equipment': equipment,
        'workout_location': workoutLocation,
        'time_per_session': timePerSession,
        'injuries': injuries == null ? null : jsonEncode(injuries),
      };

  factory UserProfile.fromDbMap(Map<String, Object?> map) => UserProfile(
        name: map['name'] as String?,
        age: map['age'] as int?,
        gender: map['gender'] as String?,
        height: (map['height'] as num?)?.toDouble(),
        weight: (map['weight'] as num?)?.toDouble(),
        goal: map['goal'] as String?,
        experienceLevel: map['experience_level'] as String?,
        equipment: map['equipment'] as String?,
        workoutLocation: map['workout_location'] as String?,
        timePerSession: map['time_per_session'] as String?,
        injuries: map['injuries'] == null
            ? null
            : (jsonDecode(map['injuries'] as String) as List).cast<String>(),
      );

  /// Returns a copy with the given non-null fields replaced.
  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? goal,
    String? experienceLevel,
    String? equipment,
    String? workoutLocation,
    String? timePerSession,
    List<String>? injuries,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      equipment: equipment ?? this.equipment,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      timePerSession: timePerSession ?? this.timePerSession,
      injuries: injuries ?? this.injuries,
    );
  }
}