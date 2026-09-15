import 'package:flutter/material.dart';
import 'dart:async';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../services/storage_service.dart';
import '../services/workout_generator_service.dart';
import 'personalized_dashboard_screen.dart';

/// Order that planner steps appear in. Steps are built dynamically from
/// whatever the profile is still missing, so the planner only asks about
/// things onboarding didn't cover (plus the focus-area question).
enum _PlannerStep { name, goal, experienceLevel, equipment, timePerSession, injuries, focusArea }

class PlannerFormScreen extends StatefulWidget {
  const PlannerFormScreen({super.key});

  @override
  State<PlannerFormScreen> createState() => _PlannerFormScreenState();
}

class _PlannerFormScreenState extends State<PlannerFormScreen> {
  // ---- Dynamic steps ----
  late List<_PlannerStep> _steps = [];
  int _currentStep = 0;

  // Working copy of the profile, seeded from the DB at load and updated as
  // each answered step is persisted (partial progress survives leaving early).
  UserProfile _workingProfile = const UserProfile();

  // ---- Form values ----
  final TextEditingController _nameController = TextEditingController();
  String _goal = 'Build Muscle';
  String _level = 'Beginner';
  String _equipment = 'None';
  String _focusArea = 'Full Body';
  String _injury = 'None';
  String _timePerSession = '30 mins';

  // ---- Loading / generating ----
  bool _isLoading = true;
  bool _isGenerating = false;
  String _loadingMessage = '';

  static const List<String> _goals = ['Build Muscle', 'Lose Weight', 'Get Fit', 'Increase Flexibility'];
  static const List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const List<String> _equipments = ['None', 'Dumbbells Only', 'Full Gym'];
  static const List<String> _focusAreas = ['Chest & Arms', 'Legs & Glutes', 'Core & Abs', 'Full Body'];
  static const List<String> _injuries = ['None', 'Knee Pain', 'Back Pain'];
  static const List<String> _times = ['15 mins', '30 mins', '45 mins'];

  // Honest, non-AI-claiming loading copy.
  static const List<String> _buildingMessages = [
    'Building your personalized plan...',
    'Putting together your weekly routine...',
    'Balancing training and rest days...',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndSteps();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Builds the step list from the profile's missing fields. If nothing is
  /// missing the planner skips straight to generation.
  Future<void> _loadProfileAndSteps() async {
    final profile = await UserProfileRepository.getProfile() ?? const UserProfile();
    final missing = await UserProfileRepository.getMissingFields();

    final steps = <_PlannerStep>[];
    if (missing.contains('name')) steps.add(_PlannerStep.name);
    if (missing.contains('goal')) steps.add(_PlannerStep.goal);
    if (missing.contains('experienceLevel')) steps.add(_PlannerStep.experienceLevel);
    if (missing.contains('equipment')) steps.add(_PlannerStep.equipment);
    if (missing.contains('timePerSession')) steps.add(_PlannerStep.timePerSession);
    if (missing.contains('injuries')) steps.add(_PlannerStep.injuries);
    if (steps.isNotEmpty) steps.add(_PlannerStep.focusArea);

    if (!mounted) return;
    setState(() {
      _workingProfile = profile;
      _steps = steps;
      _currentStep = 0;
      _nameController.text = profile.name ?? '';

      // Pre-seed single-select defaults from whatever the profile already has.
      if (profile.goal != null && _goals.contains(profile.goal)) _goal = profile.goal!;
      if (profile.experienceLevel != null && _levels.contains(profile.experienceLevel)) {
        _level = profile.experienceLevel!;
      }
      if (profile.equipment != null && _equipments.contains(profile.equipment)) {
        _equipment = profile.equipment!;
      }
      if (profile.timePerSession != null && _times.contains(profile.timePerSession)) {
        _timePerSession = profile.timePerSession!;
      }
      _injury = _injuryFromProfile(profile);
      _isLoading = false;
    });

    // No questions needed — go straight to generation.
    if (steps.isEmpty) {
      _generatePlan();
    }
  }

  String _injuryFromProfile(UserProfile profile) {
    final injuries = profile.injuries;
    if (injuries == null) return 'None';
    return injuries.isEmpty ? 'None' : injuries.first;
  }

  // --------------------------------------------------------------------------
  // Plan generation
  // --------------------------------------------------------------------------

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);
    _loadingMessage = _buildingMessages.first;

    // Rotate honest copy through the (short) delay.
    int messageIndex = 0;
    final messageTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        messageIndex = (messageIndex + 1) % _buildingMessages.length;
        _loadingMessage = _buildingMessages[messageIndex];
      });
    });

    // Keep load times short — the plan itself is generated locally.
    await Future.delayed(const Duration(milliseconds: 1200));
    messageTimer.cancel();

    try {
      final result = await WorkoutGeneratorService.generate7DayPlan(
        name: _workingProfile.name ?? _nameController.text.trim(),
        goal: _workingProfile.goal ?? _goal,
        level: _workingProfile.experienceLevel ?? _level,
        equipment: _workingProfile.equipment ?? _equipment,
        focusArea: _focusArea,
        injury: _workingProfile.injuries == null
            ? _injury
            : (_workingProfile.injuries!.isEmpty ? 'None' : _workingProfile.injuries!.first),
        timePerSession: _workingProfile.timePerSession ?? _timePerSession,
      );

      await StorageService.savePlan(
        Map<String, List<String>>.from(result['plan']),
        result['userName'],
        result['goal'],
        result['totalBurn'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PersonalizedDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // Step helpers
  // --------------------------------------------------------------------------

  _PlannerStep get _currentPlannerStep => _steps[_currentStep];

  bool get _isLastStep => _currentStep == _steps.length - 1;

  bool get _currentStepValid {
    switch (_currentPlannerStep) {
      case _PlannerStep.name:
        return _nameController.text.trim().isNotEmpty;
      default:
        return true; // single-select steps always have a valid default
    }
  }

  /// Persists the current step's answer to the DB + working profile so
  /// partial progress survives, then advances (or generates on the last step).
  Future<void> _handleNext() async {
    if (!_currentStepValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    await _saveCurrentStep();
    if (!mounted) return;

    if (_isLastStep) {
      _generatePlan();
    } else {
      setState(() => _currentStep++);
    }
  }

  Future<void> _saveCurrentStep() async {
    switch (_currentPlannerStep) {
      case _PlannerStep.name:
        final name = _nameController.text.trim();
        if (name.isNotEmpty) {
          await UserProfileRepository.updateField('name', name);
          _workingProfile = _workingProfile.copyWith(name: name);
        }
        break;
      case _PlannerStep.goal:
        await UserProfileRepository.updateField('goal', _goal);
        _workingProfile = _workingProfile.copyWith(goal: _goal);
        break;
      case _PlannerStep.experienceLevel:
        await UserProfileRepository.updateField('experienceLevel', _level);
        _workingProfile = _workingProfile.copyWith(experienceLevel: _level);
        break;
      case _PlannerStep.equipment:
        await UserProfileRepository.updateField('equipment', _equipment);
        _workingProfile = _workingProfile.copyWith(equipment: _equipment);
        break;
      case _PlannerStep.timePerSession:
        await UserProfileRepository.updateField('timePerSession', _timePerSession);
        _workingProfile = _workingProfile.copyWith(timePerSession: _timePerSession);
        break;
      case _PlannerStep.injuries:
        await UserProfileRepository.updateField(
          'injuries',
          _injury == 'None' ? <String>[] : <String>[_injury],
        );
        _workingProfile = _workingProfile.copyWith(
          injuries: _injury == 'None' ? <String>[] : <String>[_injury],
        );
        break;
      case _PlannerStep.focusArea:
        // Maybe persisted to preferences in future — not a profile field.
        break;
    }
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _isGenerating
              ? _buildLoadingState()
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (_currentStep + 1) / _steps.length,
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
    switch (_currentPlannerStep) {
      case _PlannerStep.name:
        return _buildNameStep();
      case _PlannerStep.goal:
        return _buildSelectionStep('What is your main goal?', _goals, _goal,
            (val) => setState(() => _goal = val!));
      case _PlannerStep.experienceLevel:
        return _buildSelectionStep('Choose your fitness level', _levels, _level,
            (val) => setState(() => _level = val!));
      case _PlannerStep.equipment:
        return _buildSelectionStep('What equipment do you have?', _equipments,
            _equipment, (val) => setState(() => _equipment = val!));
      case _PlannerStep.focusArea:
        return _buildSelectionStep('Which area to focus on?', _focusAreas,
            _focusArea, (val) => setState(() => _focusArea = val!));
      case _PlannerStep.timePerSession:
        return _buildSelectionStep('Time per session?', _times, _timePerSession,
            (val) => setState(() => _timePerSession = val!));
      case _PlannerStep.injuries:
        return _buildSelectionStep('Any injuries or limitations?', _injuries, _injury,
            (val) => setState(() => _injury = val!));
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
          onChanged: (_) => setState(() {}),
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
          child: RadioGroup<String>(
            groupValue: currentVal,
            onChanged: onChanged,
            child: RadioListTile<String>(
              title: Text(option, style: const TextStyle(fontWeight: FontWeight.bold)),
              value: option,
              activeColor: const Color(0xFF2563EB),
            ),
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
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(_isLastStep ? 'Generate Plan' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}