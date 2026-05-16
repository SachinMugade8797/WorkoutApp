import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../services/workout_generator_service.dart';
import '../services/storage_service.dart';
import 'personalized_dashboard_screen.dart';

class PlannerFormScreen extends StatefulWidget {
  const PlannerFormScreen({super.key});

  @override
  State<PlannerFormScreen> createState() => _PlannerFormScreenState();
}

class _PlannerFormScreenState extends State<PlannerFormScreen> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  String _goal = 'Build Muscle';
  String _level = 'Beginner';
  String _equipment = 'None';
  String _focusArea = 'Full Body';
  String _injury = 'None';
  String _timePerSession = '30 mins';
  bool _isGenerating = false;
  String _loadingMessage = 'Analyzing your fitness profile...';

  final List<String> _goals = ['Build Muscle', 'Lose Weight', 'Get Fit', 'Increase Flexibility'];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _equipments = ['None', 'Dumbbells Only', 'Full Gym'];
  final List<String> _focusAreas = ['Chest & Arms', 'Legs & Glutes', 'Core & Abs', 'Full Body'];
  final List<String> _injuries = ['None', 'Knee Pain', 'Back Pain'];
  final List<String> _times = ['15 mins', '30 mins', '45 mins'];

  final List<String> _loadingMessages = [
    "Analyzing your fitness profile...",
    "Filtering 25+ exercises for your Focus Area...",
    "Adjusting for injury limitations...",
    "Calculating estimated calorie burn...",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    
    // Start rotating messages
    int messageIndex = 0;
    Timer messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          messageIndex = (messageIndex + 1) % _loadingMessages.length;
          _loadingMessage = _loadingMessages[messageIndex];
        });
      }
    });

    // Random duration between 3 and 8 seconds
    int delay = 3 + Random().nextInt(6);
    await Future.delayed(Duration(seconds: delay));

    try {
      final result = await WorkoutGeneratorService.generate7DayPlan(
        name: _nameController.text,
        goal: _goal,
        level: _level,
        equipment: _equipment,
        focusArea: _focusArea,
        injury: _injury,
        timePerSession: _timePerSession,
      );

      await StorageService.savePlan(
        Map<String, List<String>>.from(result['plan']),
        result['userName'],
        _goal,
        result['totalBurn'],
      );

      messageTimer.cancel();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PersonalizedDashboardScreen()),
        );
      }
    } catch (e) {
      messageTimer.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Plan Your Journey', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isGenerating 
        ? _buildLoadingState()
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 7,
                  backgroundColor: Colors.grey.shade100,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(child: _buildStepContent()),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _loadingMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildSelectionStep('What is your main goal?', _goals, _goal, (val) => setState(() => _goal = val!));
      case 2:
        return _buildSelectionStep('Choose your fitness level', _levels, _level, (val) => setState(() => _level = val!));
      case 3:
        return _buildSelectionStep('What equipment do you have?', _equipments, _equipment, (val) => setState(() => _equipment = val!));
      case 4:
        return _buildSelectionStep('Which area to focus on?', _focusAreas, _focusArea, (val) => setState(() => _focusArea = val!));
      case 5:
        return _buildSelectionStep('Any injuries or limitations?', _injuries, _injury, (val) => setState(() => _injury = val!));
      case 6:
        return _buildSelectionStep('Time per session?', _times, _timePerSession, (val) => setState(() => _timePerSession = val!));
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What's your name?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 30),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSelectionStep(String title, List<String> options, String currentVal, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 30),
        ...options.map((option) => Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: currentVal == option ? const Color(0xFF2563EB) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: RadioListTile<String>(
            title: Text(option, style: const TextStyle(fontWeight: FontWeight.bold)),
            value: option,
            groupValue: currentVal,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
          ),
        )),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 6) {
                  if (_currentStep == 0 && _nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your name')),
                    );
                    return;
                  }
                  setState(() => _currentStep++);
                } else {
                  _generatePlan();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(_currentStep < 6 ? 'Next' : 'Generate Plan'),
            ),
          ),
        ],
      ),
    );
  }
}
