import 'dart:async';
import 'package:flutter/material.dart';

class DietLoadingScreen extends StatefulWidget {
  const DietLoadingScreen({super.key});

  @override
  State<DietLoadingScreen> createState() => _DietLoadingScreenState();
}

class _DietLoadingScreenState extends State<DietLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0;
  String _loadingText = 'Analyzing your profile...';
  final List<String> _messages = [
    'Analyzing your profile...',
    'Calculating nutritional requirements...',
    'Selecting best meal options for you...',
    'Optimizing macro-nutrient balance...',
    'Finalizing your 7-day plan...',
  ];
  int _messageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _progress = _controller.value;
        });
      });
    
    _controller.forward().then((_) {
      if (mounted) Navigator.pop(context);
    });

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
          _loadingText = _messages[_messageIndex];
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon/Logo placeholder
            const Icon(Icons.restaurant_menu, size: 80, color: Color(0xFF2563EB)),
            const SizedBox(height: 40),
            
            const Text(
              'Creating your personalized diet plan...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 50),
            
            // Progress Indicator
            Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                ),
                FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF60A5FA)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 40),
            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _loadingText,
                key: ValueKey(_loadingText),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
