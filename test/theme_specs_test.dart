import 'package:dragon_age_companion/shared/theme_specs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between two colors (1 = same, 21 = black on white).
double contrast(Color a, Color b) {
  final light = a.computeLuminance() > b.computeLuminance() ? a : b;
  final dark = identical(light, a) ? b : a;
  return (light.computeLuminance() + 0.05) / (dark.computeLuminance() + 0.05);
}

void main() {
  test('every theme has a spec', () {
    for (final id in AppThemeId.values) {
      expect(themeSpecs[id], isNotNull, reason: id.name);
    }
  });

  test('unknown or missing names give the classic theme', () {
    expect(AppThemeId.fromName(null), AppThemeId.classic);
    expect(AppThemeId.fromName('nope'), AppThemeId.classic);
    expect(AppThemeId.fromName('chantry'), AppThemeId.chantry);
  });

  test('every theme stays readable', () {
    for (final id in AppThemeId.values) {
      final spec = themeSpecs[id]!;
      expect(contrast(spec.onSurface, spec.surface), greaterThanOrEqualTo(7),
          reason: '${id.name}: text on page');
      expect(contrast(spec.onPrimary, spec.primary), greaterThanOrEqualTo(4.5),
          reason: '${id.name}: text on buttons');
      expect(contrast(spec.primary, spec.surface), greaterThanOrEqualTo(3),
          reason: '${id.name}: accent on page');
      expect(contrast(spec.outline, spec.surface), greaterThanOrEqualTo(3),
          reason: '${id.name}: borders on page');
    }
  });

  test('the color scheme follows the spec', () {
    final spec = themeSpecs[AppThemeId.manuscript]!;
    final scheme = colorSchemeFor(spec);
    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, spec.primary);
    expect(scheme.surface, spec.surface);
    expect(scheme.surfaceContainer, spec.raised);
  });
}
