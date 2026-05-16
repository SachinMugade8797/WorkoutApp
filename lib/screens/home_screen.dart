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
    if (!mounted) return;
    if (plan == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PlannerFormScreen()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PersonalizedDashboardScreen()),
      );
    }
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('$_streak', 'STREAK'),
                  _buildStatItem('$_totalKcal', 'KCAL'),
                  _buildStatItem('$_totalMinutes', 'MINUTES'),
                ],
              ),
              const SizedBox(height: 30),

              _buildWeekGoalSection(),
              const SizedBox(height: 30),

              const Text(
                '7x4 CHALLENGE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),

              _buildChallengeCard(context),
              const SizedBox(height: 40),

              Text(
                _weeklyPlan == null ? 'AI RECOMMENDATION' : 'YOUR JOURNEY',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),

              InkWell(
                onTap: () => _handlePersonalizedPlanClick(context),
                child: _buildBeginnerCard(),
              ),
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
            color: Colors.black.withOpacity(0.03),
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
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              if (_weekDates.isEmpty) return const SizedBox(width: 35, height: 35);
              DateTime date = _weekDates[index];
              String dateStr = date.toIso8601String().split('T')[0];
              bool isCompleted = _completedDates.contains(dateStr);
              bool isToday = index == _todayIndex;

              return Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF2563EB) : (isToday ? Colors.blue.shade50 : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: const Color(0xFF2563EB), width: 1.5) : null,
                ),
                child: Center(
                  child: isCompleted 
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text('${date.day}', style: TextStyle(color: isToday ? const Color(0xFF2563EB) : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBeginnerCard() {
    String todayKey = _getTodayKey();
    List<String>? todayExercises = _weeklyPlan?[todayKey];
    bool hasPlan = _weeklyPlan != null;

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/Ai_planner.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasPlan ? 'ACTIVE PLAN' : 'AI GENERATED',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasPlan ? 'Today: $_userGoal' : 'Personalized AI Plan',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              hasPlan 
                ? (todayExercises == null || todayExercises.isEmpty ? 'REST DAY' : '${todayExercises.length} TARGETED EXERCISES')
                : 'CREATE YOUR AI PLAN',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (!hasPlan)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 160,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
              child: Image.asset('assets/images/body_challenge.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FULL BODY 7x4\nCHALLENGE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text('Start your journey to fitness', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                const Text('DAY 1', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 25,
            width: 180,
            child: ElevatedButton(
              onPressed: () async {
                if (_hasMissedWorkout) {
                  final ids = await StorageService.getActiveWorkoutIds();
                  final index = await StorageService.getCurrentWorkoutIndex();
                  if (mounted) {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutPlayerScreen(exerciseIds: ids, startIndex: index)));
                    _refreshData();
                  }
                } else {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutGeneratorForm()));
                  _refreshData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: Text(_hasMissedWorkout ? 'RESUME WORKOUT' : 'START', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
