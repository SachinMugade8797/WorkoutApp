import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation Controllers - control animation timing
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _breathController;

  // Animation values - what actually changes
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();

    // WHY: Fade animation - opacity goes from 0 to 1
    _fadeController = AnimationController(
      vsync: this,  // TickerProvider - needed for animations
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // WHY: Scale animation - logo grows from 80% to 100%
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // WHY: Breath animation - logo pulses gently
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _breathAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    // WHY: Start fade and scale after 500ms delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;  // Check if widget still exists
      _fadeController.forward();  // Start fade animation
      _scaleController.forward(); // Start scale animation
    });

    // WHY: Start breathing animation after 1.6 seconds
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _breathController.repeat(reverse: true); // Loop back and forth
    });

    // WHY: Navigate after 3.5 seconds (enough time for animations)
    Timer(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      
      // Check if user already completed onboarding
      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete = prefs.getBool('isOnboardingComplete') ?? false;
      
      if (!mounted) return;
      
      // Navigate to appropriate screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isOnboardingComplete
              ? const MainNavigation()  // Go to home
              : const OnboardingGenderScreen(), // Show onboarding
        ),
      );
    });
  }

  @override
  void dispose() {
    // WHY: Clean up animations to prevent memory leaks
    _fadeController.dispose();
    _scaleController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,  // Black background for logo
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,  // Applies fade animation
          child: ScaleTransition(
            scale: _scaleAnimation,  // Applies scale animation
            child: ScaleTransition(
              scale: _breathAnimation,  // Applies breath animation
              child: Image.asset(
                'assets/images/logo.png',  // Your logo image
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 80,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}