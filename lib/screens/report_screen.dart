import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with RouteAware {
  int totalCalories = 0;
  int totalMinutes = 0;
  int streak = 0;
  List<String> completedDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Reload data whenever dependencies change or when returning to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final cals = await StorageService.getTotalCalories();
    final mins = await StorageService.getTotalMinutes();
    final st = await StorageService.getStreak();
    final dates = await StorageService.getCompletedDates();

    if (mounted) {
      setState(() {
        totalCalories = cals;
        totalMinutes = mins;
        streak = st;
        completedDates = dates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('MY PROGRESS', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity Calendar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    'Last 30 Days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 32),
              _buildWeeklyChartStub(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Calories',
            totalCalories.toString(),
            'kcal',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Duration',
            totalMinutes.toString(),
            'min',
            Icons.access_time_filled,
            const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Streak',
            streak.toString(),
            'days',
            Icons.bolt,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    // Show last 30 days
    final daysToDisplay = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.start,
        children: daysToDisplay.map((date) {
          final dateStr = date.toIso8601String().split('T')[0];
          bool isCompleted = completedDates.contains(dateStr);
          bool isToday = dateStr == now.toIso8601String().split('T')[0];

          return Tooltip(
            message: DateFormat('MMM d, yyyy').format(date),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? const Color(0xFF2563EB) 
                    : (isToday ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isCompleted 
                    ? Border.all(color: const Color(0xFF2563EB), width: 1.5) 
                    : null,
              ),
              child: Center(
                child: isCompleted 
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? const Color(0xFF2563EB) : Colors.black38,
                      ),
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyChartStub() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Mock data for visual weight
    final heights = [0.4, 0.7, 0.3, 0.9, 0.5, 0.2, 0.1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Intensity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 16,
                      height: 80 * heights[index],
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      days[index],
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
