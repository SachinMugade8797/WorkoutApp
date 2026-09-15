import 'package:flutter/material.dart';
import 'workout_generator_form.dart';
import 'planner_form_screen.dart';
import 'personalized_dashboard_screen.dart';
import 'workout_player_screen.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  int _totalKcal = 0;
  int _totalMinutes = 0;
  List<DateTime> _weekDates = [];
  int _todayIndex = -1;
  List<String> _completedDates = [];
  bool _hasMissedWorkout = false;

  // New dynamic fields
  Map<String, List<String>>? _weeklyPlan;
  String _userGoal = "Fitness";

  @override
  void initState() {
    super.initState();
    _refreshData();
    _calculateWeekDates();
  }

  Future<void> _refreshData() async {
    final streak = await StorageService.getStreak();
    final kcal = await StorageService.getTotalCalories();
    final mins = await StorageService.getTotalMinutes();
    final completed = await StorageService.getCompletedDates();
    final isActive = await StorageService.isWorkoutActive();
    final plan = await StorageService.getPlan();
    final goal = await StorageService.getUserGoal();

    if (mounted) {
      setState(() {
        _streak = streak;
        _totalKcal = kcal;
        _totalMinutes = mins;
        _completedDates = completed;
        _hasMissedWorkout = isActive;
        _weeklyPlan = plan;
        _userGoal = goal ?? "Fitness";
      });
    }
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(monday.add(Duration(days: i)));
    }
    setState(() {
      _weekDates = dates;
      _todayIndex = now.weekday - 1;
    });
  }

  Future<void> _handlePersonalizedPlanClick(BuildContext context) async {
    final plan = await StorageService.getPlan();
    if (!context.mounted) return;
    final destination = plan == null
        ? const PlannerFormScreen()
        : const PersonalizedDashboardScreen();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
    _refreshData();
  }

  String _getTodayKey() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WORKOUT PLANNER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _buildWeekGoalSection(),
              const SizedBox(height: 24),
              _buildAIHeroCard(),
              const SizedBox(height: 16),
              _buildPostureTeaserCard(),
              const SizedBox(height: 20),
              _buildQuickStatsRow(),
              const SizedBox(height: 20),
              _buildWeekProgressStrip(),
              const SizedBox(height: 24),
              _buildChallengeCard(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekGoalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'WEEK GOAL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.stars, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
              Text(
                '${_completedDates.length}/6',
                style: const TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              if (_weekDates.isEmpty) {
                return const SizedBox(width: 35, height: 35);
              }
              DateTime date = _weekDates[index];
              String dateStr = date.toIso8601String().split('T')[0];
              bool isCompleted = _completedDates.contains(dateStr);
              bool isToday = index == _todayIndex;

              return Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF2563EB)
                      : (isToday
                          ? Colors.blue.withValues(alpha: 0.05)
                          : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text('${date.day}',
                          style: TextStyle(
                              color: isToday
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAIHeroCard() {
    String todayKey = _getTodayKey();
    List<String>? todayExercises = _weeklyPlan?[todayKey];
    bool hasPlan = _weeklyPlan != null;
    bool isRestDay =
        hasPlan && (todayExercises == null || todayExercises.isEmpty);

    return InkWell(
      onTap: () => _handlePersonalizedPlanClick(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/Ai_planner.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.15),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasPlan ? 'ACTIVE PLAN' : 'AI GENERATED',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                hasPlan ? 'Today: $_userGoal' : 'Personalized AI Plan',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                hasPlan
                    ? (isRestDay
                        ? 'REST DAY'
                        : '${todayExercises!.length} TARGETED EXERCISES')
                    : 'CREATE YOUR AI PLAN',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasPlan ? _startTodaysWorkout : _openPlannerForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    hasPlan ? 'START WORKOUT' : 'CREATE PLAN',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTodaysWorkout() async {
    final plan = _weeklyPlan;
    if (plan == null) return;

    List<String> ids = plan[_getTodayKey()] ?? [];
    if (ids.isEmpty) {
      // Rest day today — fall back to Monday's routine.
      ids = plan['Mon'] ?? [];
    }
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No workout available yet. Create your AI plan first.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutPlayerScreen(exerciseIds: ids)),
    );
    _refreshData();
  }

  void _openPlannerForm() {
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PlannerFormScreen()))
        .then((_) => _refreshData());
  }

  Widget _buildPostureTeaserCard() {
    return Material(
      color: const Color(0xFFEDF2FF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openPostureScore,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check Your Posture Score',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('See how your posture affects your workouts',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _openPostureScore() {
    // Posture Score screen is not built yet — placeholder for later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Posture Score is coming soon!')),
    );
  }

  Widget _buildWeekProgressStrip() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekDates = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return d.toIso8601String().split('T')[0];
    });
    final completedThisWeek =
        _completedDates.where((d) => thisWeekDates.contains(d)).length;
    const goal = 6;
    final progress = (completedThisWeek / goal).clamp(0.0, 1.0);

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
              const Text('WEEK PROGRESS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              Text('$completedThisWeek/$goal DONE',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        _buildStatItem('$_streak', 'STREAK'),
        const SizedBox(width: 12),
        _buildStatItem('$_totalKcal', 'KCAL'),
        const SizedBox(width: 12),
        _buildStatItem('$_totalMinutes', 'MIN'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FULL BODY 7x4',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('CHALLENGE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Start your journey to fitness',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_hasMissedWorkout) {
                final ids = await StorageService.getActiveWorkoutIds();
                final index = await StorageService.getCurrentWorkoutIndex();
                if (!context.mounted) return;
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WorkoutPlayerScreen(
                            exerciseIds: ids, startIndex: index)));
                _refreshData();
              } else {
                if (!context.mounted) return;
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkoutGeneratorForm()));
                _refreshData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              elevation: 0,
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21)),
            ),
            child: Text(_hasMissedWorkout ? 'RESUME' : 'START',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
