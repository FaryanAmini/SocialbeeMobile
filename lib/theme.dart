import 'package:flutter/material.dart';

// universal theme
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color line = Color(0x24FFFFFF);
  static const Color ink = Color(0xFFF2F2F5);
  static const Color inkSoft = Color(0xFFA8A8B2);
  static const Color inkMid = Color(0xFFC9C9D2);
  static const Color muted = Color(0xFF83838D);

  static const Color accent = Color(0xFFF5A524);
  static const Color accentInk = Color(0xFF1A1200);

  static const Color building = Color(0xFF8B7CFF);
  static const Color maintaining = Color(0xFF2FBF8F);
  static const Color dimContact = Color(0xFF7A7A85);
}

// universal text sizes w two different weights
// consistency throughout app gang

class Texts {
  Texts._();

  static const TextStyle bigTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static const TextStyle itemTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle meta = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSoft,
  );

  // small tracked uppercase label "SOON", "LATER"...
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
    letterSpacing: 1.1,
  );
}

// fill and border colors
// translucence for 'liquid glass' feel
// fuck native dev we do ts the 2010 photoshop way fr
// fy mean frag shaders
// alright idk what im talking about im tired
// who tf is reading this other than me anyways

const Color glassFill = Color(0x0FFFFFFF);
const Color glassBorder = Color(0x26FFFFFF);

// applying themes to the app

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.accentInk,
      surface: Colors.black,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: Color(0x33F5A524),
      selectionHandleColor: AppColors.accent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      thumbColor: AppColors.accent,
      inactiveTickMarkColor: Color(0x1FFFFFFF),
      overlayColor: Color(0x22F5A524),
      trackHeight: 3,
    ),
  );
}
