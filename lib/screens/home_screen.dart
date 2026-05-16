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

    setState(() {
      _streak = streak;
      _totalKcal = kcal;
      _totalMinutes = mins;
      _completedDates = completed;
      _hasMissedWorkout = isActive;
    });
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    // Week starts on Monday (1)
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
              
              // Top Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('$_streak', 'STREAK'),
                  _buildStatItem('$_totalKcal', 'KCAL'),
                  _buildStatItem('$_totalMinutes', 'MINUTES'),
                ],
              ),
              const SizedBox(height: 30),

              // Week Goal Section
              Container(
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
                        Row(
                          children: [
                            const Text(
                              'WEEK GOAL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                        Text(
                          '${_completedDates.length}/6',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
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
                            color: isCompleted 
                                ? const Color(0xFF2563EB) 
                                : (isToday ? Colors.blue.shade50 : Colors.grey.shade100),
                            shape: BoxShape.circle,
                            border: isToday ? Border.all(color: const Color(0xFF2563EB), width: 1) : null,
                          ),
                          child: Center(
                            child: isCompleted 
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isToday ? const Color(0xFF2563EB) : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                '7x4 CHALLENGE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),

              // Challenge Card
              _buildChallengeCard(context),
              const SizedBox(height: 40),

              const Text(
                'BEGINNER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),

              // Beginner Section
              InkWell(
                onTap: () => _handlePersonalizedPlanClick(context),
                child: _buildBeginnerCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              child: Image.asset(
                'assets/images/body_challenge.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FULL BODY 7x4\nCHALLENGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '0 % Finished',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'DAY 1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
                    final refresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutPlayerScreen(
                          exerciseIds: ids,
                          startIndex: index,
                        ),
                      ),
                    );
                    if (refresh == true) _refreshData();
                  }
                } else {
                  if (!mounted) return;
                  final refresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutGeneratorForm(),
                    ),
                  );
                  if (refresh == true) _refreshData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                _hasMissedWorkout ? 'RESUME WORKOUT' : 'START',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeginnerCard() {
    return Container(
      width: double.infinity,
      height: 140,
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
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Colors.white, size: 16),
                Icon(Icons.bolt, color: Colors.white, size: 16),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Your Personalized Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '18 MINS • 16 EXERCISES',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
