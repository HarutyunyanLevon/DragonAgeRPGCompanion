import 'package:flutter/material.dart';

import 'theme_look.dart';

/// The themes a player can pick. The [name] of each value is saved in
/// settings.json, so do not rename a value once it is released.
enum AppThemeId {
  classic,
  chantry,
  manuscript,
  tavern,
  antivan,
  warrior;

  /// Settings value -> theme. A missing or unknown name gives the classic look.
  static AppThemeId fromName(String? name) =>
      values.firstWhere((id) => id.name == name, orElse: () => classic);
}

/// Everything that makes one theme look different, as plain data.
/// To tweak a theme, change its numbers in [themeSpecs] below.
///
/// - [surface]: page background. [raised]: app bar, tab bar, panels.
/// - [primary]: buttons and selected things. [onPrimary]: text on them.
/// - [outline]: borders and dividers.
/// - Fonts are Google Font names. null = the system serif / default font.
/// - [fontScale]: some fonts look small at the same size (Cormorant), so
///   all text of that theme is scaled up a little.
/// - [look]: the shapes (flat corners, shield plates ...), see theme_look.dart.
class ThemeSpec {
  const ThemeSpec({
    required this.brightness,
    required this.surface,
    required this.raised,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSurface,
    required this.outline,
    this.headingFont,
    this.bodyFont,
    this.fontScale = 1,
    this.look = const ThemeLook(),
  });

  final Brightness brightness;
  final Color surface;
  final Color raised;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSurface;
  final Color outline;
  final String? headingFont;
  final String? bodyFont;
  final double fontScale;
  final ThemeLook look;
}

const themeSpecs = <AppThemeId, ThemeSpec>{
  // The original look: dark slate, gold accent, serif headings.
  AppThemeId.classic: ThemeSpec(
    brightness: Brightness.dark,
    surface: Color(0xFF1B2128),
    raised: Color(0xFF252D37),
    primary: Color(0xFFC9A227),
    onPrimary: Color(0xFF1B2128),
    secondary: Color(0xFFC9A227),
    onSurface: Color(0xFFE8E6E1),
    outline: Color(0xFF8E939B),
  ),
  // Sketch 01: soot black, ember orange, crimson.
  AppThemeId.chantry: ThemeSpec(
    brightness: Brightness.dark,
    surface: Color(0xFF120E0F),
    raised: Color(0xFF211C1D),
    primary: Color(0xFFE8743B),
    onPrimary: Color(0xFF14100F),
    secondary: Color(0xFFB5303A),
    onSurface: Color(0xFFE9DFD3),
    outline: Color(0xFF8A6455),
    headingFont: 'Cinzel',
    bodyFont: 'Crimson Pro',
    fontScale: 1.05,
    look: ThemeLook(
      frameWidth: 1.5,
      ornaments: true,
      archTiles: true,
      statShape: StatShape.arch,
      vitalStyle: VitalStyle.glass,
    ),
  ),
  // Sketch 02: the only light theme. Parchment, ink, lapis, rubric red.
  AppThemeId.manuscript: ThemeSpec(
    brightness: Brightness.light,
    surface: Color(0xFFF1E4C3),
    raised: Color(0xFFE2CFA0),
    primary: Color(0xFF1F3F8A),
    onPrimary: Color(0xFFF6EBCF),
    secondary: Color(0xFFA6261D),
    onSurface: Color(0xFF2A1D12),
    outline: Color(0xFF8A6A3A),
    headingFont: 'IM Fell English',
    bodyFont: 'Cormorant Garamond',
    fontScale: 1.12,
  ),
  // Sketch 06: dark wood and brass (the cream paper cards come later).
  AppThemeId.tavern: ThemeSpec(
    brightness: Brightness.dark,
    surface: Color(0xFF33200F),
    raised: Color(0xFF4A2F1A),
    primary: Color(0xFFC9923C),
    onPrimary: Color(0xFF2A1A0F),
    secondary: Color(0xFFD64533),
    onSurface: Color(0xFFFBECCB),
    outline: Color(0xFF8A6A3A),
    headingFont: 'Fondamento',
    bodyFont: 'Alegreya',
    fontScale: 1.05,
  ),
  // Sketch 10: burgundy black, gold, ivory.
  AppThemeId.antivan: ThemeSpec(
    brightness: Brightness.dark,
    surface: Color(0xFF1A0A10),
    raised: Color(0xFF2A0D18),
    primary: Color(0xFFD4AF37),
    onPrimary: Color(0xFF1A0A10),
    secondary: Color(0xFFC0395A),
    onSurface: Color(0xFFF5ECD9),
    outline: Color(0xFF8A7330),
    headingFont: 'Italiana',
    bodyFont: 'Playfair Display',
  ),
  // Sketch 11: charcoal, steel, crimson. The crimson is a bit lighter than
  // in the sketch so white text on it and the red itself stay readable.
  AppThemeId.warrior: ThemeSpec(
    brightness: Brightness.dark,
    surface: Color(0xFF14161A),
    raised: Color(0xFF20242B),
    primary: Color(0xFFD7363C),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFAEB7C2),
    onSurface: Color(0xFFECEFF3),
    outline: Color(0xFF6B7482),
    headingFont: 'Oswald',
    bodyFont: 'Source Serif 4',
    look: ThemeLook(
      flat: true,
      frameWidth: 3,
      statShape: StatShape.shield,
      vitalStyle: VitalStyle.plate,
    ),
  ),
};

/// The Material color scheme of a theme. Pure (no fonts), so tests can check
/// the colors.
ColorScheme colorSchemeFor(ThemeSpec spec) {
  final dark = spec.brightness == Brightness.dark;
  // A soft tint of an accent over the page color, for chips and selections.
  Color tint(Color color) =>
      Color.alphaBlend(color.withValues(alpha: 0.28), spec.surface);

  return ColorScheme(
    brightness: spec.brightness,
    primary: spec.primary,
    onPrimary: spec.onPrimary,
    primaryContainer: tint(spec.primary),
    onPrimaryContainer: spec.onSurface,
    secondary: spec.secondary,
    onSecondary: _readableOn(spec.secondary),
    secondaryContainer: tint(spec.secondary),
    onSecondaryContainer: spec.onSurface,
    error: dark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
    onError: dark ? const Color(0xFF601410) : Colors.white,
    surface: spec.surface,
    onSurface: spec.onSurface,
    onSurfaceVariant:
        Color.alphaBlend(spec.onSurface.withValues(alpha: 0.72), spec.surface),
    surfaceContainer: spec.raised,
    outline: spec.outline,
    outlineVariant: spec.outline.withValues(alpha: 0.5),
  );
}

Color _readableOn(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
