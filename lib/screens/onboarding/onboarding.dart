import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';

class OnboardingGenderScreen extends StatefulWidget {
  const OnboardingGenderScreen({super.key});
  @override
  State<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends State<OnboardingGenderScreen> {
  String? selectedGender;

  Future<void> _completeOnboarding() async {
    if (selectedGender == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    await prefs.setString('gender', selectedGender!);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('Select your gender', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Choose to personalize your workout experience', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 40),
              Expanded(
                child: Row(
                  children: [
                    _card('man', 'Man', 'assets/images/men.jpg'),
                    const SizedBox(width: 16),
                    _card('woman', 'Woman', 'assets/images/women.jpg'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: selectedGender != null ? _completeOnboarding : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: _skip,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8F8F8),
                    foregroundColor: const Color(0xFF9E9E9E),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String gender, String label, String img) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300, width: isSelected ? 2.5 : 1),
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(img, fit: BoxFit.cover, width: double.infinity)))),
              Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF2563EB) : Colors.black)),
              const SizedBox(height: 12),
              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}