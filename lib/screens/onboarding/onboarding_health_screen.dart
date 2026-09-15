import 'package:flutter/material.dart';

import '../../repositories/user_profile_repository.dart';
import 'onboarding_widgets.dart';

/// Part 5 of onboarding: injuries / limitations.
///
/// Single-select. Choosing "None" saves an *empty* list (meaning "no
/// injuries" — that counts as an answered field). Anyone who skips this step
/// leaves injuries null (never answered).
class OnboardingHealthScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingHealthScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingHealthScreen> createState() => _OnboardingHealthScreenState();
}

class _OnboardingHealthScreenState extends State<OnboardingHealthScreen> {
  static const List<String> _injuryOptions = [
    'None',
    'Back',
    'Shoulder',
    'Knee',
    'Ankle',
    'Neck',
  ];
  String? _selected;

  Future<void> _continue() async {
    await UserProfileRepository.updateField(
      'injuries',
      _selected == null || _selected == 'None' ? <String>[] : <String>[_selected!],
    );
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
            'Any injuries we should avoid?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll keep these areas out of your workout plan.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          ..._injuryOptions.map((option) => OnboardingOptionCard(
                title: option,
                icon: option == 'None'
                    ? Icons.check_circle_outline
                    : Icons.healing_outlined,
                isSelected: _selected == option,
                onTap: () => setState(() => _selected = option),
              )),
          const Spacer(),
          OnboardingActions(
            onContinue: _continue,
            onSkip: widget.onSkip,
            continueLabel: 'FINISH',
          ),
        ],
      ),
    );
  }
}