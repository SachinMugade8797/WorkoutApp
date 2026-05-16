import 'package:flutter/material.dart';
import '../../models/diet_model.dart';
import '../../services/diet_service.dart';
import '../../services/storage_service.dart';
import 'diet_loading_screen.dart';

class DietFormScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const DietFormScreen({super.key, required this.onComplete});

  @override
  State<DietFormScreen> createState() => _DietFormScreenState();
}

class _DietFormScreenState extends State<DietFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form Data
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _gender = 'Male';
  String _goal = 'Weight Loss';
  String _activityLevel = 'Moderate';
  String _mealPreference = 'Indian Diet';
  bool _autoWater = true;
  final TextEditingController _waterGoalController = TextEditingController();

  final Color _primaryColor = const Color(0xFF2563EB);

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _waterGoalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    final String ageStr = _ageController.text;
    final String weightStr = _weightController.text;
    final String heightStr = _heightController.text;

    if (ageStr.isEmpty || weightStr.isEmpty || heightStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final int? age = int.tryParse(ageStr);
    final double? weight = double.tryParse(weightStr);
    final double? height = double.tryParse(heightStr);

    if (age == null || age < 10 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age between 10–100')),
      );
      return;
    }

    if (height == null || height < 100 || height > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Height must be between 100–250 cm')),
      );
      return;
    }

    if (weight == null || weight < 25 || weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight must be between 25–300 kg')),
      );
      return;
    }

    final profile = DietProfile(
      age: age,
      weight: weight,
      height: height,
      gender: _gender,
      goal: _goal,
      activityLevel: _activityLevel,
      mealPreference: _mealPreference,
      autoWater: _autoWater,
      customWaterGoal: _autoWater ? null : double.tryParse(_waterGoalController.text),
    );

    // Show loading screen for 10 seconds
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DietLoadingScreen(),
      ),
    );

    // Save profile and generate plan
    await StorageService.saveDietProfile(profile.toJson());
    final weeklyPlan = DietService.generateWeeklyPlan(profile);
    await StorageService.saveWeeklyDietPlan(weeklyPlan.map((k, v) => MapEntry(k, v.toJson())));
    
    double waterGoal = DietService.calculateWaterGoal(profile);
    await StorageService.saveWaterGoal(waterGoal);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Diet Planner', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (step) => setState(() => _currentStep = step),
                children: [
                  _buildPersonalInfoStep(),
                  _buildGoalStep(),
                  _buildActivityStep(),
                  _buildPreferenceStep(),
                  _buildWaterStep(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return _buildStepContainer(
      title: 'Personal Information',
      subtitle: 'Help us understand your body better',
      child: Column(
        children: [
          _buildTextField(_ageController, 'Age', Icons.cake, TextInputType.number),
          const SizedBox(height: 15),
          _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight, TextInputType.number),
          const SizedBox(height: 15),
          _buildTextField(_heightController, 'Height (cm)', Icons.height, TextInputType.number),
          const SizedBox(height: 25),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildSelectableCard('Male', _gender == 'Male', () => setState(() => _gender = 'Male'))),
              const SizedBox(width: 15),
              Expanded(child: _buildSelectableCard('Female', _gender == 'Female', () => setState(() => _gender = 'Female'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return _buildStepContainer(
      title: 'What is your goal?',
      subtitle: 'We will tailor your plan accordingly',
      child: Column(
        children: [
          _buildOptionCard('Weight Loss', 'Burn fat and get leaner', Icons.trending_down, _goal == 'Weight Loss', () => setState(() => _goal = 'Weight Loss')),
          _buildOptionCard('Weight Gain', 'Increase body mass', Icons.trending_up, _goal == 'Weight Gain', () => setState(() => _goal = 'Weight Gain')),
          _buildOptionCard('Muscle Gain', 'Build strength and size', Icons.fitness_center, _goal == 'Muscle Gain', () => setState(() => _goal = 'Muscle Gain')),
          _buildOptionCard('Maintain Weight', 'Keep current weight stable', Icons.balance, _goal == 'Maintain Weight', () => setState(() => _goal = 'Maintain Weight')),
        ],
      ),
    );
  }

  Widget _buildActivityStep() {
    return _buildStepContainer(
      title: 'Activity Level',
      subtitle: 'How active are you daily?',
      child: Column(
        children: [
          _buildOptionCard('Beginner', 'Little to no exercise', Icons.airline_seat_recline_normal, _activityLevel == 'Beginner', () => setState(() => _activityLevel = 'Beginner')),
          _buildOptionCard('Moderate', 'Exercise 3-5 days a week', Icons.directions_walk, _activityLevel == 'Moderate', () => setState(() => _activityLevel = 'Moderate')),
          _buildOptionCard('Active', 'Heavy exercise daily', Icons.directions_run, _activityLevel == 'Active', () => setState(() => _activityLevel = 'Active')),
        ],
      ),
    );
  }

  Widget _buildPreferenceStep() {
    return _buildStepContainer(
      title: 'Meal Preference',
      subtitle: 'Choose your dietary choice',
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildOptionCard('Vegetarian', 'No meat, includes dairy', Icons.eco, _mealPreference == 'Vegetarian', () => setState(() => _mealPreference = 'Vegetarian')),
            _buildOptionCard('Non-Vegetarian', 'Includes all proteins', Icons.kebab_dining, _mealPreference == 'Non-Vegetarian', () => setState(() => _mealPreference = 'Non-Vegetarian')),
            _buildOptionCard('Vegan', 'Plant-based only', Icons.grass, _mealPreference == 'Vegan', () => setState(() => _mealPreference = 'Vegan')),
            _buildOptionCard('Indian Diet', 'Balanced Indian meals', Icons.restaurant, _mealPreference == 'Indian Diet', () => setState(() => _mealPreference = 'Indian Diet')),
            _buildOptionCard('Gym Diet', 'High protein focused', Icons.fitness_center, _mealPreference == 'Gym Diet', () => setState(() => _mealPreference = 'Gym Diet')),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterStep() {
    return _buildStepContainer(
      title: 'Water Preference',
      subtitle: 'How would you like to track hydration?',
      child: Column(
        children: [
          _buildOptionCard('Auto Calculate', 'Recommended based on weight', Icons.auto_awesome, _autoWater, () => setState(() => _autoWater = true)),
          _buildOptionCard('Custom Water Goal', 'Set your own daily target', Icons.edit, !_autoWater, () => setState(() => _autoWater = false)),
          if (!_autoWater) ...[
            const SizedBox(height: 20),
            _buildTextField(_waterGoalController, 'Target (Liters)', Icons.water_drop, TextInputType.number),
          ],
        ],
      ),
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 30),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _primaryColor, width: 2)),
      ),
    );
  }

  Widget _buildSelectableCard(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade200, width: 2),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? _primaryColor : Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String title, String desc, IconData icon, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade200, width: 2),
            boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isSelected ? _primaryColor : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: _primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Back', style: TextStyle(color: Colors.grey)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(_currentStep == _totalSteps - 1 ? 'GENERATE PLAN' : 'NEXT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
