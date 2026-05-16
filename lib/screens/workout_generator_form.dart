import 'dart:convert';
import 'package:flutter/material.dart';
import 'workout_player_screen.dart';
import '../services/storage_service.dart';

class WorkoutGeneratorForm extends StatefulWidget {
  const WorkoutGeneratorForm({super.key});

  @override
  State<WorkoutGeneratorForm> createState() => _WorkoutGeneratorFormState();
}

class _WorkoutGeneratorFormState extends State<WorkoutGeneratorForm> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isGenerating = false;

  // Form Data
  String? _selectedGoal;
  String? _selectedFitnessLevel;
  String? _selectedEquipment;
  String? _selectedSchedule;

  final Color _primaryColor = const Color(0xFF2563EB);

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _generatePlanAndStart();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _generatePlanAndStart() async {
    setState(() => _isGenerating = true);

    // Mock logic: Selecting some hardcoded IDs based on goal
    List<String> exercises = ['lg_01', 'ch_01', 'ab_01', 'bk_01', 'ar_01', 'lg_03'];
    
    // Check for missed exercises
    List<String> missed = await StorageService.getMissedExercises();
    if (missed.isNotEmpty) {
      exercises = [...missed, ...exercises];
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isGenerating = false);
      
      final refresh = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutPlayerScreen(exerciseIds: exercises),
        ),
      );

      if (refresh == true && mounted) {
        Navigator.pop(context, true); // Signal home to refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Workout Generator',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isGenerating ? _buildLoadingState() : _buildFormContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 20),
          const Text(
            'Preparing your workout...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Including any missed exercises from last session.'),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
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
            onPageChanged: (int page) => setState(() => _currentPage = page),
            children: [
              _buildSelectionPage(
                title: 'What is your goal?',
                options: ['Lose Weight', 'Build Muscle', 'Stay Fit'],
                selectedValue: _selectedGoal,
                onSelected: (val) => setState(() => _selectedGoal = val),
              ),
              _buildSelectionPage(
                title: 'Your Fitness Level?',
                options: ['Beginner', 'Intermediate', 'Advanced'],
                selectedValue: _selectedFitnessLevel,
                onSelected: (val) => setState(() => _selectedFitnessLevel = val),
              ),
              _buildSelectionPage(
                title: 'Available Equipment?',
                options: ['No Equipment', 'Dumbbells only', 'Full Gym'],
                selectedValue: _selectedEquipment,
                onSelected: (val) => setState(() => _selectedEquipment = val),
              ),
              _buildSelectionPage(
                title: 'Weekly Schedule?',
                options: ['3 days/week', '5 days/week'],
                selectedValue: _selectedSchedule,
                onSelected: (val) => setState(() => _selectedSchedule = val),
              ),
            ],
          ),
        ),
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildSelectionPage({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 30),
          ...options.map((option) {
            bool isSelected = selectedValue == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: InkWell(
                onTap: () => onSelected(option),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade200, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option, style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _primaryColor : Colors.black87)),
                      if (isSelected) Icon(Icons.check_circle, color: _primaryColor),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    bool canGoNext = (_currentPage == 0 && _selectedGoal != null) ||
                     (_currentPage == 1 && _selectedFitnessLevel != null) ||
                     (_currentPage == 2 && _selectedEquipment != null) ||
                     (_currentPage == 3 && _selectedSchedule != null);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(child: TextButton(onPressed: _previousPage, child: const Text('Back', style: TextStyle(color: Colors.grey, fontSize: 16)))),
          if (_currentPage > 0) const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canGoNext ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(_currentPage == 3 ? 'START WORKOUT' : 'NEXT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
