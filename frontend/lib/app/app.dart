import 'package:flutter/material.dart';

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
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}
