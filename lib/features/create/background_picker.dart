import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../shared/display_name.dart';
import 'character_draft.dart';
import 'custom_background_page.dart';

/// Race filter chips, the list of backgrounds (the player's custom one first),
/// and the details of the selected one right under it.
class BackgroundPicker extends ConsumerStatefulWidget {
  const BackgroundPicker({super.key});

  @override
  ConsumerState<BackgroundPicker> createState() => _BackgroundPickerState();
}

class _BackgroundPickerState extends ConsumerState<BackgroundPicker> {
  String? _raceFilter; // null = all races

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final book = ref.watch(rulesProvider).requireValue.backgrounds.backgrounds;
    final draft = ref.watch(characterDraftProvider);
    final notifier = ref.read(characterDraftProvider.notifier);

    final shown = [
      if (draft.customBackground != null) draft.customBackground!,
      for (final b in book)
        if (_raceFilter == null || b.races.contains(_raceFilter)) b,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: Text(l10n.filterAll),
              selected: _raceFilter == null,
              onSelected: (_) => setState(() => _raceFilter = null),
            ),
            for (final race in playableRaces)
              ChoiceChip(
                label: Text(displayName(race)),
                selected: _raceFilter == race,
                onSelected: (_) => setState(() => _raceFilter = race),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final b in shown) ...[
          ListTile(
            title: Text(b.name),
            subtitle: Text(b.races.map(displayName).join(' / ')),
            trailing: b.homebrew ? Text(l10n.homebrew) : null,
            selected: draft.background?.id == b.id,
            onTap: () => notifier.selectBackground(b),
          ),
          if (draft.background?.id == b.id) _BackgroundDetails(background: b),
        ],
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l10n.addCustomBackground),
          onTap: _createCustom,
        ),
      ],
    );
  }

  Future<void> _createCustom() async {
    final custom = await Navigator.of(context).push<Background>(
      MaterialPageRoute(builder: (_) => const CustomBackgroundPage()),
    );
    if (custom != null && mounted) {
      ref
          .read(characterDraftProvider.notifier)
          .selectBackground(custom, custom: custom);
    }
  }
}

/// What the selected background gives.
class _BackgroundDetails extends StatelessWidget {
  const _BackgroundDetails({required this.background});

  final Background background;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final b = background;
    final languageChoice = b.languageChoice;

    final languages = [
      ...b.languages.map(displayName),
      if (languageChoice != null)
        l10n.languagePick(
          languageChoice.pick,
          languageChoice.from.map(displayName).join(' / '),
        ),
    ];
    final focuses = [
      for (final f in b.focusChoices)
        '${displayName(f.ability)} (${displayName(f.focus)})',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(l10n.race, b.races.map(displayName).join(' / ')),
            _DetailRow(l10n.abilityBonus, displayName(b.abilityBonus)),
            _DetailRow(l10n.focusChoices, focuses.join(', ')),
            _DetailRow(l10n.languages, languages.join(', ')),
            _DetailRow(l10n.classes, b.classes.map(displayName).join(', ')),
            if (b.trait != null) _DetailRow(l10n.trait, displayName(b.trait!)),
            for (final note in b.notes) Text(note),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(TextSpan(children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: value),
      ])),
    );
  }
}
