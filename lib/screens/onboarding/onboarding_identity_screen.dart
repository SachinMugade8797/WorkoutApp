import 'package:flutter/material.dart';

import '../../repositories/user_profile_repository.dart';
import 'onboarding_widgets.dart';

/// Part 1 of onboarding: the user's name.
class OnboardingIdentityScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingIdentityScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingIdentityScreen> createState() => _OnboardingIdentityScreenState();
}

class _OnboardingIdentityScreenState extends State<OnboardingIdentityScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Saves the name (if provided) then moves to the next part.
  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await UserProfileRepository.updateField('name', name);
    }
    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your name?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use it to make your plans feel personal.",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
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
                borderSide: const BorderSide(color: primary, width: 2),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          OnboardingActions(onContinue: _continue, onSkip: widget.onSkip),
        ],
      ),
    );
  }
}