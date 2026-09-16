import 'package:flutter/material.dart';
import 'tokens.dart';

class TgsTheme {
  TgsTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: TgsColors.brick500,
      onPrimary: Colors.white,
      primaryContainer: TgsColors.brick50,
      onPrimaryContainer: TgsColors.brick700,
      secondary: TgsColors.maroon500,
      onSecondary: Colors.white,
      secondaryContainer: TgsColors.maroon50,
      onSecondaryContainer: TgsColors.maroon700,
      tertiary: TgsColors.navy500,
      onTertiary: Colors.white,
      tertiaryContainer: TgsColors.navy50,
      onTertiaryContainer: TgsColors.navy700,
      error: TgsColors.brick600,
      onError: Colors.white,
      errorContainer: TgsColors.brick50,
      onErrorContainer: TgsColors.brick700,
      surface: TgsColors.bgSurface,
      onSurface: TgsColors.fg1,
      surfaceContainerHighest: TgsColors.paper2,
      onSurfaceVariant: TgsColors.fg2,
      outline: TgsColors.border1,
      outlineVariant: TgsColors.border2,
      shadow: TgsColors.ink800,
      scrim: TgsColors.ink900,
      inverseSurface: TgsColors.ink800,
      onInverseSurface: Colors.white,
      inversePrimary: TgsColors.brick200,
    );

    final text = _textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TgsColors.bgApp,
      fontFamily: TgsFonts.sans,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: TgsColors.bgApp,
        foregroundColor: TgsColors.fg1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: TgsColors.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TgsRadius.xl),
          side: const BorderSide(color: TgsColors.border1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TgsColors.border1,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TgsColors.brick500,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: TgsFonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TgsRadius.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TgsColors.maroon600,
          side: const BorderSide(color: TgsColors.border2),
          textStyle: const TextStyle(
            fontFamily: TgsFonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TgsRadius.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TgsColors.brick600,
          textStyle: const TextStyle(
            fontFamily: TgsFonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TgsRadius.lg),
          borderSide: const BorderSide(color: TgsColors.border1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TgsRadius.lg),
          borderSide: const BorderSide(color: TgsColors.border1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TgsRadius.lg),
          borderSide: const BorderSide(color: TgsColors.brick500, width: 1.5),
        ),
        labelStyle: const TextStyle(color: TgsColors.fg3),
        hintStyle: const TextStyle(color: TgsColors.fgMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: TgsColors.brick50,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: TgsFonts.sans,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? TgsColors.brick600 : TgsColors.fg3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? TgsColors.brick600 : TgsColors.fg3,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: TgsColors.brick50,
        side: const BorderSide(color: TgsColors.border1),
        labelStyle: const TextStyle(
          fontFamily: TgsFonts.sans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TgsRadius.pill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TgsColors.ink800,
        contentTextStyle: const TextStyle(
          fontFamily: TgsFonts.sans,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TgsRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TgsRadius.xxl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: TgsColors.fg2,
        textColor: TgsColors.fg1,
      ),
    );
  }

  static TextTheme _textTheme() {
    const display = TextStyle(
      fontFamily: TgsFonts.display,
      fontWeight: FontWeight.w400,
      color: TgsColors.fg1,
      height: 1.15,
      letterSpacing: -0.3,
    );
    const sans = TextStyle(
      fontFamily: TgsFonts.sans,
      color: TgsColors.fg1,
      height: 1.4,
    );
    return TextTheme(
      displayLarge: display.copyWith(fontSize: 48),
      displayMedium: display.copyWith(fontSize: 38),
      displaySmall: display.copyWith(fontSize: 30),
      headlineLarge: display.copyWith(fontSize: 28),
      headlineMedium: display.copyWith(fontSize: 24),
      headlineSmall: display.copyWith(fontSize: 20),
      titleLarge: sans.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      titleSmall: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: sans.copyWith(fontSize: 16),
      bodyMedium: sans.copyWith(fontSize: 14),
      bodySmall: sans.copyWith(fontSize: 12, color: TgsColors.fg2),
      labelLarge: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: sans.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: sans.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: TgsColors.fg3,
      ),
    );
  }
}

/// Convenience text styles used across the app that don't map to TextTheme.
class TgsText {
  TgsText._();

  static const eyebrow = TextStyle(
    fontFamily: TgsFonts.sans,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: TgsColors.fg3,
  );

  static const mono = TextStyle(
    fontFamily: TgsFonts.mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: TgsColors.fg2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle amount({double size = 24, Color color = TgsColors.fg1}) =>
      TextStyle(
        fontFamily: TgsFonts.mono,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -0.5,
      );
}
