import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../repositories/user_profile_repository.dart';
import '../services/storage_service.dart';

/// ---------------------------------------------------------------------------
/// Range options
/// ---------------------------------------------------------------------------

/// A time window applied to *every* section of the report at once, so the
/// cards, the calendar and the chart can never describe different periods.
class ReportRange {
  final String label;
  final String description;

  /// Length in days, or `null` for all recorded history.
  final int? days;

  const ReportRange(this.label, this.description, this.days);
}

const List<ReportRange> kReportRanges = [
  ReportRange('7D', 'Last 7 days', 7),
  ReportRange('30D', 'Last 30 days', 30),
  ReportRange('90D', 'Last 90 days', 90),
  ReportRange('ALL', 'All time', null),
];

/// ---------------------------------------------------------------------------
/// Snapshot
/// ---------------------------------------------------------------------------

/// Everything the report renders, read from `workout_history` in one pass.
class ReportSnapshot {
  final int calories;
  final int minutes;
  final int sessions;
  final int currentStreak;
  final int bestStreak;

  /// `yyyy-MM-dd` days with at least one session inside the selected range.
  final Set<String> activeDates;

  /// `yyyy-MM-dd` -> calories, inside the selected range.
  final Map<String, int> dailyCalories;

  /// Total across all history, regardless of the selected range.
  final int allTimeCalories;

  /// Oldest session ever recorded, or `null` if there is no history. Used to
  /// size the chart so the ALL range really does span the whole history.
  final String? earliestSession;

  /// Days trained in the current Mon-Sun week, independent of [ReportRange].
  final int weeklyCompleted;

  const ReportSnapshot({
    required this.calories,
    required this.minutes,
    required this.sessions,
    required this.currentStreak,
    required this.bestStreak,
    required this.activeDates,
    required this.dailyCalories,
    required this.allTimeCalories,
    required this.earliestSession,
    required this.weeklyCompleted,
  });

  static const empty = ReportSnapshot(
    calories: 0,
    minutes: 0,
    sessions: 0,
    currentStreak: 0,
    bestStreak: 0,
    activeDates: <String>{},
    dailyCalories: <String, int>{},
    allTimeCalories: 0,
    earliestSession: null,
    weeklyCompleted: 0,
  );
}

/// Every progress figure the home screen, planner, dashboard and report all
/// display, read from `workout_history` in one place.
///
/// Having a single reader means the home screen and the report can never show
/// different numbers for the same thing.
class ProgressSummary {
  final int streak;
  final int bestStreak;
  final int calories;
  final int minutes;
  final int sessions;

  /// Days trained inside the current Mon-Sun week.
  final int weeklyCompleted;
  final int weeklyGoal;

  /// Every day ever trained, newest first.
  final List<String> activeDates;

  /// Calories per day for the current week only.
  final Map<String, int> weeklyCalories;

  const ProgressSummary({
    required this.streak,
    required this.bestStreak,
    required this.calories,
    required this.minutes,
    required this.sessions,
    required this.weeklyCompleted,
    required this.weeklyGoal,
    required this.activeDates,
    required this.weeklyCalories,
  });

  static const empty = ProgressSummary(
    streak: 0,
    bestStreak: 0,
    calories: 0,
    minutes: 0,
    sessions: 0,
    weeklyCompleted: 0,
    weeklyGoal: kWeeklySessionGoal,
    activeDates: <String>[],
    weeklyCalories: <String, int>{},
  );
}

/// Workouts per week the app aims for. Mirrors the home screen's week strip.
const int kWeeklySessionGoal = 6;

/// One bar in the activity chart: either a single day or a Mon-Sun week.
class ChartBucket {
  final DateTime start;
  final DateTime end;
  final int calories;

  const ChartBucket(this.start, this.end, this.calories);
}

// ---------------------------------------------------------------------------
// Data access
// ---------------------------------------------------------------------------

/// Reads and writes the `workout_history` table that backs the report.
///
/// Self-contained on purpose: everything the report needs from the database
/// lives in this file. It borrows the already-open connection (and therefore
/// the schema and migrations) from [UserProfileRepository] rather than opening
/// a second handle on `fitforge.db` or duplicating the table definition.
class ReportDataSource {
  static const String _table = 'workout_history';

  /// Bumped whenever history is written or cleared.
  ///
  /// The report tab lives inside a persistent `IndexedStack`, so its
  /// `initState` runs exactly once and tab switches never rebuild it. This is
  /// how it learns to re-query after a workout finishes.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Marks the one-time import of pre-database progress.
  static const String _backfillFlag = 'report_backfill_v1';

  // -- writes ---------------------------------------------------------------

  /// Records one finished (or stopped) session.
  ///
  /// This is the only writer of progress in the app, so it is also what makes
  /// the history permanent: the row lives in SQLite and survives restarts,
  /// app updates and reinstall-over-adb. It is removed only by an explicit
  /// "clear my data" action or by uninstalling.
  ///
  /// Sessions that burned nothing and lasted no time are dropped, so opening
  /// the player and bailing out cannot add a phantom day to the calendar.
  ///
  /// Retries once, because a transient SQLITE_BUSY must not cost the user
  /// their session.
  static Future<void> recordSession({
    required int calories,
    required int minutes,
    required int exerciseCount,
    String? planKey,
    DateTime? when,
  }) async {
    if (calories <= 0 && minutes <= 0) return;

    final values = {
      'date': formatDay(when ?? DateTime.now()),
      'duration_minutes': minutes,
      'calories_burned': calories,
      'exercise_count': exerciseCount,
      'plan_key': planKey,
    };

    final db = await UserProfileRepository.getDatabase();
    try {
      await db.insert(_table, values);
    } on DatabaseException {
      await db.insert(_table, values);
    }
    revision.value++;
  }

  /// Deletes every session. Keeps the all-time calorie total in sync.
  static Future<void> clearHistory() async {
    final db = await UserProfileRepository.getDatabase();
    await db.delete(_table);
    revision.value++;
  }

  /// One-time import of progress earned before the report used the database.
  ///
  /// That data only ever existed as SharedPreferences counters: a lifetime
  /// calorie/minute total plus the list of days the user trained. Per-day
  /// figures were never stored, so the totals are spread evenly across the
  /// recorded days. The totals and the activity calendar end up exactly right;
  /// only the height of an individual legacy bar in the chart is an estimate.
  /// Anything recorded from now on is exact.
  ///
  /// No-op once the flag is set, and skipped entirely if the table already
  /// holds sessions, so it can never double-count.
  static Future<bool> backfillLegacyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_backfillFlag) == true) return false;

    final db = await UserProfileRepository.getDatabase();
    final count = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    if ((count.first['c'] as int? ?? 0) > 0) {
      await prefs.setBool(_backfillFlag, true);
      return false;
    }

    final totalCalories = await StorageService.getTotalCalories();
    final totalMinutes = await StorageService.getTotalMinutes();
    final trainedDays = await StorageService.getCompletedDates();

    if (trainedDays.isEmpty || (totalCalories == 0 && totalMinutes == 0)) {
      // Nothing worth carrying over, but stop checking on every launch.
      await prefs.setBool(_backfillFlag, true);
      return false;
    }

    final dayCount = trainedDays.length;
    final perDayCalories = (totalCalories / dayCount).round();
    final perDayMinutes = (totalMinutes / dayCount).round();
    var caloriesLeft = totalCalories;
    var minutesLeft = totalMinutes;

    final batch = db.batch();
    for (var i = 0; i < dayCount; i++) {
      // The last row absorbs the rounding remainder so the totals round-trip.
      final isLast = i == dayCount - 1;
      final dayCalories = isLast ? caloriesLeft : perDayCalories;
      final dayMinutes = isLast ? minutesLeft : perDayMinutes;
      caloriesLeft -= dayCalories;
      minutesLeft -= dayMinutes;
      batch.insert(_table, {
        'date': trainedDays[i],
        'duration_minutes': dayMinutes,
        'calories_burned': dayCalories,
        'exercise_count': 0,
        'plan_key': null,
      });
    }
    await batch.commit(noResult: true);

    await prefs.setBool(_backfillFlag, true);
    revision.value++;
    return true;
  }

  // -- reads ----------------------------------------------------------------

  /// Reads every figure the report needs for [range] in a single round trip.
  static Future<ReportSnapshot> load(ReportRange range) async {
    final db = await UserProfileRepository.getDatabase();
    final now = DateTime.now();
    final today = dateOnly(now);
    final from = range.days == null
        ? DateTime(2000, 1, 1)
        : today.subtract(Duration(days: range.days! - 1));
    final fromKey = formatDay(from);
    final toKey = formatDay(today);

    // Totals + per-day burn for the selected range, and the per-day split in
    // one pass each. Session rows are the source of truth, so a day can hold
    // several sessions and still be counted once in the calendar.
    final totalsRows = await db.rawQuery(
      '''
      SELECT
        IFNULL(SUM(calories_burned), 0) AS calories,
        IFNULL(SUM(duration_minutes), 0) AS minutes,
        COUNT(*) AS sessions,
        COUNT(DISTINCT date) AS days
      FROM $_table
      WHERE date BETWEEN ? AND ?
      ''',
      [fromKey, toKey],
    );

    final dailyRows = await db.rawQuery(
      '''
      SELECT date, SUM(calories_burned) AS cals
      FROM $_table
      WHERE date BETWEEN ? AND ?
      GROUP BY date
      ''',
      [fromKey, toKey],
    );

    final allTimeRows = await db.rawQuery(
      'SELECT IFNULL(SUM(calories_burned), 0) AS cals, MIN(date) AS first FROM $_table',
    );

    // Every active day ever, needed for the streak (independent of range).
    final streakRows = await db.rawQuery(
      'SELECT DISTINCT date FROM $_table ORDER BY date DESC',
    );

    // Days trained this week, also independent of the selected range, so the
    // week-goal strip matches the home screen whatever range is active.
    final weekRows = await db.rawQuery(
      'SELECT COUNT(DISTINCT date) AS days FROM $_table WHERE date BETWEEN ? AND ?',
      [formatDay(ReportDataSource.daysOfWeekContaining(now).first), toKey],
    );

    final daily = <String, int>{
      for (final row in dailyRows) row['date'] as String: _asInt(row['cals']),
    };
    final allActiveDays = streakRows.map((r) => r['date'] as String).toList();

    final totals = totalsRows.first;
    return ReportSnapshot(
      calories: _asInt(totals['calories']),
      minutes: _asInt(totals['minutes']),
      sessions: _asInt(totals['sessions']),
      currentStreak: _currentStreak(allActiveDays, today),
      bestStreak: _bestStreak(allActiveDays),
      activeDates: daily.keys.toSet(),
      dailyCalories: daily,
      allTimeCalories: _asInt(allTimeRows.first['cals']),
      earliestSession: allTimeRows.first['first'] as String?,
      weeklyCompleted: _asInt(weekRows.first['days']),
    );
  }

  /// Reads the headline progress figures in two queries: everything ever
  /// recorded, plus the current Mon-Sun week.
  ///
  /// This is what the home screen, planner and dashboard render, so all of
  /// them agree with the report by construction.
  static Future<ProgressSummary> loadSummary() async {
    final db = await UserProfileRepository.getDatabase();
    final now = DateTime.now();
    final today = dateOnly(now);
    final toKey = formatDay(today);
    final weekStartKey = formatDay(daysOfWeekContaining(now).first);

    final allTime = await db.rawQuery(
      '''
      SELECT
        IFNULL(SUM(calories_burned), 0) AS calories,
        IFNULL(SUM(duration_minutes), 0) AS minutes,
        COUNT(*) AS sessions
      FROM $_table
      ''',
    );

    final thisWeek = await db.rawQuery(
      '''
      SELECT
        IFNULL(SUM(calories_burned), 0) AS calories,
        COUNT(DISTINCT date) AS days
      FROM $_table
      WHERE date BETWEEN ? AND ?
      ''',
      [weekStartKey, toKey],
    );

    final weekDaily = await db.rawQuery(
      '''
      SELECT date, SUM(calories_burned) AS cals
      FROM $_table
      WHERE date BETWEEN ? AND ?
      GROUP BY date
      ''',
      [weekStartKey, toKey],
    );

    final activeRows = await db.rawQuery(
      'SELECT DISTINCT date FROM $_table ORDER BY date DESC',
    );
    final activeDates =
        activeRows.map((row) => row['date'] as String).toList();

    final life = allTime.first;
    final week = thisWeek.first;
    return ProgressSummary(
      streak: _currentStreak(activeDates, today),
      bestStreak: _bestStreak(activeDates),
      calories: _asInt(life['calories']),
      minutes: _asInt(life['minutes']),
      sessions: _asInt(life['sessions']),
      weeklyCompleted: _asInt(week['days']),
      weeklyGoal: kWeeklySessionGoal,
      activeDates: activeDates,
      weeklyCalories: {
        for (final row in weekDaily) row['date'] as String: _asInt(row['cals']),
      },
    );
  }

  /// Consecutive trained days counting back from today.
  ///
  /// An untrained today does not break the streak — counting starts at
  /// yesterday, so a streak survives until a whole day is actually missed.
  static int _currentStreak(List<String> activeDaysDesc, DateTime today) {
    final active = activeDaysDesc.toSet();
    var cursor = active.contains(formatDay(today))
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (active.contains(formatDay(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest run of consecutive trained days across all history.
  static int _bestStreak(List<String> activeDaysDesc) {
    if (activeDaysDesc.isEmpty) return 0;
    final days = activeDaysDesc.map(_parseDay).toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best;
  }

  static DateTime _parseDay(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  // -- helpers --------------------------------------------------------------

  /// Strips the time component so range boundaries land on whole days.
  static DateTime dateOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  /// `yyyy-MM-dd`. Sorts lexicographically, so `BETWEEN` works on this text
  /// column with no date conversion.
  static String formatDay(DateTime day) {
    final d = dateOnly(day);
    final month = d.month.toString().padLeft(2, '0');
    final date = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$date';
  }

  /// Monday-through-Sunday containing [day].
  static List<DateTime> daysOfWeekContaining(DateTime day) {
    final date = dateOnly(day);
    return List.generate(
      7,
      (i) => date.subtract(Duration(days: date.weekday - 1 - i)),
    );
  }

  /// Daily buckets for the [count] days ending today, oldest first.
  static List<ChartBucket> dailyBuckets(
    Map<String, int> daily,
    DateTime now,
    int count,
  ) {
    final today = dateOnly(now);
    return List.generate(count, (i) {
      final day = today.subtract(Duration(days: count - 1 - i));
      return ChartBucket(day, day, daily[formatDay(day)] ?? 0);
    });
  }

  /// Mon-Sun weekly buckets ending with the current week, oldest first.
  /// Each bucket covers [start, end] inclusive, so [weekCount] buckets span
  /// exactly `weekCount * 7` days.
  static List<ChartBucket> weeklyBuckets(
    Map<String, int> daily,
    DateTime now,
    int weekCount,
  ) {
    final thisWeek = daysOfWeekContaining(now).first;
    return List.generate(weekCount, (i) {
      final start = thisWeek.subtract(Duration(days: 7 * (weekCount - 1 - i)));
      final end = start.add(const Duration(days: 6));
      var sum = 0;
      for (var d = 0; d < 7; d++) {
        sum += daily[formatDay(start.add(Duration(days: d)))] ?? 0;
      }
      return ChartBucket(start, end, sum);
    });
  }

  /// Whole weeks of history, counting the current (partial) week as one.
  ///
  /// Rounds up and adds a week of slack so the oldest session is never clipped
  /// by the leading Mon-Sun boundary — otherwise the chart would total less
  /// than the cards it sits under.
  static int weeksInHistory(DateTime now, String? earliestSession) {
    if (earliestSession == null) return 1;
    final earliest = _parseDay(earliestSession);
    final days = dateOnly(now).difference(earliest).inDays;
    return ((days + 6) ~/ 7) + 1;
  }

  static int _asInt(Object? value) => (value as num?)?.toInt() ?? 0;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReportScreen extends StatefulWidget {
  /// Index of this tab in the bottom navigation, used to refresh on tab entry.
  final int tabIndex;
  final ValueNotifier<int> activeTab;

  const ReportScreen({
    super.key,
    this.tabIndex = 0,
    required this.activeTab,
  });

  /// Entry point for the workout player. Kept here so all report data logic
  /// lives in this one file.
  static Future<void> recordSession({
    required int calories,
    required int minutes,
    required int exerciseCount,
  }) =>
      ReportDataSource.recordSession(
        calories: calories,
        minutes: minutes,
        exerciseCount: exerciseCount,
      );

  /// Headline progress (streak, calories, minutes, week goal) for the home
  /// screen, planner and dashboard, so they render exactly what the report
  /// renders.
  static Future<ProgressSummary> loadSummary() => ReportDataSource.loadSummary();

  /// Fires whenever progress is written or cleared, so every screen showing
  /// these figures can refresh itself.
  static ValueListenable<int> get progressChanges =>
      ReportDataSource.revision;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportSnapshot _snapshot = ReportSnapshot.empty;
  ReportRange _range = kReportRanges[1];
  bool _isLoading = true;
  String? _error;
  int _weekCompleted = 0;

  /// Tags the newest in-flight [_load] so a slow earlier query cannot resolve
  /// after a faster later one and repaint stale numbers.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    // The tab is kept alive by an IndexedStack, so refresh on data changes and
    // on tab entry, in case a workout finished while this screen was hidden.
    ReportDataSource.revision.addListener(_load);
    widget.activeTab.addListener(_onTabSelected);
    _load();
  }

  @override
  void dispose() {
    ReportDataSource.revision.removeListener(_load);
    widget.activeTab.removeListener(_onTabSelected);
    super.dispose();
  }

  void _onTabSelected() {
    if (widget.activeTab.value == widget.tabIndex) _load();
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    try {
      final snapshot = await ReportDataSource.load(_range);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _snapshot = snapshot;
        _weekCompleted = snapshot.weeklyCompleted;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not read workout history';
      });
    }
  }

  void _selectRange(ReportRange range) {
    if (range.label == _range.label) return;
    setState(() {
      _range = range;
      _isLoading = true;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('MY PROGRESS',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRangeSelector(),
              const SizedBox(height: 16),
              _buildScopeLabel(),
              const SizedBox(height: 16),
              _buildSummaryCards(),
              const SizedBox(height: 16),
              _buildWeekGoalStrip(),
              const SizedBox(height: 32),
              _buildSectionTitle('Activity Calendar', 'Last 30 Days'),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 32),
              _buildSectionTitle('Activity Intensity', 'kcal per bar'),
              const SizedBox(height: 16),
              _buildChart(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: [
        for (final range in kReportRanges) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _selectRange(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: range.label == _range.label
                      ? const Color(0xFF2563EB)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: range.label == _range.label
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Center(
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: range.label == _range.label
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (range != kReportRanges.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildScopeLabel() {
    if (_isLoading) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
      );
    }
    final text = _range.days == null
        ? 'All recorded history • ${_snapshot.sessions} sessions'
        : '${_range.description} • ${_snapshot.sessions} session'
            '${_snapshot.sessions == 1 ? '' : 's'}';
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Calories',
                _formatNumber(_snapshot.calories),
                'kcal',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Duration',
                _formatNumber(_snapshot.minutes),
                'min',
                Icons.access_time_filled,
                const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Streak',
                _snapshot.currentStreak.toString(),
                'days',
                Icons.bolt,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                'SESSIONS',
                '${_snapshot.sessions}',
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStat(
                'ACTIVE DAYS',
                '${_snapshot.activeDates.length}',
                Icons.event_available_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStat(
                'BEST STREAK',
                '${_snapshot.bestStreak}',
                Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int value) {
    return value >= 1000
        ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k'
        : value.toString();
  }

  /// Mirrors the home screen's "WEEK PROGRESS" strip, driven by the same
  /// `ProgressSummary` so the two can never disagree.
  Widget _buildWeekGoalStrip() {
    final done = _weekCompleted;
    const goal = kWeeklySessionGoal;
    final progress = goal == 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WEEK PROGRESS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Text(
                '$done/$goal DONE',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            done >= goal
                ? 'Weekly goal complete. Rest day earned.'
                : '${goal - done} more to hit this week\'s goal.',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          Text(
            unit,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade400,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          trailing,
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysToDisplay =
        List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final today = ReportDataSource.formatDay(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.start,
        children: daysToDisplay.map((date) {
          final dateStr = ReportDataSource.formatDay(date);
          // Fall back to the range snapshot, but days outside the selected
          // range must not look "completed" — hence the range check.
          final isCompleted = _isInRange(date) && _snapshot.activeDates.contains(dateStr);
          final isToday = dateStr == today;

          return Tooltip(
            message: DateFormat('MMM d, yyyy').format(date),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF2563EB)
                    : (isToday
                        ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isCompleted
                    ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday ? const Color(0xFF2563EB) : Colors.black38,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isInRange(DateTime day) {
    if (_range.days == null) return true;
    final today = ReportDataSource.dateOnly(DateTime.now());
    final cutoff = today.subtract(Duration(days: _range.days! - 1));
    return !ReportDataSource.dateOnly(day).isBefore(cutoff);
  }

  /// Picks chart buckets that cover the selected range exactly, so the chart
  /// can never hide data the cards are counting (or count data the chart
  /// omits). Returns the buckets plus the label describing their span.
  ({List<ChartBucket> buckets, String trailing, bool weekly}) _chartShape() {
    final daily = _snapshot.dailyCalories;
    switch (_range.days) {
      case 7:
        return (
          buckets: ReportDataSource.dailyBuckets(daily, DateTime.now(), 7),
          trailing: 'Last 7 Days',
          weekly: false,
        );
      case 30:
        return (
          buckets: ReportDataSource.dailyBuckets(daily, DateTime.now(), 30),
          trailing: 'Last 30 Days',
          weekly: false,
        );
      case 90:
        return (
          buckets: ReportDataSource.weeklyBuckets(daily, DateTime.now(), 13),
          trailing: 'Per Week • 13 wks',
          weekly: true,
        );
      default:
        // All time: span the whole history. Capped so a multi-year history
        // still renders legibly, and the cap is stated rather than silent.
        final weeks = ReportDataSource.weeksInHistory(
          DateTime.now(),
          _snapshot.earliestSession,
        );
        const cap = 26;
        final shown = weeks > cap ? cap : weeks;
        return (
          buckets: ReportDataSource.weeklyBuckets(daily, DateTime.now(), shown),
          trailing: weeks > cap
              ? 'Per Week • last $cap of $weeks wks'
              : 'Per Week • $shown wks',
          weekly: true,
        );
    }
  }

  Widget _buildChart() {
    final shape = _chartShape();
    final buckets = shape.buckets;
    final weekly = shape.weekly;
    final peak = buckets.fold<int>(0, (a, b) => a > b.calories ? a : b.calories);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (peak == 0) ...[
            SizedBox(
              height: 90,
              child: Center(
                child: Text(
                  _snapshot.allTimeCalories == 0
                      ? 'Finish a workout to start tracking.'
                      : 'No workouts in ${_range.description.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < buckets.length; i++)
                    Expanded(
                      child: _buildBar(
                        fraction: peak == 0 ? 0 : buckets[i].calories / peak,
                        label: _barLabel(buckets[i], i, buckets.length, weekly),
                        tooltip: weekly
                            ? '${DateFormat('d MMM').format(buckets[i].start)} – '
                                '${DateFormat('d MMM').format(buckets[i].end)}\n'
                                '${buckets[i].calories} kcal'
                            : '${DateFormat('EEE d MMM').format(buckets[i].start)}\n'
                                '${buckets[i].calories} kcal',
                        barCount: buckets.length,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Peak $peak kcal • ${shape.trailing}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Keeps the axis readable as bar count grows: every bar at 7 days, every
  /// 5th at 30 days, every 2nd or so once weekly buckets get dense.
  String _barLabel(
    ChartBucket bucket,
    int index,
    int count,
    bool weekly,
  ) {
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (!weekly) {
      if (count <= 7) return dayLetters[bucket.start.weekday - 1];
      return index % 5 == 0 || index == count - 1
          ? bucket.start.day.toString()
          : '';
    }
    if (count <= 13) return DateFormat('d/M').format(bucket.start);
    return index % 3 == 0 || index == count - 1
        ? DateFormat('d/M').format(bucket.start)
        : '';
  }

  Widget _buildBar({
    required double fraction,
    required String label,
    required String tooltip,
    required int barCount,
  }) {
    final hasData = fraction > 0;
    // Tighten gutters as bars multiply so 30 daily bars stay visible.
    final gutter = barCount > 20
        ? 1.0
        : (barCount > 10 ? 2.0 : 4.0);
    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: gutter),
            height: hasData ? (112 * fraction).clamp(6, 112) : 3,
            decoration: BoxDecoration(
              gradient: hasData
                  ? const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: hasData ? null : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 12,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.54),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
