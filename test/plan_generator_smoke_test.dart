import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:workout_app/models/exercise_model.dart';
import 'package:workout_app/models/user_profile.dart';
import 'package:workout_app/services/planner/llm_plan_generator.dart';
import 'package:workout_app/services/planner/ml_plan_generator.dart';
import 'package:workout_app/services/planner/plan_generator_factory.dart';
import 'package:workout_app/services/planner/plan_generator_interface.dart';
import 'package:workout_app/services/planner/rule_based_plan_generator.dart';

const _dayWeekday = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7};

void main() {
  late List<WorkoutExercise> catalog;

  setUpAll(() {
    final raw = File('assets/exercises.json').readAsStringSync();
    final data = jsonDecode(raw) as List;
    catalog = data
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  const beginner = UserProfile(
    name: 'Test',
    goal: 'Build Muscle',
    experienceLevel: 'Beginner',
    equipment: 'None',
    timePerSession: '30 mins',
    injuries: [],
  );

  test('factory returns a working generator', () {
    final generator = PlanGeneratorFactory.getActivePlanGenerator();
    expect(generator, isA<RuleBasedPlanGenerator>());
  });

  test('main plan: 7 days, Sun rest, mixed groups, no consecutive Legs days',
      () async {
    final plan = await PlanGeneratorFactory.getActivePlanGenerator().generatePlan(
          profile: beginner,
          planType: PlanTypes.main,
          availableExercises: catalog,
        );
    expect(plan.days.length, 7);
    expect(plan.days.last.dayLabel, 'Sun');
    expect(plan.days.last.exercises, isEmpty);

    final workoutDays = plan.days.sublist(0, 6);
    for (final day in workoutDays) {
      expect(day.exercises, isNotEmpty,
          reason: '${day.dayLabel} should have exercises');
      expect(day.exercises.every((p) => p.reps > 0 && p.sets > 0), isTrue);
      // Each day must mix at least 2 distinct muscle groups (no one-track day).
      final groups = day.exercises.expand((p) => p.exercise.muscleGroup).toSet();
      expect(groups.length, greaterThanOrEqualTo(2),
          reason: '${day.dayLabel} is single-track');
    }

    for (var i = 0; i < workoutDays.length - 1; i++) {
      bool hasLegs(int idx) =>
          workoutDays[idx].exercises.any((p) => p.exercise.category == 'Legs');
      expect(hasLegs(i) && hasLegs(i + 1), isFalse,
          reason: 'Legs heavy on two consecutive days');
    }
  });

  test('filters use schema fields: injuryRisk, equipmentRequired, difficulty',
      () async {
    final profile = beginner.copyWith(
      goal: 'Get Fit',
      injuries: const ['Knee Pain'],
    );
    final plan = await RuleBasedPlanGenerator().generatePlan(
      profile: profile,
      planType: PlanTypes.main,
      availableExercises: catalog,
    );
    for (final day in plan.days.sublist(0, 6)) {
      for (final p in day.exercises) {
        expect(p.exercise.injuryRisk.contains('knee'), isFalse,
            reason: '${p.exercise.id} flagged knee but user has knee pain');
        expect(p.exercise.equipmentRequired, isFalse,
            reason: '${p.exercise.id} requires gear but user has none');
        expect(p.exercise.difficulty, 'beginner');
      }
    }
  });

  test('missed-day bonus: +1 per missed day on remaining days of current week',
      () async {
    final generator = RuleBasedPlanGenerator();
    generator.markDayMissed();
    generator.markDayMissed();

    final plan = await generator.generatePlan(
      profile: beginner,
      planType: PlanTypes.main,
      availableExercises: catalog,
    );

    final todayWeekday = DateTime.now().weekday;
    for (final day in plan.days) {
      final isRemaining = (_dayWeekday[day.dayLabel] ?? 7) >= todayWeekday;
      for (final p in day.exercises) {
        if (isRemaining) {
          expect(p.sets, greaterThanOrEqualTo(p.exercise.defaultSets + 1));
          expect(p.reps, greaterThanOrEqualTo(p.exercise.defaultReps + 1));
        }
      }
    }
  });

  test('bonus is capped at +3', () async {
    final generator = RuleBasedPlanGenerator();
    for (var i = 0; i < 10; i++) {
      generator.markDayMissed();
    }

    final plan = await generator.generatePlan(
      profile: beginner,
      planType: PlanTypes.main,
      availableExercises: catalog,
    );

    final todayWeekday = DateTime.now().weekday;
    for (final day in plan.days) {
      final isRemaining = (_dayWeekday[day.dayLabel] ?? 7) >= todayWeekday;
      if (!isRemaining) continue;
      for (final p in day.exercises) {
        expect(p.sets, lessThanOrEqualTo(p.exercise.defaultSets + 3));
        expect(p.reps, lessThanOrEqualTo(p.exercise.defaultReps + 3));
      }
    }
  });

  test('fixed plans do NOT get any missed-day bonus', () async {
    final generator = RuleBasedPlanGenerator();
    generator.markDayMissed();
    for (final type in [
      PlanTypes.stretching,
      PlanTypes.fullBody,
      PlanTypes.armsOnly,
    ]) {
      final plan = await generator.generatePlan(
        profile: beginner,
        planType: type,
        availableExercises: catalog,
      );
      for (final day in plan.days.sublist(0, 6)) {
        expect(day.exercises, isNotEmpty, reason: '$type ${day.dayLabel} empty');
        for (final p in day.exercises) {
          expect(p.sets, p.exercise.defaultSets);
          expect(p.reps, p.exercise.defaultReps);
        }
      }
    }
  });

  test('LLM and ML placeholders throw UnimplementedError', () async {
    final llm = LlmPlanGenerator();
    final ml = MlPlanGenerator();
    await expectLater(
      () => llm.generatePlan(
          profile: beginner, planType: PlanTypes.main, availableExercises: catalog),
      throwsUnimplementedError,
    );
    await expectLater(
      () => ml.generatePlan(
          profile: beginner, planType: PlanTypes.main, availableExercises: catalog),
      throwsUnimplementedError,
    );
  });
}