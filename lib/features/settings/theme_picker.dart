import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/theme_provider.dart';
import '../../shared/theme_specs.dart';

/// Opens the theme picker: a bottom sheet (centered and narrow on wide
/// screens). Picking a theme changes the whole app at once and is saved.
void showThemePicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const ThemePicker(),
  );
}

class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected =
        ref.watch(themeIdProvider).valueOrNull ?? AppThemeId.classic;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.themeTitle,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final id in AppThemeId.values)
                  ListTile(
                    selected: id == selected,
                    leading: _Swatch(themeSpecs[id]!),
                    title: Text(_name(l10n, id)),
                    subtitle: Text(_about(l10n, id)),
                    trailing: id == selected ? const Icon(Icons.check) : null,
                    onTap: () => ref.read(themeIdProvider.notifier).select(id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// A small preview of a theme: its page color with its two accent dots.
class _Swatch extends StatelessWidget {
  const _Swatch(this.spec);

  final ThemeSpec spec;

  Widget _dot(Color color) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: spec.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: spec.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_dot(spec.primary), const SizedBox(width: 4), _dot(spec.secondary)],
      ),
    );
  }
}

String _name(AppLocalizations l10n, AppThemeId id) => switch (id) {
      AppThemeId.classic => l10n.themeClassic,
      AppThemeId.chantry => l10n.themeChantry,
      AppThemeId.manuscript => l10n.themeManuscript,
      AppThemeId.tavern => l10n.themeTavern,
      AppThemeId.antivan => l10n.themeAntivan,
      AppThemeId.warrior => l10n.themeWarrior,
    };

String _about(AppLocalizations l10n, AppThemeId id) => switch (id) {
      AppThemeId.classic => l10n.themeClassicAbout,
      AppThemeId.chantry => l10n.themeChantryAbout,
      AppThemeId.manuscript => l10n.themeManuscriptAbout,
      AppThemeId.tavern => l10n.themeTavernAbout,
      AppThemeId.antivan => l10n.themeAntivanAbout,
      AppThemeId.warrior => l10n.themeWarriorAbout,
    };
