import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';  // Import to access MainNavigation

class OnboardingGenderScreen extends StatefulWidget {
  const OnboardingGenderScreen({super.key});
  
  @override
  State<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends State<OnboardingGenderScreen> {
  // Track selected gender - null means nothing selected
  String? selectedGender;

  // Called when user taps "Next" after selecting gender
  Future<void> _completeOnboarding() async {
    // Guard clause - prevent if no gender selected
    if (selectedGender == null) return;
    
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingComplete', true);
    await prefs.setString('gender', selectedGender!);

    // Navigate to main app
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  // Called when user taps "Skip" - no gender required
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
      body: SafeArea(  // Avoids notch/status bar
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Select your gender',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose to personalize your workout experience',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              
              // Two cards side by side (Man & Woman)
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
              
              // Next Button - disabled until gender selected
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedGender != null ? _completeOnboarding : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Skip Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _skip,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8F8F8),
                    foregroundColor: const Color(0xFF9E9E9E),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

  // Helper widget for gender card
  Widget _card(String gender, String label, String img) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF2563EB)  // Blue border when selected
                  : Colors.grey.shade300,    // Grey border when not selected
              width: isSelected ? 2.5 : 1,
            ),
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image not found
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            gender == 'man' 
                                ? Icons.person 
                                : Icons.person_outline,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Label
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF2563EB) : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              
              // Checkmark when selected
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2563EB),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}