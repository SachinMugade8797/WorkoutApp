import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'diet_form_screen.dart';
import 'diet_dashboard_screen.dart';

class DietPlannerScreen extends StatefulWidget {
  const DietPlannerScreen({super.key});

  @override
  State<DietPlannerScreen> createState() => _DietPlannerScreenState();
}

class _DietPlannerScreenState extends State<DietPlannerScreen> {
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final profile = await StorageService.getDietProfile();
    if (mounted) {
      setState(() {
        _hasProfile = profile != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    return _hasProfile 
        ? const DietDashboardScreen() 
        : DietFormScreen(onComplete: _checkProfile);
  }
}
