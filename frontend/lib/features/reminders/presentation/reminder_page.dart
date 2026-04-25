import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../family/presentation/family_page.dart';
import '../../settings/presentation/settings_page.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  int selectedTabIndex = 2;
  List<Reminder> _reminders = [];
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userRes = await ApiClient.instance.get('/users/me/');
      final user = AppUser.fromJson(userRes.data);

      final futures = [ApiClient.instance.get('/reminders/mine/')];
      if (user.familyId != null) {
        futures
            .add(ApiClient.instance.get('/families/${user.familyId}/members/'));
      }

      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _reminders =
            (results[0].data as List).map((r) => Reminder.fromJson(r)).toList();
        if (results.length > 1) {
          _familyMembers = (results[1].data as List)
              .map((m) => FamilyMember.fromJson(m))
              .toList();
        }
      });
    } on DioException catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markDone(int id) async {
    // Immediately remove from UI
    setState(() {
      _reminders.removeWhere((r) => r.id == id);
    });

    try {
      await ApiClient.instance.patch('/reminders/$id/done/');
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
      // Reload to restore state if API call fails
      await _loadData();
    }
  }

  Future<void> _dismiss(int id) async {
    // Immediately remove from UI
    setState(() {
      _reminders.removeWhere((r) => r.id == id);
    });

    try {
      await ApiClient.instance.patch('/reminders/$id/dismiss/');
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
      // Reload to restore state if API call fails
      await _loadData();
    }
  }

  Future<void> _addReminder(String title, String notes, DateTime dateTime,
      int? assignedUserId) async {
    try {
      await ApiClient.instance.post('/reminders/', data: {
        'title': title.trim().isEmpty ? 'Reminder' : title.trim(),
        'description': notes.trim().isEmpty ? null : notes.trim(),
        'remind_at': dateTime.toUtc().toIso8601String(),
        'assigned_to_ids': assignedUserId != null ? [assignedUserId] : [],
      });
      await _loadData();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberNames = _familyMembers.map((m) => m.displayName).toList();
    final memberIds = _familyMembers.map((m) => m.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      extendBody: true,
      appBar: const ReminderHeader(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94E4D)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 138),
              children: [
                ReminderPanel(
                  reminders: _reminders,
                  onDone: _markDone,
                  onDismiss: _dismiss,
                  onAddReminderPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) {
                        return AddReminderModal(
                          memberNames: memberNames.isNotEmpty
                              ? memberNames
                              : const ['Me'],
                          onConfirm: (title, notes, dateTime, memberIndex) {
                            Navigator.of(dialogContext).pop();
                            final assignedId = memberIds.isNotEmpty &&
                                    memberIndex < memberIds.length
                                ? memberIds[memberIndex]
                                : null;
                            _addReminder(title, notes, dateTime, assignedId);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
      bottomNavigationBar: ReminderBottomNavBar(
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

class ReminderHeader extends StatelessWidget implements PreferredSizeWidget {
  const ReminderHeader({super.key});

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
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
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

class ReminderPanel extends StatelessWidget {
  const ReminderPanel({
    super.key,
    required this.reminders,
    required this.onAddReminderPressed,
    this.onDone,
    this.onDismiss,
  });

  final List<Reminder> reminders;
  final VoidCallback onAddReminderPressed;
  final ValueChanged<int>? onDone;
  final ValueChanged<int>? onDismiss;

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
            Text('Reminders',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A4A4A))),
            const SizedBox(height: 16),
            if (reminders.isEmpty)
              Text('No reminders yet.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF9F9F9F)))
            else
              ...List.generate(reminders.length, (index) {
                final reminder = reminders[index];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == reminders.length - 1 ? 0 : 14),
                  child: ReminderCardSection(
                    reminderId: reminder.id,
                    title: reminder.title,
                    contentHint: reminder.description ?? '',
                    timeText: 'Time: ${reminder.formattedTime}',
                    onDone: onDone != null ? () => onDone!(reminder.id) : null,
                    onDismiss: onDismiss != null
                        ? () => onDismiss!(reminder.id)
                        : null,
                  ),
                );
              }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onAddReminderPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94E4D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Add Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderCardSection extends StatelessWidget {
  const ReminderCardSection({
    super.key,
    required this.reminderId,
    required this.title,
    required this.contentHint,
    required this.timeText,
    this.onDone,
    this.onDismiss,
  });

  final int reminderId;
  final String title;
  final String contentHint;
  final String timeText;
  final VoidCallback? onDone;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE94E4D))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(contentHint,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA0A0A0))),
        ),
        const SizedBox(height: 8),
        Text(timeText,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF454545))),
        if (onDone != null || onDismiss != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (onDone != null)
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94E4D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              if (onDone != null && onDismiss != null) const SizedBox(width: 8),
              if (onDismiss != null)
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9F9F9F),
                        side: const BorderSide(color: Color(0xFFCFCFCF)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class AddReminderModal extends StatefulWidget {
  const AddReminderModal({
    super.key,
    required this.onConfirm,
    this.memberNames = const ['Me'],
    this.initiallySelectedIndex = 0,
  });

  final void Function(
      String title, String notes, DateTime dateTime, int memberIndex) onConfirm;
  final List<String> memberNames;
  final int initiallySelectedIndex;

  @override
  State<AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<AddReminderModal> {
  late int _selectedMemberIndex;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    _selectedMemberIndex =
        widget.initiallySelectedIndex.clamp(0, widget.memberNames.length - 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime));
    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
            _selectedDateTime.year,
            _selectedDateTime.month,
            _selectedDateTime.day,
            picked.hour,
            picked.minute);
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDateTime,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100));
    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(picked.year, picked.month, picked.day,
            _selectedDateTime.hour, _selectedDateTime.minute);
      });
    }
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a Reminder',
                  style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF434343))),
              const SizedBox(height: 14),
              const _FieldLabel(text: 'Reminder Title:'),
              const SizedBox(height: 6),
              _FilledInput(controller: _titleController, hintText: 'Add Title'),
              const SizedBox(height: 14),
              Text('Select Family Member to Remind:',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFA0A0A0))),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.memberNames.length, (index) {
                    final isSelected = _selectedMemberIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedMemberIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFCFCFCF),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE94E4D)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              const _FieldLabel(text: 'Member Selected:'),
              const SizedBox(height: 4),
              Text(
                _selectedMemberIndex < widget.memberNames.length
                    ? widget.memberNames[_selectedMemberIndex]
                    : '',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFA0A0A0)),
              ),
              const SizedBox(height: 12),
              const _FieldLabel(text: 'Select Time:'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _SelectorPill(
                      text:
                          '${TimeOfDay.fromDateTime(_selectedDateTime).hourOfPeriod == 0 ? 12 : TimeOfDay.fromDateTime(_selectedDateTime).hourOfPeriod}',
                      onTap: () => _pickTime(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SelectorPill(
                      text: TimeOfDay.fromDateTime(_selectedDateTime)
                          .minute
                          .toString()
                          .padLeft(2, '0'),
                      onTap: () => _pickTime(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SelectorPill(
                      text: TimeOfDay.fromDateTime(_selectedDateTime).period ==
                              DayPeriod.am
                          ? 'AM'
                          : 'PM',
                      onTap: () => _pickTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _FieldLabel(text: 'Select Date:'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _SelectorPill(
                        text: _monthShort(_selectedDateTime.month),
                        onTap: () => _pickDate(context)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SelectorPill(
                        text: '${_selectedDateTime.day}',
                        onTap: () => _pickDate(context)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SelectorPill(
                        text: '${_selectedDateTime.year}',
                        onTap: () => _pickDate(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _FieldLabel(text: 'Reminder Notes:'),
              const SizedBox(height: 6),
              _FilledInput(
                  controller: _notesController,
                  hintText: 'Add Reminder Notes',
                  height: 68,
                  maxLines: 3),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(
                      _titleController.text,
                      _notesController.text,
                      _selectedDateTime,
                      _selectedMemberIndex,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94E4D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Confirm Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF434343)));
  }
}

class _FilledInput extends StatelessWidget {
  const _FilledInput({
    required this.controller,
    required this.hintText,
    this.height = 62,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final double height;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB2B2B2)),
            border: InputBorder.none,
            isDense: true,
          ),
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF434343)),
        ),
      ),
    );
  }
}

class _SelectorPill extends StatelessWidget {
  const _SelectorPill({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111))),
        ),
      ),
    );
  }
}

class ReminderBottomNavBar extends StatelessWidget {
  const ReminderBottomNavBar({
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
                color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 8)),
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
