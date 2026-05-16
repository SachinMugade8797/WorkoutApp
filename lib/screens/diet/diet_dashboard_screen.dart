import 'package:flutter/material.dart';
import '../../models/diet_model.dart';
import '../../services/diet_service.dart';
import '../../services/storage_service.dart';
import '../../main.dart';

class DietDashboardScreen extends StatefulWidget {
  const DietDashboardScreen({super.key});

  @override
  State<DietDashboardScreen> createState() => _DietDashboardScreenState();
}

class _DietDashboardScreenState extends State<DietDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DietProfile? _profile;
  Map<String, DailyDietPlan>? _weeklyPlan;
  Map<String, dynamic>? _nutrition;
  double _waterIntake = 0;
  double _waterGoal = 2.5;
  bool _isLoading = true;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Color _primaryColor = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this, initialIndex: _getCurrentDayIndex());
    _loadData();
  }

  int _getCurrentDayIndex() {
    int weekday = DateTime.now().weekday; // Mon=1, Sun=7
    return weekday - 1;
  }

  Future<void> _loadData() async {
    final profileJson = await StorageService.getDietProfile();
    final planJson = await StorageService.getWeeklyDietPlan();
    final intake = await StorageService.getWaterIntake();
    final goal = await StorageService.getWaterGoal();

    if (profileJson != null && planJson != null) {
      final profile = DietProfile.fromJson(profileJson);
      final Map<String, dynamic> decodedPlan = planJson;
      final weeklyPlan = decodedPlan.map((k, v) => MapEntry(k, DailyDietPlan.fromJson(v)));

      setState(() {
        _profile = profile;
        _weeklyPlan = weeklyPlan;
        _nutrition = DietService.calculateNutrition(profile);
        _waterIntake = intake;
        _waterGoal = goal;
        _isLoading = false;
      });
    }
  }

  void _addWater() async {
    setState(() {
      _waterIntake += 0.25; // Add 250ml
      if (_waterIntake > _waterGoal + 1) _waterIntake = _waterGoal + 1;
    });
    await StorageService.saveWaterIntake(_waterIntake);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset Diet Plan?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to reset your diet plan? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await StorageService.clearDietData();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainNavigation()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${_profile?.goal ?? 'Diet'} Plan', style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _showResetConfirmation,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNutritionSummary(),
            _buildWaterTracker(),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 30, 24, 15),
              child: Text('Weekly Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            _buildWeeklyTabs(),
            _buildDayPlan(_weeklyPlan![_days[_tabController.index]]!),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Targets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildMacroCard('Calories', '${_nutrition!['calories']}', 'kcal', _primaryColor)),
              const SizedBox(width: 15),
              Expanded(child: _buildMacroCard('Protein', '${_nutrition!['protein']}', 'g', Colors.orange)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildMacroCard('Carbs', '${_nutrition!['carbs']}', 'g', Colors.green)),
              const SizedBox(width: 15),
              Expanded(child: _buildMacroCard('Fats', '${_nutrition!['fats']}', 'g', Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8))),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.6))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker() {
    double percent = _waterIntake / _waterGoal;
    if (percent > 1.0) percent = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hydration Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                    Text('${_waterIntake.toStringAsFixed(2)} / ${_waterGoal.toStringAsFixed(2)} L', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
                Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addWater,
              icon: const Icon(Icons.add),
              label: const Text('Add 250ml'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: _primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: _primaryColor,
      indicatorWeight: 3,
      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
      tabs: _days.map((day) => Tab(text: day)).toList(),
      onTap: (index) {
        setState(() {}); // Rebuild to show the selected day's plan
      },
    );
  }

  Widget _buildDayPlan(DailyDietPlan plan) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildMealCard('Breakfast', plan.breakfast),
          _buildMealCard('Lunch', plan.lunch),
          _buildMealCard('Snacks', plan.snacks),
          _buildMealCard('Dinner', plan.dinner),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, List<Meal> meals) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text('${meals.fold(0, (sum, item) => sum + item.calories)} kcal', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...meals.map((meal) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(meal.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniMacro('P', '${meal.protein.toStringAsFixed(1)}g'),
                          _buildMiniMacro('C', '${meal.carbs.toStringAsFixed(1)}g'),
                          _buildMiniMacro('F', '${meal.fats.toStringAsFixed(1)}g'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildMiniMacro(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
