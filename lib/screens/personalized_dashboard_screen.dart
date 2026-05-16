import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/storage_service.dart';
import 'planner_form_screen.dart';
import 'workout_player_screen.dart';

class PersonalizedDashboardScreen extends StatefulWidget {
  const PersonalizedDashboardScreen({super.key});

  @override
  State<PersonalizedDashboardScreen> createState() => _PersonalizedDashboardScreenState();
}

class _PersonalizedDashboardScreenState extends State<PersonalizedDashboardScreen> {
  Map<String, List<String>>? _weeklyPlan;
  String _userName = 'User';
  String _userGoal = 'Fitness';
  int _streak = 0;
  int _totalCalories = 0;
  int _weeklyBurn = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final plan = await StorageService.getPlan();
    final name = await StorageService.getUserName();
    final goal = await StorageService.getUserGoal();
    final streak = await StorageService.getStreak();
    final calories = await StorageService.getTotalCalories();
    final weeklyBurn = await StorageService.getWeeklyBurn();
    
    setState(() {
      _weeklyPlan = plan;
      _userName = name ?? 'User';
      _userGoal = goal ?? 'Fitness';
      _streak = streak;
      _totalCalories = calories;
      _weeklyBurn = weeklyBurn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$_userName\'s 7-Day $_userGoal Journey', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlannerFormScreen()),
            ).then((_) => _loadData()),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '$_streak Days',
                    'STREAK 🔥',
                    const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    '$_totalCalories',
                    'TOTAL KCAL ⚡',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Weekly Burn Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.green, size: 30),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_weeklyBurn kcal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green)),
                      const Text('ESTIMATED WEEKLY BURN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'TODAY\'S WORKOUT',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 15),
            
            if (_weeklyPlan != null) _buildTodaysPlanCard()
            else _buildEmptyPlanCard(),
            
            const SizedBox(height: 30),
            const Text(
              'WEEKLY SCHEDULE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 15),
            if (_weeklyPlan != null)
              ..._weeklyPlan!.entries.map((e) => _buildDayTile(e.key, e.value))
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String val, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildTodaysPlanCard() {
    String today = _getTodayKey();
    final exerciseIds = _weeklyPlan![today] ?? [];
    
    if (exerciseIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(
          child: Text('Today is a Rest Day! 🧘', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ready to go?', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Text('${exerciseIds.length} Exercises', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Custom Daily Routine',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutPlayerScreen(exerciseIds: exerciseIds),
              ),
            ).then((_) => _loadData()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('START WORKOUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getTodayKey() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }

  Widget _buildEmptyPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('No plan found'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlannerFormScreen())).then((_) => _loadData()),
            child: const Text('Generate with AI'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTile(String day, List<String> ids) {
    bool isToday = day == _getTodayKey();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: isToday ? Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)) : null,
      ),
      child: ListTile(
        title: Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? const Color(0xFF2563EB) : Colors.black)),
        subtitle: Text(ids.isEmpty ? 'Rest Day' : '${ids.length} exercises'),
        trailing: ids.isEmpty ? null : const Icon(Icons.chevron_right),
        onTap: ids.isEmpty ? null : () {
          // Could show a list of exercises or start the workout
        },
      ),
    );
  }
}
