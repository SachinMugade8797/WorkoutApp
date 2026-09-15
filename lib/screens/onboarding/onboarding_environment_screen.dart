import 'package:flutter/material.dart';

import '../../repositories/user_profile_repository.dart';
import 'onboarding_widgets.dart';

/// Part 4 of onboarding: equipment, training location, available time.
class OnboardingEnvironmentScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingEnvironmentScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingEnvironmentScreen> createState() =>
      _OnboardingEnvironmentScreenState();
}

class _OnboardingEnvironmentScreenState extends State<OnboardingEnvironmentScreen> {
  String? _selectedEquipment;
  String? _selectedLocation;
  String? _selectedTime;

  static const List<Map<String, String>> _equipment = [
    {'value': 'Full Gym',        'desc': 'Barbells, dumbbells, machines, cables'},
    {'value': 'Basic Weights',   'desc': 'Dumbbells and/or a kettlebell'},
    {'value': 'Bodyweight Only', 'desc': 'No equipment needed'},
    {'value': 'Resistance Bands','desc': 'Band-based training'},
  ];

  static const List<Map<String, String>> _locations = [
    {'value': 'Gym',    'desc': 'Commercial or home gym'},
    {'value': 'Home',   'desc': 'Bedroom, garage, living room'},
    {'value': 'Park',   'desc': 'Outdoor workouts'},
  ];

  static const List<Map<String, String>> _times = [
    {'value': '30 minutes',  'desc': 'Quick, focused sessions'},
    {'value': '45 minutes',  'desc': 'Moderate length'},
    {'value': '60+ minutes', 'desc': 'Full, relaxed sessions'},
  ];

  bool get _canContinue =>
      _selectedEquipment != null && _selectedLocation != null && _selectedTime != null;

  Future<void> _continue() async {
    if (!_canContinue) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make a selection in each category')),
      );
      return;
    }
    await Future.wait([
      UserProfileRepository.updateField('equipment', _selectedEquipment),
      UserProfileRepository.updateField('workoutLocation', _selectedLocation),
      UserProfileRepository.updateField('timePerSession', _selectedTime),
    ]);
    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's your setup?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'This shapes which exercises we suggest.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            // --- Equipment ---
            const SizedBox(height: 25),
            _sectionLabel('Equipment'),
            ..._equipment.map((o) => OnboardingOptionCard(
                  title: o['value']!,
                  subtitle: o['desc'],
                  icon: _equipIcon(o['value']!),
                  isSelected: _selectedEquipment == o['value'],
                  onTap: () => setState(() => _selectedEquipment = o['value']),
                )),

            // --- Location ---
            _sectionLabel('Training Location'),
            ..._locations.map((o) => OnboardingOptionCard(
                  title: o['value']!,
                  subtitle: o['desc'],
                  icon: _locIcon(o['value']!),
                  isSelected: _selectedLocation == o['value'],
                  onTap: () => setState(() => _selectedLocation = o['value']),
                )),

            // --- Time ---
            _sectionLabel('Time per Session'),
            ..._times.map((o) => OnboardingOptionCard(
                  title: o['value']!,
                  subtitle: o['desc'],
                  icon: Icons.access_time,
                  isSelected: _selectedTime == o['value'],
                  onTap: () => setState(() => _selectedTime = o['value']),
                )),

            const SizedBox(height: 20),
            OnboardingActions(onContinue: _continue, onSkip: widget.onSkip),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  IconData _equipIcon(String v) {
    switch (v) {
      case 'Full Gym':        return Icons.fitness_center;
      case 'Basic Weights':   return Icons.fitness_center;
      case 'Bodyweight Only': return Icons.self_improvement;
      case 'Resistance Bands':return Icons.sports_martial_arts;
      default:                return Icons.help_outline;
    }
  }

  IconData _locIcon(String v) {
    switch (v) {
      case 'Gym':  return Icons.fitness_center;
      case 'Home': return Icons.home_outlined;
      case 'Park': return Icons.park_outlined;
      default:     return Icons.help_outline;
    }
  }
}