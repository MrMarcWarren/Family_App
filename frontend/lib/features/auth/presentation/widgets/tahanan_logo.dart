import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TahananLogo extends StatelessWidget {
  const TahananLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 165,
          width: 165,
          child: const Image(
            image: AssetImage('assets/images/logos/tahanan_logo.png'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'TAHANAN',
          style: GoogleFonts.dynaPuff(
            color: Color(0xFFFFEFEF),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.8,
            shadows: const [
              Shadow(
                color: Color(0x33000000),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
