import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../services/storage_service.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final List<String> exerciseIds;
  final int startIndex;

  const WorkoutPlayerScreen({
    super.key, 
    required this.exerciseIds, 
    this.startIndex = 0
  });

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  late List<WorkoutExercise> _exercises;
  late int _currentIndex;
  int _secondsElapsed = 0;
  int _totalSessionCalories = 0;
  int _lastExerciseTimestamp = 0;
  Timer? _timer;
  bool _isPaused = false;
  bool _isResting = false;
  int _restTimeRemaining = 30;
  Timer? _restTimer;
  String _userLevel = 'Beginner';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _exercises = widget.exerciseIds
        .map((id) => masterExerciseList.firstWhere((e) => e.id == id,
            orElse: () => masterExerciseList.first))
        .toList();
    _loadUserLevel();
    _startTimer();
    _saveSessionData();
  }

  Future<void> _loadUserLevel() async {
    final level = await StorageService.getUserLevel();
    setState(() => _userLevel = level);
  }

  Future<void> _saveSessionData() async {
    await StorageService.saveActiveWorkoutIds(widget.exerciseIds);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isResting) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _calculateCalsForFinishedExercise() {
    final currentEx = _exercises[_currentIndex];
    final timeSpentInSeconds = _secondsElapsed - _lastExerciseTimestamp;
    final minutesSpent = timeSpentInSeconds / 60.0;
    _totalSessionCalories += (currentEx.caloriesPerMinute * minutesSpent).round();
    _lastExerciseTimestamp = _secondsElapsed;
  }

  void _nextExercise() {
    _calculateCalsForFinishedExercise();
    if (_currentIndex < _exercises.length - 1) {
      _startRest();
    } else {
      _finishWorkout();
    }
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _restTimeRemaining = 30;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        setState(() => _restTimeRemaining--);
      } else {
        _skipRest();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentIndex++;
    });
    StorageService.saveCurrentWorkoutIndex(_currentIndex);
  }

  void _finishWorkout() async {
    _timer?.cancel();
    _restTimer?.cancel();
    
    await StorageService.saveWorkoutProgress(_totalSessionCalories, (_secondsElapsed / 60).round());
    await StorageService.updateStreak();
    await StorageService.clearMissedExercises();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Workout Complete! 🎉', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text('You burned $_totalSessionCalories kcal in ${(_secondsElapsed / 60).toStringAsFixed(1)} minutes.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('AWESOME', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            )
          ],
        ),
      );
    }
  }

  void _showPauseOverlay() {
    setState(() => _isPaused = true);
  }

  void _stopAndSave() async {
    _calculateCalsForFinishedExercise();
    await StorageService.saveCurrentWorkoutIndex(_currentIndex);
    await StorageService.saveWorkoutProgress(_totalSessionCalories, (_secondsElapsed / 60).round());
    await StorageService.setIsWorkoutActive(true);
    
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _getSetsReps(WorkoutExercise ex) {
    if (ex.id == 'ab_03') { // Plank
      return "3 Sets x 45 Sec";
    }
    return _userLevel == 'Advanced' ? "4 Sets x 15 Reps" : "3 Sets x 12 Reps";
  }

  @override
  Widget build(BuildContext context) {
    final currentEx = _exercises[_currentIndex];
    final progress = (_currentIndex + 1) / _exercises.length;
    final gifPath = 'assets/gifs/${currentEx.id}.gif';
    print('Attempting to load GIF: $gifPath');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => _showPauseOverlay(),
        ),
        title: Text(
          'Exercise ${_currentIndex + 1} of ${_exercises.length}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                color: const Color(0xFF2563EB),
                minHeight: 8,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            gifPath,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              print('FAILED to load GIF at: $gifPath');
                              return const Center(
                                child: Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _getSetsReps(currentEx),
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB)
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentEx.name,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentEx.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(_secondsElapsed),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              _buildControls(),
            ],
          ),
          if (_isPaused) _buildPauseOverlayWidget(),
          if (_isResting) _buildRestOverlayWidget(),
        ],
      ),
    );
  }

  Widget _buildRestOverlayWidget() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: const Color(0xFF2563EB).withOpacity(0.9),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'REST',
              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            Text(
              '$_restTimeRemaining',
              style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.w200),
            ),
            const SizedBox(height: 40),
            Text(
              'UP NEXT: ${_currentIndex + 1 < _exercises.length ? _exercises[_currentIndex + 1].name : "Finish"}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _skipRest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('SKIP REST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlayWidget() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'WORKOUT PAUSED',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isPaused = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('RESUME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: _stopAndSave,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('SAVE & QUIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: _showPauseOverlay,
            icon: const Icon(Icons.pause),
            iconSize: 32,
            padding: const EdgeInsets.all(16),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _currentIndex < _exercises.length - 1 ? 'NEXT EXERCISE' : 'FINISH WORKOUT',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
