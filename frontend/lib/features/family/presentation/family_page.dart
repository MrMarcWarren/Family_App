import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../reminders/presentation/reminder_page.dart';
import '../../settings/presentation/settings_page.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  int selectedTabIndex = 1;
  List<FamilyMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      final userRes = await ApiClient.instance.get('/users/me/');
      final user = AppUser.fromJson(userRes.data);
      if (user.familyId == null) return;

      final membersRes =
          await ApiClient.instance.get('/families/${user.familyId}/members/');
      if (!mounted) return;
      setState(() {
        _members = (membersRes.data as List)
            .map((m) => FamilyMember.fromJson(m))
            .toList();
      });
    } on DioException catch (_) {
      // silently fail
    }
  }

  Future<void> _checkOn(FamilyMember member) async {
    try {
      await ApiClient.instance.patch('/users/${member.id}/check-on/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked on ${member.displayName}!'),
          backgroundColor: const Color(0xFFE94E4D),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  Future<void> _toggleEmergency() async {
    try {
      final res = await ApiClient.instance.patch('/users/emergency/toggle');
      final isOn = res.data['in_emergency'] as bool? ?? false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isOn ? 'Emergency alert activated!' : 'Emergency alert deactivated.'),
          backgroundColor: isOn ? Colors.red : const Color(0xFFE94E4D),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      extendBody: true,
      appBar: const FamilyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 138),
        children: [
          _EmergencyAlertPanel(onToggle: _toggleEmergency),
          const SizedBox(height: 12),
          FamilyMembersPanel(members: _members),
          const SizedBox(height: 12),
          FamilyMapPanel(members: _members),
          const SizedBox(height: 12),
          FamilyCheckInPanel(
            members: _members,
            onCheckOn: _checkOn,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedTabIndex,
        onTap: (index) {
          if (index == selectedTabIndex) return;
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
            return;
          }
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ReminderPage()),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
            return;
          }
          setState(() => selectedTabIndex = index);
        },
      ),
    );
  }
}

void _showFamilyCheckInModal(BuildContext context, FamilyMember member,
    VoidCallback onCheckOn) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return FamilyCheckInModal(
        name: member.displayName,
        statusText: 'Status: Feeling ${member.mood[0].toUpperCase()}${member.mood.substring(1)}',
        onCheckOnThem: () {
          Navigator.of(dialogContext).pop();
          onCheckOn();
        },
        onMessage: () => Navigator.of(dialogContext).pop(),
        onCall: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

void _showFamilyProfileModal(BuildContext context, FamilyMember member,
    VoidCallback onCheckOn) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return FamilyProfileModal(
        name: member.displayName,
        statusText: 'Status: Feeling ${member.mood[0].toUpperCase()}${member.mood.substring(1)}',
        onCheckOnThem: () {
          Navigator.of(dialogContext).pop();
          onCheckOn();
        },
        onAddReminder: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class FamilyHeader extends StatelessWidget implements PreferredSizeWidget {
  const FamilyHeader({super.key});

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
          Image.asset('assets/images/logos/tahanan_logo.png', width: 32, height: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'TAHANAN',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 18),
            ),
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

class FamilyMembersPanel extends StatelessWidget {
  const FamilyMembersPanel({super.key, required this.members});

  final List<FamilyMember> members;

  static const _moodColors = {
    'happy': Color(0xFF9AA272),
    'sad': Color(0xFF9FA2D5),
    'excited': Color(0xFFE5CF7B),
    'crying': Color(0xFF7BA2D5),
    'angry': Color(0xFFE57373),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Family',
              style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 12),
            members.isEmpty
                ? Text(
                    'No family members yet.',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9F9F9F)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: members.map((member) {
                      final color =
                          _moodColors[member.mood] ?? const Color(0xFFD5D5D5);
                      return Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _showFamilyProfileModal(context, member, () {}),
                              child: Stack(
                                alignment: Alignment.bottomLeft,
                                children: [
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFD5D5D5),
                                  ),
                                  CircleAvatar(radius: 9, backgroundColor: color),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              member.displayName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111111)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class FamilyMapPanel extends StatelessWidget {
  const FamilyMapPanel({super.key, required this.members});

  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final membersWithLocation =
        members.where((m) => m.latitude != null && m.longitude != null).toList();

    final LatLng center = membersWithLocation.isNotEmpty
        ? LatLng(membersWithLocation.first.latitude!,
            membersWithLocation.first.longitude!)
        : const LatLng(14.5764, 121.0851);

    final markers = membersWithLocation
        .map(
          (member) => Marker(
            point: LatLng(member.latitude!, member.longitude!),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showFamilyProfileModal(context, member, () {}),
              child: Tooltip(
                message: member.displayName,
                child: const CircleAvatar(backgroundColor: Colors.white),
              ),
            ),
          ),
        )
        .toList();

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14.5),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.family_test_1',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FamilyCheckInPanel extends StatelessWidget {
  const FamilyCheckInPanel({
    super.key,
    required this.members,
    required this.onCheckOn,
  });

  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onCheckOn;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check up on your Family',
              style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 10),
            if (members.isEmpty)
              Text(
                'No family members to check on.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9F9F9F)),
              )
            else
              ...members.map(
                (member) => _CheckInEntry(
                  name: member.displayName,
                  mood: member.mood,
                  onPressed: () => _showFamilyCheckInModal(
                    context,
                    member,
                    () => onCheckOn(member),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckInEntry extends StatelessWidget {
  const _CheckInEntry({
    required this.name,
    required this.mood,
    required this.onPressed,
  });

  final String name;
  final String mood;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: const Color(0xFFF6F6F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Feeling: ${mood[0].toUpperCase()}${mood.substring(1)}',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7B7B7B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94E4D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                  ),
                  child: Text('Check on them',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FamilyProfileModal extends StatelessWidget {
  const FamilyProfileModal({
    super.key,
    required this.name,
    required this.statusText,
    required this.onCheckOnThem,
    required this.onAddReminder,
  });

  final String name;
  final String statusText;
  final VoidCallback onCheckOnThem;
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 24, backgroundColor: Color(0xFFD9D9D9)),
            const SizedBox(height: 12),
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3F3F3F))),
            const SizedBox(height: 6),
            Text(statusText,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9B9B9B))),
            const SizedBox(height: 12),
            _ModalActionButton(label: 'Check on them', onPressed: onCheckOnThem),
            const SizedBox(height: 8),
            _ModalActionButton(label: 'Add Reminder', onPressed: onAddReminder),
          ],
        ),
      ),
    );
  }
}

class FamilyCheckInModal extends StatelessWidget {
  const FamilyCheckInModal({
    super.key,
    required this.name,
    required this.statusText,
    required this.onCheckOnThem,
    required this.onMessage,
    required this.onCall,
  });

  final String name;
  final String statusText;
  final VoidCallback onCheckOnThem;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 20, backgroundColor: Colors.white),
            const SizedBox(height: 10),
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3F3F3F))),
            const SizedBox(height: 6),
            Text(statusText,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9B9B9B))),
            const SizedBox(height: 12),
            _ModalActionButton(label: 'Check on them', onPressed: onCheckOnThem),
            const SizedBox(height: 8),
            _ModalActionButton(label: 'Message', onPressed: onMessage),
            const SizedBox(height: 8),
            _ModalActionButton(label: 'Call', onPressed: onCall),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE94E4D), width: 1),
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gentle Guide',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D2D2D))),
                  const SizedBox(height: 4),
                  Text(
                    '"Try to invite for a drink, send a Meme, try to\ncheer up the person"',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8E8E8E)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalActionButton extends StatelessWidget {
  const _ModalActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94E4D),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _EmergencyAlertPanel extends StatelessWidget {
  const _EmergencyAlertPanel({required this.onToggle});

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Alert',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Press to alert your family that you need help.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7B7B7B)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onToggle,
                icon: const Icon(Icons.warning_amber_rounded),
                label: Text('Toggle Emergency',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
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
          color: Colors.white,
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
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFFE94E4D),
            unselectedItemColor: const Color(0xFF9F9F9F),
            selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
