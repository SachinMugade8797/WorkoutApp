import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _planKey = 'workout_plan';
  static const String _streakKey = 'user_streak';
  static const String _lastWorkoutDateKey = 'last_workout_date';
  static const String _caloriesKey = 'total_calories';
  static const String _minutesKey = 'total_minutes';
  static const String _userNameKey = 'user_name';
  static const String _goalKey = 'user_goal';
  static const String _weeklyBurnKey = 'weekly_burn';
  static const String _missedExercisesKey = 'missed_exercises';
  static const String _completedDatesKey = 'completed_dates';
  static const String _currentWorkoutIndexKey = 'current_workout_index';
  static const String _activeWorkoutIdsKey = 'active_workout_ids';
  static const String _isWorkoutActiveKey = 'is_workout_active';
  static const String _userLevelKey = 'user_level';
  static const String _isMetricKey = 'settings_is_metric';
  static const String _isDarkModeKey = 'settings_is_dark_mode';
  static const String _isReminderOnKey = 'settings_is_reminder_on';
  static const String _onboardingCompleteKey = 'hasCompletedOnboarding';
  static const String _gDriveBackupKey = 'settings_google_drive_backup';
  static const String _subscriptionKey = 'subscription_active';

  static Future<void> savePlan(Map<String, List<String>> plan, String name, String goal, int weeklyBurn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, jsonEncode(plan));
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_goalKey, goal);
    await prefs.setInt(_weeklyBurnKey, weeklyBurn);
  }

  static Future<void> saveUserProfile(String name, String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_goalKey, goal);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_goalKey);
  }

  static Future<int> getWeeklyBurn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_weeklyBurnKey) ?? 0;
  }

  static Future<Map<String, List<String>>?> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_planKey);
    if (data == null) return null;
    final Map<String, dynamic> decoded = jsonDecode(data);
    return decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  static Future<void> saveWorkoutProgress(int calories, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCals = prefs.getInt(_caloriesKey) ?? 0;
    final currentMins = prefs.getInt(_minutesKey) ?? 0;
    await prefs.setInt(_caloriesKey, currentCals + calories);
    await prefs.setInt(_minutesKey, currentMins + minutes);
    
    // Mark today as completed
    List<String> completedDates = prefs.getStringList(_completedDatesKey) ?? [];
    String today = DateTime.now().toIso8601String().split('T')[0];
    if (!completedDates.contains(today)) {
      completedDates.add(today);
      await prefs.setStringList(_completedDatesKey, completedDates);
    }
  }

  static Future<List<String>> getCompletedDates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedDatesKey) ?? [];
  }

  static Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastWorkoutDateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int currentStreak = prefs.getInt(_streakKey) ?? 0;

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        currentStreak = 1;
      }
      // If difference == 0 (already worked out today), do nothing
    } else {
      currentStreak = 1;
    }

    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setString(_lastWorkoutDateKey, today.toIso8601String());
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  static Future<int> getTotalCalories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_caloriesKey) ?? 0;
  }

  static Future<int> getTotalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minutesKey) ?? 0;
  }

  static Future<void> saveInterruptedWorkout(List<String> remainingIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_missedExercisesKey, remainingIds);
  }

  static Future<List<String>> getMissedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_missedExercisesKey) ?? [];
  }

  static Future<void> clearMissedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_missedExercisesKey);
    await prefs.remove(_currentWorkoutIndexKey);
    await prefs.remove(_activeWorkoutIdsKey);
    await prefs.setBool(_isWorkoutActiveKey, false);
  }

  static Future<void> saveCurrentWorkoutIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentWorkoutIndexKey, index);
  }

  static Future<int> getCurrentWorkoutIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentWorkoutIndexKey) ?? 0;
  }

  static Future<void> saveActiveWorkoutIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_activeWorkoutIdsKey, ids);
    await prefs.setBool(_isWorkoutActiveKey, true);
  }

  static Future<List<String>> getActiveWorkoutIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_activeWorkoutIdsKey) ?? [];
  }

  static Future<void> setIsWorkoutActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isWorkoutActiveKey, value);
  }

  static Future<bool> isWorkoutActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isWorkoutActiveKey) ?? false;
  }

  static Future<String> getUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userLevelKey) ?? 'Beginner';
  }

  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
    await prefs.remove(_weeklyBurnKey);
    await prefs.remove(_activeWorkoutIdsKey);
    await prefs.remove(_isWorkoutActiveKey);
    await prefs.remove(_currentWorkoutIndexKey);
    await prefs.remove(_missedExercisesKey);
  }

  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_caloriesKey);
    await prefs.remove(_minutesKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_lastWorkoutDateKey);
    await prefs.remove(_completedDatesKey);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Settings Methods
  static Future<void> saveMetricUnit(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isMetricKey, value);
  }

  static Future<bool> getMetricUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isMetricKey) ?? true;
  }

  static Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, value);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDarkModeKey) ?? false;
  }

  static Future<void> saveReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isReminderOnKey, value);
  }

  static Future<bool> getReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isReminderOnKey) ?? true;
  }

  // Onboarding flag
  static Future<bool> getOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    // Fall back to the legacy key used by the old single-screen onboarding,
    // so users who already onboarded don't get asked again.
    return prefs.getBool(_onboardingCompleteKey) ??
        prefs.getBool('isOnboardingComplete') ??
        false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, value);
  }

  // Backup to Google Drive (free tier) — value is persisted, integration is a stub
  static Future<bool> getGoogleDriveBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gDriveBackupKey) ?? false;
  }

  static Future<void> setGoogleDriveBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gDriveBackupKey, value);
  }

  // Cloud Sync subscription check.
  // STUB: Always returns false until real billing/entitlement logic is added.
  static Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_subscriptionKey) ?? false;
  }

  static Future<void> setSubscribed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionKey, value);
  }

  // Clears every piece of locally stored user data (profile lives in the DB
  // and is cleared separately by UserProfileRepository.deleteProfile()).
  static Future<void> clearAllUserData() async {
    await clearAllProgress();
    await clearPlan();
    await clearMissedExercises();
  }
}
