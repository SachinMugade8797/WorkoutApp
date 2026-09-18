import 'dart:math';

import '../../models/exercise_model.dart';
import '../../models/user_profile.dart';
import 'plan_generator_interface.dart';
import 'plan_models.dart';

/// Default (and currently only) [PlanGeneratorInterface] implementation.
///
/// Generates plans purely from rule-based heuristics:
///  - filters the catalog by the `injuryRisk`, `equipmentRequired`,
///    `difficulty` and `muscleGroup` fields of `assets/exercises.json`
///  - builds multi-muscle-group days (no single-track "Legs only" days) that
///    rotate so heavy groups (especially Legs) get rest between sessions
///  - applies the weekly missed-day bonus on the main plan only
///
/// A future LLM / ML generator would implement the same interface and would be
/// returned instead from [PlanGeneratorFactory]. See
/// `llm_plan_generator.dart` / `ml_plan_generator.dart`.
class RuleBasedPlanGenerator implements PlanGeneratorInterface {
  /// 6 rotating day templates, each mixing 2-3 muscle groups. Legs never
  /// appears on two consecutive days so it recovers between heavy sessions.
  static const List<List<String>> _dayRotation = [
    ['Chest', 'Arms', 'Abs'],
    ['Legs', 'Back', 'Abs'],
    ['Back', 'Arms', 'Abs'],
    ['Legs', 'Chest', 'Abs'],
    ['Arms', 'Back', 'Abs'],
    ['Legs', 'Chest', 'Arms'],
  ];

  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const String _restDayLabel = 'Sun';

  static const int _maxMissedDayBonus = 3;

  /// Share of a daily session biased toward the user's focus area.
  static const double _focusShare = 0.35;

  // -------------------------------------------------------------------------
  // Weekly missed-day bonus state (main plan only).
  // -------------------------------------------------------------------------

  int _weeklyMissedDayCount = 0;
  int? _bonusWeekKey;

  /// Records one missed workout day in the current calendar week. Each call
  /// grants +1 (capped at +3 total) sets/reps to every exercise on the
  /// remaining days of the week. Counters reset automatically each Monday.
  void markDayMissed() {
    _refreshWeek();
    if (_weeklyMissedDayCount < _maxMissedDayBonus) {
      _weeklyMissedDayCount++;
    }
  }

  void _refreshWeek() {
    final key = _weekKey(DateTime.now());
    if (_bonusWeekKey == null || _bonusWeekKey != key) {
      _bonusWeekKey = key;
      _weeklyMissedDayCount = 0;
    }
  }

  /// Stable key for the Monday-based calendar week containing [date].
  static int weekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    return monday.year * 1000 + monday.difference(DateTime(monday.year, 1, 1)).inDays;
  }

  static int _weekKey(DateTime date) => weekKey(date);

  // -------------------------------------------------------------------------
  // PlanGeneratorInterface
  // -------------------------------------------------------------------------

  @override
  Future<WeeklyPlan> generatePlan({
    required UserProfile profile,
    required String planType,
    required List<WorkoutExercise> availableExercises,
  }) async {
    _refreshWeek();

    if (isMainPlanType(planType)) {
      return _generateMainPlan(profile, planType, availableExercises);
    }
    return _generateFixedPlan(planType, profile, availableExercises);
  }

  /// True for the personalized plan (the only type eligible for the missed-day
  /// bonus). A `main:<focusSlug>` suffix still counts as the main plan.
  static bool isMainPlanType(String planType) =>
      planType == PlanTypes.main || planType.startsWith('${PlanTypes.main}:');

  static String? _focusSlugFrom(String planType) {
    const prefix = '${PlanTypes.main}:';
    return planType.startsWith(prefix) ? planType.substring(prefix.length) : null;
  }

  // -------------------------------------------------------------------------
  // Catalog filtering (new exercises.json schema fields).
  // -------------------------------------------------------------------------

  /// Applies injury, equipment and difficulty filtering to the catalog.
  List<WorkoutExercise> _filterBase(UserProfile profile, List<WorkoutExercise> catalog) =>
      catalog.where(_passesInjury(profile)).where(_passesEquipment(profile)).where(_passesDifficulty(profile)).toList();

  bool Function(WorkoutExercise) _passesInjury(UserProfile profile) {
    final injuries = profile.injuries ?? const <String>[];
    final riskTokens = injuries
        .map(_riskTokenFor)
        .where((t) => t != null)
        .cast<String>()
        .toList();
    return (ex) => riskTokens.every((token) => !ex.injuryRisk.contains(token));
  }

  /// Maps a user-facing injury name to the risk token used in `injuryRisk`.
  static String? _riskTokenFor(String injury) {
    switch (injury) {
      case 'Knee Pain':
        return 'knee';
      case 'Back Pain':
        return 'back';
      default:
        return null;
    }
  }

  bool Function(WorkoutExercise) _passesEquipment(UserProfile profile) {
    final equipment = profile.equipment;
    if (equipment == null || equipment == 'None') {
      return (ex) => !ex.equipmentRequired;
    }
    if (equipment == 'Dumbbells Only') {
      return (ex) =>
          !ex.equipmentRequired ||
          ex.equipment == 'Dumbbells' ||
          ex.equipment == 'Chair/Bench';
    }
    return (_) => true; // Full Gym / unknown -> everything is fair game
  }

  bool Function(WorkoutExercise) _passesDifficulty(UserProfile profile) {
    final allowed = switch (profile.experienceLevel) {
      'Intermediate' => const {'beginner', 'intermediate'},
      'Advanced' => const {'beginner', 'intermediate', 'advanced'},
      _ => const {'beginner'}, // Beginner / unspecified
    };
    return (ex) => allowed.contains(ex.difficulty);
  }

  /// Goal-based priority ordering applied within each day's pool.
  void _applyGoalPriority(List<WorkoutExercise> pool, String? goal) {
    if (goal == 'Lose Weight') {
      pool.sort((a, b) {
        final aHigh = a.caloriesPerMinute >= 7.5;
        final bHigh = b.caloriesPerMinute >= 7.5;
        if (aHigh && !bHigh) return -1;
        if (!aHigh && bHigh) return 1;
        return b.caloriesPerMinute.compareTo(a.caloriesPerMinute);
      });
    } else if (goal == 'Build Muscle') {
      pool.sort((a, b) {
        final aStrength = a.equipmentRequired || a.category == 'Chest' || a.category == 'Back';
        final bStrength = b.equipmentRequired || b.category == 'Chest' || b.category == 'Back';
        if (aStrength && !bStrength) return -1;
        if (!aStrength && bStrength) return 1;
        return 0;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Main (personalized) plan.
  // -------------------------------------------------------------------------

  WeeklyPlan _generateMainPlan(UserProfile profile, String planType, List<WorkoutExercise> availableExercises) {
    final random = Random();
    final base = _filterBase(profile, availableExercises);
    final focusCategories = _focusCategoriesFor(_focusSlugFrom(planType));
    final exercisesPerDay = _exercisesPerDay(profile.experienceLevel);

    final usedInWeek = <String>{};
    final days = <DayPlan>[];
    final todayWeekday = DateTime.now().weekday;
    final bonus = min(_weeklyMissedDayCount, _maxMissedDayBonus);

    for (var i = 0; i < _dayRotation.length; i++) {
      final label = _dayLabels[i];
      final template = _dayRotation[i];

      final pool = base.where((ex) => _matchesTemplate(ex, template)).toList();
      if (pool.isEmpty) pool.addAll(base);
      _applyGoalPriority(pool, profile.goal);

      List<WorkoutExercise> focusPool = pool;
      List<WorkoutExercise> varietyPool = <WorkoutExercise>[];
      if (focusCategories.isNotEmpty) {
        focusPool = pool.where((ex) => _matchesFocus(ex, focusCategories)).toList();
        varietyPool = pool.where((ex) => !_matchesFocus(ex, focusCategories)).toList();
      }
      focusPool.shuffle(random);
      varietyPool.shuffle(random);

      final selection = <WorkoutExercise>[];
      final focusCount = (exercisesPerDay * _focusShare).round().clamp(0, exercisesPerDay);
      _pickFromPool(focusPool, focusCount, selection, usedInWeek, random);
      _pickFromPool(varietyPool, exercisesPerDay - selection.length, selection, usedInWeek, random);

      // Missed-day bonus only reaches the days still ahead in the current week.
      final dayBonus = _isRemainingDay(label, todayWeekday) ? bonus : 0;

      days.add(DayPlan(
        dayLabel: label,
        exercises: selection
            .map((ex) => PlannedExercise(
                  exercise: ex,
                  sets: ex.defaultSets + dayBonus,
                  reps: ex.defaultReps + dayBonus,
                ))
            .toList(),
      ));
    }

    days.add(const DayPlan(dayLabel: _restDayLabel, exercises: []));
    return WeeklyPlan(days: days);
  }

  int _exercisesPerDay(String? level) {
    switch (level) {
      case 'Intermediate':
        return 6;
      case 'Advanced':
        return 8;
      default:
        return 5;
    }
  }

  bool _matchesTemplate(WorkoutExercise ex, List<String> template) =>
      template.contains(ex.category) || ex.muscleGroup.any(template.contains);

  /// Exercises count toward the focus area when their category or any
  /// muscleGroup matches the user's chosen focus.
  bool _matchesFocus(WorkoutExercise ex, Set<String> focus) =>
      focus.contains(ex.category) || ex.muscleGroup.any(focus.contains);

  static Set<String> _focusCategoriesFor(String? slug) {
    switch (slug) {
      case 'chest_arms':
        return const {'Chest', 'Arms', 'Triceps', 'Biceps', 'Shoulders', 'Forearms'};
      case 'legs_glutes':
        return const {'Legs', 'Quads', 'Hamstrings', 'Glutes', 'Calves', 'Hip Flexors'};
      case 'core_abs':
        return const {'Abs', 'Core', 'Obliques', 'Hip Flexors'};
      default:
        return const {};
    }
  }

  bool _isRemainingDay(String label, int todayWeekday) {
    const labelWeekday = {
      'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7,
    };
    return (labelWeekday[label] ?? 7) >= todayWeekday;
  }

  /// Picks up to [count] exercises from [pool] without repeating one used
  /// earlier in the week (falling back to repeats across days when needed),
  /// and never duplicating an exercise twice on the same day.
  void _pickFromPool(
    List<WorkoutExercise> pool,
    int count,
    List<WorkoutExercise> selection,
    Set<String> usedInWeek,
    Random random,
  ) {
    var picked = 0;
    for (final ex in pool) {
      if (picked >= count) break;
      if (!usedInWeek.contains(ex.id) && !selection.any((e) => e.id == ex.id)) {
        selection.add(ex);
        usedInWeek.add(ex.id);
        picked++;
      }
    }
    if (picked < count) {
      for (final ex in pool) {
        if (picked >= count) break;
        if (!selection.any((e) => e.id == ex.id)) {
          selection.add(ex);
          picked++;
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Fixed plans (stretching / full body / arms only). No missed-day bonus.
  // -------------------------------------------------------------------------

  WeeklyPlan _generateFixedPlan(String planType, UserProfile profile, List<WorkoutExercise> availableExercises) {
    final random = Random();
    final base = _filterBase(profile, availableExercises);

    List<WorkoutExercise> pool;
    switch (planType) {
      case PlanTypes.armsOnly:
        pool = base
            .where((ex) =>
                ex.category == 'Arms' ||
                ex.muscleGroup.any(const {'Biceps', 'Triceps', 'Forearms'}.contains))
            .toList();
        break;
      case PlanTypes.stretching:
        pool = base.where((ex) => ex.caloriesPerMinute < 5).toList();
        break;
      case PlanTypes.fullBody:
        pool = base;
        break;
      default:
        pool = base;
    }

    final exercisesPerDay = _exercisesPerDay(profile.experienceLevel);
    final usedInWeek = <String>{};
    final days = <DayPlan>[];

    for (var i = 0; i < _dayLabels.length; i++) {
      final selection = <WorkoutExercise>[];
      if (pool.isNotEmpty) {
        _pickFromPool(pool, exercisesPerDay, selection, usedInWeek, random);
        if (selection.isEmpty) {
          selection.addAll(pool.take(exercisesPerDay));
        }
      }
      days.add(DayPlan(
        dayLabel: _dayLabels[i],
        exercises: selection
            .map((ex) => PlannedExercise(exercise: ex, sets: ex.defaultSets, reps: ex.defaultReps))
            .toList(),
      ));
    }

    days.add(const DayPlan(dayLabel: _restDayLabel, exercises: []));
    return WeeklyPlan(days: days);
  }
}