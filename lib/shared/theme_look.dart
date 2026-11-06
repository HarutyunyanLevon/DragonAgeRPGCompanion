import 'package:flutter/material.dart';

/// How Defense, Armor and Speed are drawn.
enum StatShape { box, shield, arch }

/// How Health and Mana are drawn.
enum VitalStyle { box, plate, glass }

/// The shapes of a theme (its colors and fonts are in [ThemeSpec]).
/// Widgets read these few switches with [ThemeLook.of] and draw themselves
/// accordingly. A new theme only sets other values in `themeSpecs`.
///
/// - [flat]: square corners everywhere.
/// - [frameWidth]: thickness of the line under the header and above the tab
///   bar (0 = no line).
/// - [ornaments]: small corner marks on Play widgets and Sheet boxes.
/// - [archTiles]: Play tiles get a round arch on top.
/// - [statShape]: `shield` / `arch` draws Defense / Armor / Speed as plates.
/// - [vitalStyle]: `plate` = big number with a bar, `glass` = stained-glass vial.
class ThemeLook extends ThemeExtension<ThemeLook> {
  const ThemeLook({
    this.flat = false,
    this.frameWidth = 0,
    this.ornaments = false,
    this.archTiles = false,
    this.statShape = StatShape.box,
    this.vitalStyle = VitalStyle.box,
  });

  final bool flat;
  final double frameWidth;
  final bool ornaments;
  final bool archTiles;
  final StatShape statShape;
  final VitalStyle vitalStyle;

  /// Corner radius of the app's own boxes.
  double get radius => flat ? 0 : 8;

  /// The look of the current theme (the plain look if none is set).
  static ThemeLook of(BuildContext context) =>
      Theme.of(context).extension<ThemeLook>() ?? const ThemeLook();

  // Flutter wants these two. Themes are never changed after they are built
  // and never animated from one to another, so they stay trivial.
  @override
  ThemeLook copyWith() => this;

  @override
  ThemeLook lerp(ThemeExtension<ThemeLook>? other, double t) =>
      t < 0.5 || other is! ThemeLook ? this : other;
}
