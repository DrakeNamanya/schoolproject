import 'package:flutter/material.dart';

/// Timbitwire Girls School design tokens.
/// Direct port of design_reference/timbitwire-tokens.css.
class TgsColors {
  TgsColors._();

  // Primary - Brick Red
  static const brick50 = Color(0xFFFBEEEC);
  static const brick100 = Color(0xFFF5D2CD);
  static const brick200 = Color(0xFFEAA79E);
  static const brick300 = Color(0xFFD97869);
  static const brick400 = Color(0xFFBC4D3E);
  static const brick500 = Color(0xFFA5352C); // PRIMARY
  static const brick600 = Color(0xFF8A2A22);
  static const brick700 = Color(0xFF6E1F19);
  static const brick800 = Color(0xFF501510);
  static const brick900 = Color(0xFF340D09);

  // Secondary - Deep Maroon
  static const maroon50 = Color(0xFFF6E4EB);
  static const maroon100 = Color(0xFFE7B7C7);
  static const maroon200 = Color(0xFFCE7F9B);
  static const maroon300 = Color(0xFFA94F72);
  static const maroon400 = Color(0xFF832A4F);
  static const maroon500 = Color(0xFF690427); // SECONDARY
  static const maroon600 = Color(0xFF520320);
  static const maroon700 = Color(0xFF3B0217);
  static const maroon800 = Color(0xFF26010F);

  // Accent - Deep Navy
  static const navy50 = Color(0xFFE5E7EE);
  static const navy100 = Color(0xFFC1C5D3);
  static const navy200 = Color(0xFF8A93AE);
  static const navy300 = Color(0xFF58628A);
  static const navy400 = Color(0xFF333F6C);
  static const navy500 = Color(0xFF1F2950); // ACCENT
  static const navy600 = Color(0xFF171F3F);
  static const navy700 = Color(0xFF10162E);
  static const navy800 = Color(0xFF0A0E1E);

  // Neutrals - rose-tinted paper
  static const paper = Color(0xFFF7EFEC); // app background
  static const paper2 = Color(0xFFEFE1DE); // alt surface, hover
  static const paper3 = Color(0xFFE2D5D4); // Rose Grey - dividers/borders
  static const ink50 = Color(0xFFF4EEED);
  static const ink100 = Color(0xFFE7DFDD);
  static const ink200 = Color(0xFFCFC4C2);
  static const ink300 = Color(0xFFA69B99);
  static const ink400 = Color(0xFF7A6E6C);
  static const ink500 = Color(0xFF574B49);
  static const ink600 = Color(0xFF3A3230);
  static const ink700 = Color(0xFF2A2422);
  static const ink800 = Color(0xFF201D1D); // Charcoal
  static const ink900 = Color(0xFF0F0D0D);

  // Semantic
  static const success = Color(0xFF2E6B4B);
  static const successBg = Color(0xFFE4EFEA);
  static const warning = Color(0xFFB4791E);
  static const warningBg = Color(0xFFF7EAD1);
  static const warningText = Color(0xFF7A5111);
  static const danger = brick500;
  static const dangerBg = brick50;
  static const info = navy500;
  static const infoBg = navy50;

  // Semantic aliases
  static const bgApp = paper;
  static const bgSurface = Colors.white;
  static const bgMuted = paper2;
  static const fg1 = ink800;
  static const fg2 = ink600;
  static const fg3 = ink400;
  static const fgMuted = ink300;
  static const border1 = paper3;
  static const border2 = ink200;

  // Uganda flag
  static const ugBlack = Color(0xFF111111);
  static const ugYellow = Color(0xFFFCD116);
  static const ugRed = Color(0xFFD21034);

  // Mobile money brands
  static const mtnYellow = Color(0xFFFFCC00);
  static const airtelRed = Color(0xFFE40000);
}

class TgsFonts {
  TgsFonts._();
  static const display = 'DM Serif Display';
  static const sans = 'Plus Jakarta Sans';
  static const mono = 'JetBrains Mono';
}

class TgsSpace {
  TgsSpace._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;
  static const double s9 = 48;
  static const double s10 = 64;
}

class TgsRadius {
  TgsRadius._();
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double pill = 999;
}

class TgsShadows {
  TgsShadows._();
  static const List<BoxShadow> sh1 = [
    BoxShadow(color: Color(0x0A201D1D), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x08201D1D), offset: Offset(0, 1), blurRadius: 1),
  ];
  static const List<BoxShadow> sh2 = [
    BoxShadow(color: Color(0x0F201D1D), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(color: Color(0x0A201D1D), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> sh3 = [
    BoxShadow(color: Color(0x14201D1D), offset: Offset(0, 8), blurRadius: 20),
    BoxShadow(color: Color(0x0A201D1D), offset: Offset(0, 2), blurRadius: 4),
  ];
  static const List<BoxShadow> sh4 = [
    BoxShadow(color: Color(0x1A201D1D), offset: Offset(0, 18), blurRadius: 40),
    BoxShadow(color: Color(0x0A201D1D), offset: Offset(0, 4), blurRadius: 8),
  ];
}
