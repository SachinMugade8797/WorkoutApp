import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'User';
  String _userGoal = 'Fitness';
  bool _isMetric = true;
  bool _isDarkMode = false;
  bool _isReminderOn = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await StorageService.getUserName();
    final goal = await StorageService.getUserGoal();
    if (mounted) {
      setState(() {
        _userName = name ?? 'User';
        _userGoal = goal ?? 'Fitness';
      });
    }
  }

  void _showResetConfirmation(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Section 1: User Profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: primaryColor, size: 35),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Goal: $_userGoal',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: primaryColor),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          _buildSectionHeader('Preferences'),
          SwitchListTile(
            activeColor: primaryColor,
            secondary: const Icon(Icons.straighten, color: primaryColor),
            title: const Text('Metric Units (kg/cm)'),
            value: _isMetric,
            onChanged: (val) => setState(() => _isMetric = val),
          ),
          SwitchListTile(
            activeColor: primaryColor,
            secondary: const Icon(Icons.dark_mode_outlined, color: primaryColor),
            title: const Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (val) => setState(() => _isDarkMode = val),
          ),
          SwitchListTile(
            activeColor: primaryColor,
            secondary: const Icon(Icons.notifications_none, color: primaryColor),
            title: const Text('Workout Reminders'),
            value: _isReminderOn,
            onChanged: (val) => setState(() => _isReminderOn = val),
          ),

          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.red),
            title: const Text('Reset Workout Plan', style: TextStyle(color: Colors.red)),
            onTap: () => _showResetConfirmation(
              'Reset Plan?',
              'This will clear your current AI-generated plan. You will need to create a new one.',
              () async {
                await StorageService.clearPlan();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            title: const Text('Clear Progress Data', style: TextStyle(color: Colors.red)),
            onTap: () => _showResetConfirmation(
              'Clear Progress?',
              'This will permanently delete your total calories, minutes, and streaks. This cannot be undone.',
              () async {
                await StorageService.clearAllProgress();
                _loadUserInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress data cleared')),
                );
              },
            ),
          ),

          _buildSectionHeader('Support'),
          const ListTile(
            leading: Icon(Icons.star_outline, color: primaryColor),
            title: Text('Rate Us'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
            title: Text('Privacy Policy'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: primaryColor),
            title: Text('App Version'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
