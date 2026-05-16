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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final name = await StorageService.getUserName();
    final goal = await StorageService.getUserGoal();
    final metric = await StorageService.getMetricUnit();
    final dark = await StorageService.getDarkMode();
    final reminder = await StorageService.getReminder();

    if (mounted) {
      setState(() {
        _userName = name ?? 'User';
        _userGoal = goal ?? 'Fitness';
        _isMetric = metric;
        _isDarkMode = dark;
        _isReminderOn = reminder;
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    String tempGoal = _userGoal;
    final goals = ['Build Muscle', 'Lose Weight', 'Get Fit', 'Increase Flexibility'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Your Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: goals.contains(tempGoal) ? tempGoal : goals.first,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setDialogState(() => tempGoal = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await StorageService.saveUserProfile(nameController.text, tempGoal);
                Navigator.pop(context);
                _loadSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRateUsDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(child: Text('Rate Our App', style: TextStyle(fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How do you like your workouts?', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 35),
                  onPressed: () => setDialogState(() => rating = index + 1),
                )),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('NOT NOW')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('SUBMIT')),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "1. Data Collection: We collect your name and fitness goals to personalize your workout plan. This data is stored locally on your device.\n\n"
                  "2. Local Storage: All your progress, including calories burned and workout durations, is saved using local storage (SharedPreferences). We do not upload this data to external servers.\n\n"
                  "3. Permissions: The app may require access to local storage to save your profile information and workout history.\n\n"
                  "4. Changes: We may update our Privacy Policy from time to time. You are advised to review this page periodically for any changes.",
                  style: TextStyle(height: 1.6, fontSize: 15, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900)),
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
                  Expanded(
                    child: Column(
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                    onPressed: _showEditProfileDialog,
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
            onTap: _showEditProfileDialog,
          ),

          _buildSectionHeader('Preferences'),
          SwitchListTile(
            activeColor: primaryColor,
            secondary: const Icon(Icons.straighten, color: primaryColor),
            title: const Text('Metric Units (kg/cm)'),
            value: _isMetric,
            onChanged: (val) async {
              await StorageService.saveMetricUnit(val);
              setState(() => _isMetric = val);
            },
          ),
          SwitchListTile(
            activeColor: primaryColor,
            secondary: const Icon(Icons.dark_mode_outlined, color: primaryColor),
            title: const Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (val) async {
              await StorageService.saveDarkMode(val);
              setState(() => _isDarkMode = val);
            },
          ),
          SwitchListTile(
            activeColor: primaryColor,
            secondary: const Icon(Icons.notifications_none, color: primaryColor),
            title: const Text('Workout Reminders'),
            value: _isReminderOn,
            onChanged: (val) async {
              await StorageService.saveReminder(val);
              setState(() => _isReminderOn = val);
            },
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
                _loadSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress data cleared')),
                );
              },
            ),
          ),

          _buildSectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.star_outline, color: primaryColor),
            title: const Text('Rate Us'),
            onTap: _showRateUsDialog,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: primaryColor),
            title: const Text('Privacy Policy'),
            onTap: _showPrivacyPolicy,
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
