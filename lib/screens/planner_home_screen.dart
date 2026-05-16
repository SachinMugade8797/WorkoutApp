import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/storage_service.dart';
import 'planner_form_screen.dart';
import 'workout_player_screen.dart';

class PlannerHomeScreen extends StatefulWidget {
  const PlannerHomeScreen({super.key});

  @override
  State<PlannerHomeScreen> createState() => _PlannerHomeScreenState();
}

class _PlannerHomeScreenState extends State<PlannerHomeScreen> {
  Map<String, List<String>>? _weeklyPlan;
  int _streak = 0;
  int _totalCalories = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final plan = await StorageService.getPlan();
    final streak = await StorageService.getStreak();
    final calories = await StorageService.getTotalCalories();
    setState(() {
      _weeklyPlan = plan;
      _streak = streak;
      _totalCalories = calories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_weeklyPlan == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My AI Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            _buildStatsHeader(),
            const SizedBox(height: 30),
            const Text(
              'Weekly Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ..._weeklyPlan!.entries.map((entry) => _buildDayCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF2563EB)),
            const SizedBox(height: 20),
            const Text(
              'No Plan Generated Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Let AI create a custom 7-day routine for you.'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlannerFormScreen()),
              ).then((_) => _loadData()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('CREATE MY PLAN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('$_streak', 'STREAK', Icons.local_fire_department),
          _statItem('$_totalCalories', 'KCAL', Icons.bolt),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 5),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildDayCard(String day, List<String> exerciseIds) {
    final exercises = exerciseIds.map((id) => masterExerciseList.firstWhere((e) => e.id == id)).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text('${exercises.length} Exercises'),
        trailing: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkoutPlayerScreen(exerciseIds: exerciseIds)),
          ).then((_) => _loadData()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('START', style: TextStyle(color: Colors.white)),
        ),
        children: exercises.map((ex) => ListTile(
          leading: const Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text(ex.name),
          subtitle: Text(ex.category),
        )).toList(),
      ),
    );
  }
}
