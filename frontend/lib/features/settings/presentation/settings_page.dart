import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../core/token_store.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../family/presentation/family_page.dart';
import '../../reminders/presentation/reminder_page.dart';
import '../../auth/presentation/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int selectedTabIndex = 3;
  AppUser? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.get('/users/me/');
      if (!mounted) return;
      setState(() => _user = AppUser.fromJson(res.data));
    } on DioException catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await TokenStore.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      extendBody: true,
      appBar: const _SettingsHeader(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94E4D)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 138),
              children: [
                _ProfileCard(user: _user),
                const SizedBox(height: 16),
                _LogoutCard(onLogout: _logout),
              ],
            ),
      bottomNavigationBar: _SettingsBottomNavBar(
        currentIndex: selectedTabIndex,
        onTap: (index) {
          if (index == selectedTabIndex) return;
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
            return;
          }
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

class _SettingsHeader extends StatelessWidget implements PreferredSizeWidget {
  const _SettingsHeader();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFE94E4D),
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset('assets/images/logos/tahanan_logo.png',
              width: 32, height: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Text('TAHANAN',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 18)),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFFE94E4D), size: 18),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A4A4A))),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE94E4D),
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '—',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2A2A2A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user?.username ?? '—'}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9F9F9F)),
                      ),
                    ],
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

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A4A4A))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94E4D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBottomNavBar extends StatelessWidget {
  const _SettingsBottomNavBar({
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFFE94E4D),
            unselectedItemColor: const Color(0xFF9F9F9F),
            selectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.family_restroom_outlined),
                  activeIcon: Icon(Icons.family_restroom),
                  label: 'Family'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none),
                  activeIcon: Icon(Icons.notifications),
                  label: 'Reminders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
