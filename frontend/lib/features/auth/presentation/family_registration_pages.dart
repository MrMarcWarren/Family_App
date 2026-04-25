import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_page.dart';
import 'widgets/tahanan_logo.dart';

class JoinFamilyPage extends StatelessWidget {
  const JoinFamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FamilyRegistrationPage(
      title: 'Join a Family',
      description:
          'Enter your family code and personal details to join the household.',
      includeFamilyCode: true,
      actionLabel: 'Join Family',
      familyCodeLabel: 'Family Code',
      navigateToDashboardOnSubmit: false,
    );
  }
}

class CreateFamilyPage extends StatelessWidget {
  const CreateFamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FamilyRegistrationPage(
      title: 'Create a Family',
      description: 'Set up a new family space and invite others to join later.',
      includeFamilyCode: false,
      actionLabel: 'Register Account',
      navigateToDashboardOnSubmit: true,
    );
  }
}

class _FamilyRegistrationPage extends StatefulWidget {
  const _FamilyRegistrationPage({
    required this.title,
    required this.description,
    required this.includeFamilyCode,
    required this.actionLabel,
    required this.navigateToDashboardOnSubmit,
    this.familyCodeLabel,
  });

  final String title;
  final String description;
  final bool includeFamilyCode;
  final String actionLabel;
  final bool navigateToDashboardOnSubmit;
  final String? familyCodeLabel;

  @override
  State<_FamilyRegistrationPage> createState() =>
      _FamilyRegistrationPageState();
}

class _FamilyRegistrationPageState extends State<_FamilyRegistrationPage> {
  final TextEditingController familyCodeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  @override
  void dispose() {
    familyCodeController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    contactController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFE94E4D);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'A StrideForge Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      const TahananLogo(
                        imageSize: 120,
                        labelFontSize: 24,
                        labelSpacing: 4,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (widget.includeFamilyCode) ...[
                        _SectionLabel(
                            label: widget.familyCodeLabel ?? 'Family Code'),
                        const SizedBox(height: 8),
                        _RoundedInput(
                          controller: familyCodeController,
                          hintText: 'Enter Family Code',
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 18),
                      ],
                      const _SectionLabel(label: 'Personal Details'),
                      const SizedBox(height: 10),
                      const _SectionLabel(label: 'Name'),
                      const SizedBox(height: 8),
                      _RoundedInput(
                        controller: nameController,
                        hintText: 'Enter Full Name',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 10),
                      const _SectionLabel(label: 'Email Address'),
                      const SizedBox(height: 8),
                      _RoundedInput(
                        controller: emailController,
                        hintText: 'Enter Email Address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      const _SectionLabel(label: 'Password'),
                      const SizedBox(height: 8),
                      _RoundedInput(
                        controller: passwordController,
                        hintText: 'Enter Desired Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      const _SectionLabel(label: 'Contact / Number'),
                      const SizedBox(height: 8),
                      _RoundedInput(
                        controller: contactController,
                        hintText: 'Enter Contact Number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      const _SectionLabel(label: 'Birthdate'),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniInput(
                              controller: dayController,
                              hintText: 'DD',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _MiniInput(
                              controller: monthController,
                              hintText: 'MM',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _MiniInput(
                              controller: yearController,
                              hintText: 'YYYY',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.navigateToDashboardOnSubmit) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const DashboardPage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFF63C3C),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ).copyWith(color: const Color(0xFFF63C3C)),
                          ),
                          child: Text(widget.actionLabel),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  const _RoundedInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(
        color: const Color(0xFF4A4A4A),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFBEBEBE),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MiniInput extends StatelessWidget {
  const _MiniInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: const Color(0xFF4A4A4A),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFBEBEBE),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
