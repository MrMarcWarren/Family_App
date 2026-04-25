import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  int selectedTabIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      extendBody: true,
      appBar: const FamilyHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 138),
        children: const [
          FamilyMembersPanel(),
          SizedBox(height: 12),
          FamilyMapPanel(),
          SizedBox(height: 12),
          FamilyCheckInPanel(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedTabIndex,
        onTap: (index) {
          setState(() {
            selectedTabIndex = index;
          });
        },
      ),
    );
  }
}

void _showFamilyCheckInModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return FamilyCheckInModal(
        name: 'Name Name Name',
        statusText: 'Status: Feeling Happy (2hrs ago)',
        onCheckOnThem: () {},
        onMessage: () {},
        onCall: () {},
      );
    },
  );
}

void _showFamilyProfileModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return FamilyProfileModal(
        name: 'Name Name Name',
        statusText: 'Status: Feeling Happy (2hrs ago)',
        onCheckOnThem: () {},
        onAddReminder: () {},
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
          Image.asset(
            'assets/images/logos/tahanan_logo.png',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'TAHANAN',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 18,
              ),
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
  const FamilyMembersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final memberColors = <Color>[
      const Color(0xFF9FA2D5),
      const Color(0xFFE74E4E),
      const Color(0xFFE74E4E),
      const Color(0xFFF0C94D),
      const Color(0xFF86A9D8),
    ];

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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(memberColors.length, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showFamilyProfileModal(context),
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xFFD5D5D5),
                            ),
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: memberColors[index],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Name Here',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyMapPanel extends StatelessWidget {
  const FamilyMapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: const LatLng(14.5764, 121.0851),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showFamilyProfileModal(context),
          child: const CircleAvatar(
            backgroundColor: Colors.white,
          ),
        ),
      ),
      Marker(
        point: const LatLng(14.5782, 121.0837),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showFamilyProfileModal(context),
          child: const CircleAvatar(
            backgroundColor: Colors.white,
          ),
        ),
      ),
      Marker(
        point: const LatLng(14.5749, 121.0869),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showFamilyProfileModal(context),
          child: const CircleAvatar(
            backgroundColor: Colors.white,
          ),
        ),
      ),
    ];

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
              options: const MapOptions(
                initialCenter: LatLng(14.5764, 121.0851),
                initialZoom: 14.5,
              ),
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
  const FamilyCheckInPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final members = List.generate(3, (index) {
      return _CheckInEntry(
        name: 'Nickname of Family',
        lastCheckedIn: 'Last Checked in 8:15pm',
        onPressed: () => _showFamilyCheckInModal(context),
      );
    });

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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 10),
            ...members,
          ],
        ),
      ),
    );
  }
}

class _CheckInEntry extends StatelessWidget {
  const _CheckInEntry({
    required this.name,
    required this.lastCheckedIn,
    required this.onPressed,
  });

  final String name;
  final String lastCheckedIn;
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
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
              ),
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
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastCheckedIn,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7B7B7B),
                      ),
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
                      borderRadius: BorderRadius.circular(11),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Check on them',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3F3F3F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9B9B9B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            _ModalActionButton(
              label: 'Check on them',
              onPressed: onCheckOnThem,
            ),
            const SizedBox(height: 8),
            _ModalActionButton(
              label: 'Add Reminder',
              onPressed: onAddReminder,
            ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3F3F3F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9B9B9B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            _ModalActionButton(
              label: 'Check on them',
              onPressed: onCheckOnThem,
            ),
            const SizedBox(height: 8),
            _ModalActionButton(
              label: 'Message',
              onPressed: onMessage,
            ),
            const SizedBox(height: 8),
            _ModalActionButton(
              label: 'Call',
              onPressed: onCall,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE94E4D), width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gentle Guide',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"Try to invite for a drink, send a Meme, try to\n'
                    'cheer up the person"',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8E8E8E),
                    ),
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
  const _ModalActionButton({
    required this.label,
    required this.onPressed,
  });

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
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
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
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
            unselectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w600),
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
