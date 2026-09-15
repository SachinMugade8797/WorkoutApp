import 'package:flutter/material.dart';

import '../../repositories/user_profile_repository.dart';
import 'onboarding_widgets.dart';

/// Part 3 of onboarding: training goal.
class OnboardingGoalScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingGoalScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingGoalScreen> createState() => _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends State<OnboardingGoalScreen> {
  String? _selected;

  static const List<Map<String, String>> _options = [
    {'value': 'Build Muscle',      'desc': 'Progressive overload, higher volume'},
    {'value': 'Lose Weight',       'desc': 'Caloric deficit, higher reps'},
    {'value': 'Endurance',         'desc': 'Muscular endurance, circuit-style'},
    {'value': 'General Fitness',   'desc': 'Mix of strength and cardio'},
  ];

  Future<void> _continue() async {
    if (_selected == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a goal')),
      );
      return;
    }
    await UserProfileRepository.updateField('goal', _selected);
    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your primary goal?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'We optimise workout structure around this.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          ..._options.map((o) => OnboardingOptionCard(
                title: o['value']!,
                subtitle: o['desc'],
                icon: _iconFor(o['value']!),
                isSelected: _selected == o['value'],
                onTap: () => setState(() => _selected = o['value']),
              )),
          const Spacer(),
          OnboardingActions(onContinue: _continue, onSkip: widget.onSkip),
        ],
      ),
    );
  }

  IconData _iconFor(String value) {
    switch (value) {
      case 'Build Muscle':    return Icons.fitness_center;
      case 'Lose Weight':     return Icons.local_fire_department_outlined;
      case 'Endurance':       return Icons.timer_outlined;
      case 'General Fitness': return Icons.sports_gymnastics;
      default:                return Icons.help_outline;
    }
  }
}