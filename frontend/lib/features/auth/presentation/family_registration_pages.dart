import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_client.dart';
import '../../../core/token_store.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import 'widgets/tahanan_logo.dart';

class JoinFamilyPage extends StatelessWidget {
  const JoinFamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FamilyRegistrationPage(
      title: 'Join a Family',
      description:
          'Enter the Family ID and your personal details to join the household.',
      includeFamilyId: true,
      actionLabel: 'Join Family',
      familyIdLabel: 'Family ID',
    );
  }
}

class CreateFamilyPage extends StatelessWidget {
  const CreateFamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FamilyRegistrationPage(
      title: 'Create a Family',
      description: 'Register your account. An admin will set up the family space.',
      includeFamilyId: false,
      actionLabel: 'Register Account',
    );
  }
}

class _FamilyRegistrationPage extends StatefulWidget {
  const _FamilyRegistrationPage({
    required this.title,
    required this.description,
    required this.includeFamilyId,
    required this.actionLabel,
    this.familyIdLabel,
  });

  final String title;
  final String description;
  final bool includeFamilyId;
  final String actionLabel;
  final String? familyIdLabel;

  @override
  State<_FamilyRegistrationPage> createState() =>
      _FamilyRegistrationPageState();
}

class _FamilyRegistrationPageState extends State<_FamilyRegistrationPage> {
  final TextEditingController familyIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    familyIdController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    contactController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final phone = contactController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Name and password are required.');
      return;
    }

    String? birthday;
    final day = dayController.text.trim();
    final month = monthController.text.trim();
    final year = yearController.text.trim();
    if (day.isNotEmpty && month.isNotEmpty && year.isNotEmpty) {
      birthday =
          '${year.padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
    }

    setState(() => _isLoading = true);

    try {
      // 1. Register
      await ApiClient.instance.post('/auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
        if (phone.isNotEmpty) 'phone': phone,
        if (birthday != null) 'birthday': birthday,
      });

      // 2. Login to get tokens
      final loginRes = await ApiClient.instance.post('/auth/login/', data: {
        'username': username,
        'password': password,
      });
      await TokenStore.saveTokens(
        loginRes.data['access'],
        loginRes.data['refresh'],
      );

      // 3. Join family if family ID was provided
      if (widget.includeFamilyId) {
        final familyId = int.tryParse(familyIdController.text.trim());
        if (familyId != null) {
          await ApiClient.instance.post('/families/$familyId/join/');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
        (route) => false,
      );
    } on DioException catch (e) {
      _showError(ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
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
                      if (widget.includeFamilyId) ...[
                        _SectionLabel(
                            label: widget.familyIdLabel ?? 'Family ID'),
                        const SizedBox(height: 8),
                        _RoundedInput(
                          controller: familyIdController,
                          hintText: 'Enter Family ID (number)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 18),
                      ],
                      const _SectionLabel(label: 'Personal Details'),
                      const SizedBox(height: 10),
                      const _SectionLabel(label: 'Username'),
                      const SizedBox(height: 8),
                      _RoundedInput(
                        controller: nameController,
                        hintText: 'Enter Username',
                        keyboardType: TextInputType.text,
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
                        hintText: 'Enter Password',
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
                          onPressed: _isLoading ? null : _submit,
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
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF63C3C),
                                  ),
                                )
                              : Text(widget.actionLabel),
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
