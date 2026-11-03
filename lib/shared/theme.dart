import 'package:flutter/material.dart';

/// The app look: dark slate, gold accent, serif headings.
/// Change the colors here and the whole app follows.
const _gold = Color(0xFFC9A227);
const _slate = Color(0xFF1B2128);
const _slateRaised = Color(0xFF252D37); // bars and panels

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: _gold,
    onPrimary: _slate,
    secondary: _gold,
    surface: _slate,
    surfaceContainer: _slateRaised,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final indicator = _gold.withValues(alpha: 0.25);

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: _serif(base.textTheme.headlineMedium),
      headlineSmall: _serif(base.textTheme.headlineSmall),
      titleLarge: _serif(base.textTheme.titleLarge),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _slateRaised,
      titleTextStyle: _serif(base.textTheme.titleLarge),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _slateRaised,
      indicatorColor: indicator,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _slateRaised,
      indicatorColor: indicator,
    ),
  );
}

/// Serif font for headings. 'serif' works on Android; Georgia/Cambria cover
/// Windows. Bundle a font file later if you want the same face everywhere.
TextStyle? _serif(TextStyle? style) => style?.copyWith(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Cambria', 'Times New Roman'],
    );
