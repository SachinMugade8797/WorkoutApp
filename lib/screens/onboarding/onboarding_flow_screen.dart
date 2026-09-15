import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../main.dart';
import 'onboarding_body_screen.dart';
import 'onboarding_environment_screen.dart';
import 'onboarding_goal_screen.dart';
import 'onboarding_health_screen.dart';
import 'onboarding_identity_screen.dart';

/// Multi-screen onboarding flow.
///
/// Shows a page indicator ("1 of 5"), 5 scrollable parts on a PageView,
/// and a stacked "SKIP FOR NOW" / "CONTINUE" action row.
///
/// Every part is independently skippable — whatever was filled is saved, and
/// missing fields simply keep the planner showing extra questions later.
///
/// Parts:
///   1. Identity  (name)
///   2. Body      (age, gender, height, weight)
///   3. Goal      (goal type)
///   4. Environment (equipment, location, time per session)
///   5. Health    (injuries)
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalParts = 5;

  void _goToNext() {
    if (_currentPage < _totalParts - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() {
    if (_currentPage < _totalParts - 1) {
      _goToNext();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await StorageService.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'FitForge Setup',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Part ${_currentPage + 1} of $_totalParts',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalParts,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                OnboardingIdentityScreen(
                  onContinue: _goToNext,
                  onSkip: _skip,
                ),
                OnboardingBodyScreen(
                  onContinue: _goToNext,
                  onSkip: _skip,
                ),
                OnboardingGoalScreen(
                  onContinue: _goToNext,
                  onSkip: _skip,
                ),
                OnboardingEnvironmentScreen(
                  onContinue: _goToNext,
                  onSkip: _skip,
                ),
                OnboardingHealthScreen(
                  onContinue: _finish,
                  onSkip: _skip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}