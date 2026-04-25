import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../core/token_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../family/presentation/family_page.dart';
import '../../reminders/presentation/reminder_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedTabIndex = 0;
  final TextEditingController messageController = TextEditingController();

  AppUser? _user;
  List<Medicine> _medicines = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/users/me/'),
        ApiClient.instance.get('/medicines/'),
      ]);
      if (!mounted) return;
      setState(() {
        _user = AppUser.fromJson(results[0].data);
        _medicines = (results[1].data as List)
            .map((m) => Medicine.fromJson(m))
            .toList();
      });
    } on DioException catch (_) {
      // silently fail — page shows graceful fallbacks
    }
  }

  Future<void> _updateMood(String moodValue) async {
    try {
      await ApiClient.instance.patch('/users/me/', data: {'mood': moodValue});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood updated to $moodValue'),
          backgroundColor: const Color(0xFFE94E4D),
        ),
      );
      setState(() {
        if (_user != null) {
          _user = AppUser(
            id: _user!.id,
            username: _user!.username,
            firstName: _user!.firstName,
            lastName: _user!.lastName,
            familyId: _user!.familyId,
            mood: moodValue,
            checkedOn: _user!.checkedOn,
            inEmergency: _user!.inEmergency,
          );
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    try {
      await ApiClient.instance.post('/notes/', data: {'content': content.trim()});
      messageController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to family!'),
          backgroundColor: Color(0xFFE94E4D),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  Future<void> _logout() async {
    await TokenStore.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicine = _medicines.isNotEmpty ? _medicines.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE94E4D),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logos/tahanan_logo.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 10),
            Text(
              'TAHANAN',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFFE94E4D), size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE74E4E),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: GreetingHeader(
              name: _user?.displayName ?? '...',
              currentMood: _user?.mood,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              children: [
                MoodCheckInPanel(
                  currentMood: _user?.mood,
                  onMoodPressed: _updateMood,
                ),
                const SizedBox(height: 14),
                MedicationReminderPanel(medicine: medicine),
                const SizedBox(height: 14),
                QuickMessagePanel(
                  controller: messageController,
                  onPresetPressed: (message) {
                    messageController.text = message;
                  },
                  onSendPressed: () => _sendMessage(messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedTabIndex,
        onTap: (index) {
          if (index == selectedTabIndex) return;
          if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const FamilyPage()),
            );
            return;
          }
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ReminderPage()),
            );
            return;
          }
          setState(() => selectedTabIndex = index);
        },
      ),
    );
  }
}

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.name, this.currentMood});

  final String name;
  final String? currentMood;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(color: Colors.white, fontSize: 36, height: 1),
            children: [
              const TextSpan(text: 'Hello '),
              TextSpan(
                text: '$name!',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          currentMood != null
              ? 'You\'re feeling ${currentMood![0].toUpperCase()}${currentMood!.substring(1)} today.'
              : 'You haven\'t checked in today. Kamusta ka?',
          style: GoogleFonts.inter(
            color: const Color(0xFFF9BFBF),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class MoodCheckInPanel extends StatelessWidget {
  const MoodCheckInPanel({
    super.key,
    required this.onMoodPressed,
    this.currentMood,
  });

  final ValueChanged<String> onMoodPressed;
  final String? currentMood;

  @override
  Widget build(BuildContext context) {
    const moods = [
      _MoodData('sad', 'Sad', Icons.sentiment_dissatisfied, Color(0xFF9FA2D5)),
      _MoodData('happy', 'Happy', Icons.sentiment_satisfied, Color(0xFF9AA272)),
      _MoodData('excited', 'Excited', Icons.celebration, Color(0xFFE5CF7B)),
      _MoodData('crying', 'Crying', Icons.sentiment_very_dissatisfied, Color(0xFF7BA2D5)),
      _MoodData('angry', 'Angry', Icons.mood_bad, Color(0xFFE57373)),
    ];

    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shadowColor: const Color(0x26000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: moods
                    .map(
                      (mood) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: MoodItem(
                          data: mood,
                          isSelected: currentMood == mood.value,
                          onPressed: () => onMoodPressed(mood.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodItem extends StatelessWidget {
  const MoodItem({
    super.key,
    required this.data,
    required this.onPressed,
    this.isSelected = false,
  });

  final _MoodData data;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(44),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: data.color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: data.color,
              child: Icon(data.icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

class _MoodData {
  const _MoodData(this.value, this.label, this.icon, this.color);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class MedicationReminderPanel extends StatelessWidget {
  const MedicationReminderPanel({super.key, this.medicine});

  final Medicine? medicine;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shadowColor: const Color(0x26000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                medicine != null
                    ? 'Did you take your Medicine today?'
                    : 'No medicines scheduled.',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            if (medicine != null) ...[
              const SizedBox(height: 6),
              Text(
                'Take at ${medicine!.scheduledTime}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${medicine!.name}${medicine!.dosage != null ? ' — ${medicine!.dosage}' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: medicine!.isOverdue
                      ? Colors.red
                      : const Color(0xFFE74E4E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (medicine!.skipMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  medicine!.skipMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class QuickMessagePanel extends StatelessWidget {
  const QuickMessagePanel({
    super.key,
    required this.controller,
    required this.onPresetPressed,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onPresetPressed;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shadowColor: const Color(0x26000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF111111)),
                children: const [
                  TextSpan(text: 'Send a quick message to '),
                  TextSpan(
                    text: 'everyone',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _QuickPresetButton(
              label: 'Kamusta Kayo?',
              onPressed: () => onPresetPressed('Kamusta Kayo?'),
            ),
            const SizedBox(height: 10),
            _QuickPresetButton(
              label: 'Miss ko na kayo’ng lahat!',
              onPressed: () => onPresetPressed('Miss ko na kayo’ng lahat!'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Send a Message',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE3E3E3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 58,
                  width: 58,
                  child: ElevatedButton(
                    onPressed: onSendPressed,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: const Color(0xFFE94E4D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Transform.rotate(
                      angle: -0.7854,
                      child: const Icon(Icons.send_rounded, size: 26, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPresetButton extends StatelessWidget {
  const _QuickPresetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94E4D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFFFFFFF),
            elevation: 0,
            selectedItemColor: const Color(0xFFE94E4D),
            unselectedItemColor: const Color(0xFF9F9F9F),
            selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.family_restroom_outlined),
                activeIcon: Icon(Icons.family_restroom),
                label: 'Family',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none),
                activeIcon: Icon(Icons.notifications),
                label: 'Reminders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
