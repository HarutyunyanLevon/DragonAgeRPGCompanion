import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_specs.dart';

/// Builds the Material theme for one of the themes in theme_specs.dart.
/// The colors and fonts of each theme are data there; this file only turns
/// that data into a ThemeData.
ThemeData buildTheme(AppThemeId id) {
  final spec = themeSpecs[id]!;
  final scheme = colorSchemeFor(spec);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = _textTheme(spec, base.textTheme);
  final flat = spec.look.flat;
  final frame = spec.look.frameWidth;
  final indicator = flat ? scheme.primary : scheme.primary.withValues(alpha: 0.25);
  const square = RoundedRectangleBorder(); // no rounded corners
  final squareButton = flat
      ? const ButtonStyle(shape: WidgetStatePropertyAll(square))
      : null;
  // A flat theme: the selected tab is a solid block with a readable icon.
  final selectedIcon = IconThemeData(color: scheme.onPrimary);

  return base.copyWith(
    textTheme: text,
    extensions: [spec.look],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge,
      // Some themes draw a line under the header.
      shape: frame > 0
          ? Border(bottom: BorderSide(color: scheme.primary, width: frame))
          : null,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: indicator,
      indicatorShape: flat ? square : null,
      iconTheme: flat
          ? WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? selectedIcon
                  : IconThemeData(color: scheme.onSurfaceVariant))
          : null,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: indicator,
      indicatorShape: flat ? square : null,
      selectedIconTheme: flat ? selectedIcon : null,
    ),
    filledButtonTheme: FilledButtonThemeData(style: squareButton),
    elevatedButtonTheme: ElevatedButtonThemeData(style: squareButton),
    outlinedButtonTheme: OutlinedButtonThemeData(style: squareButton),
    textButtonTheme: TextButtonThemeData(style: squareButton),
    bottomSheetTheme: BottomSheetThemeData(shape: flat ? square : null),
  );
}

/// Body font everywhere, heading font on the big text styles, then the
/// theme's size scale.
TextTheme _textTheme(ThemeSpec spec, TextTheme base) {
  // ThemeData's own text theme has no font sizes yet (Flutter adds them later),
  // and scaling needs them. The standard Material sizes are merged in first.
  var text = Typography.englishLike2021
      .merge(base)
      .apply(bodyColor: spec.onSurface, displayColor: spec.onSurface);

  final bodyFont = spec.bodyFont;
  if (bodyFont != null) {
    final plain = text;
    text = _orElse(() => GoogleFonts.getTextTheme(bodyFont, plain), plain);
  }

  text = text.copyWith(
    headlineMedium: _heading(spec, text.headlineMedium),
    headlineSmall: _heading(spec, text.headlineSmall),
    titleLarge: _heading(spec, text.titleLarge),
  );

  return spec.fontScale == 1
      ? text
      : text.apply(fontSizeFactor: spec.fontScale);
}

/// Heading style. No heading font = the system serif, as the app always had.
TextStyle? _heading(ThemeSpec spec, TextStyle? style) {
  if (style == null) return null;
  final font = spec.headingFont;
  if (font == null) {
    return style.copyWith(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Cambria', 'Times New Roman'],
    );
  }
  return _orElse(() => GoogleFonts.getFont(font, textStyle: style), style);
}

/// A misspelled font name must not crash the app: keep the plain style.
T _orElse<T>(T Function() load, T fallback) {
  try {
    return load();
  } catch (_) {
    return fallback;
  }
}
