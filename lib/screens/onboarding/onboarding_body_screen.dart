import 'package:flutter/material.dart';

import '../../repositories/user_profile_repository.dart';
import 'onboarding_widgets.dart';

/// Part 2 of onboarding: age, gender, height (cm), weight (kg).
class OnboardingBodyScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const OnboardingBodyScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  State<OnboardingBodyScreen> createState() => _OnboardingBodyScreenState();
}

class _OnboardingBodyScreenState extends State<OnboardingBodyScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = 'Male';

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final ageStr = _ageController.text.trim();
    final heightStr = _heightController.text.trim();
    final weightStr = _weightController.text.trim();

    // Require all three numeric fields to be filled.
    if (ageStr.isEmpty || heightStr.isEmpty || weightStr.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your age, height and weight')),
      );
      return;
    }

    final age = int.tryParse(ageStr);
    final height = double.tryParse(heightStr);
    final weight = double.tryParse(weightStr);

    if (age == null || age < 10 || age > 100) {
      _showError('Age must be between 10 and 100');
      return;
    }
    if (height == null || height < 100 || height > 250) {
      _showError('Height must be between 100 and 250 cm');
      return;
    }
    if (weight == null || weight < 25 || weight > 300) {
      _showError('Weight must be between 25 and 300 kg');
      return;
    }

    // Persist each field so partial saves aren't lost.
    await Future.wait([
      UserProfileRepository.updateField('age', age),
      UserProfileRepository.updateField('gender', _gender),
      UserProfileRepository.updateField('height', height),
      UserProfileRepository.updateField('weight', weight),
    ]);

    if (mounted) widget.onContinue();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
              'Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'These numbers help us tailor calorie estimates.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 25),

            // --- Age ---
            _label('Age'),
            const SizedBox(height: 8),
            _numberField(_ageController, 'Years'),
            const SizedBox(height: 20),

            // --- Gender ---
            _label('Gender'),
            const SizedBox(height: 8),
            Row(
              children: [
                _genderCard('Male'),
                const SizedBox(width: 12),
                _genderCard('Female'),
              ],
            ),
            const SizedBox(height: 20),

            // --- Height ---
            _label('Height (cm)'),
            const SizedBox(height: 8),
            _numberField(_heightController, 'e.g. 175'),
            const SizedBox(height: 20),

            // --- Weight ---
            _label('Weight (kg)'),
            const SizedBox(height: 8),
            _numberField(_weightController, 'e.g. 70'),
            const SizedBox(height: 30),

            OnboardingActions(onContinue: _continue, onSkip: widget.onSkip),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _numberField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
    );
  }

  Widget _genderCard(String label) {
    const Color primary = Color(0xFF2563EB);
    final selected = _gender == label;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = label),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? primary : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}