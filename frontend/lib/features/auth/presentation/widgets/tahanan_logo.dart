import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TahananLogo extends StatelessWidget {
  const TahananLogo({
    super.key,
    this.imageSize = 165,
    this.labelFontSize = 32,
    this.labelSpacing = 6,
  });

  final double imageSize;
  final double labelFontSize;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: imageSize,
          width: imageSize,
          child: const Image(
            image: AssetImage('assets/images/logos/tahanan_logo.png'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        SizedBox(height: labelSpacing),
        Text(
          'TAHANAN',
          style: GoogleFonts.dynaPuff(
            color: Color(0xFFFFEFEF),
            fontSize: labelFontSize,
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
