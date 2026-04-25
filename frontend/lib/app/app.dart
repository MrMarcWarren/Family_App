import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/token_store.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tahanan',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE94E4D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94E4D),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFE94E4D),
          secondary: const Color(0xFFF5D6D6),
          surface: Colors.white,
        ),
        textTheme:
            GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: FutureBuilder<bool>(
        future: TokenStore.hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFE94E4D),
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          if (snapshot.data == true) {
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
