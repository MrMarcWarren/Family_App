import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/family/presentation/family_page.dart';

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
      home: const FamilyPage(),
    );
  }
}
