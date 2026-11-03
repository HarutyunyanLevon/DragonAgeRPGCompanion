import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import '../../shared/placeholder_page.dart';
import 'background_picker.dart';
import 'character_draft.dart';
import 'class_picker.dart';

/// Wizard step 1 of 4: name, background (book or custom), race and caste when
/// the background asks for them, and class.
class NewCharacterPage extends ConsumerWidget {
  const NewCharacterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(characterDraftProvider);
    final notifier = ref.read(characterDraftProvider.notifier);
    final background = draft.background;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(1, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: l10n.characterName),
          textCapitalization: TextCapitalization.words,
          onChanged: notifier.setName,
        ),
        const SizedBox(height: 24),
        SectionTitle(l10n.background),
        const BackgroundPicker(),
        if (background != null && background.raceChoice) ...[
          const SizedBox(height: 24),
          SectionTitle(l10n.race),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: [
              for (final race in background.races)
                ButtonSegment(value: race, label: Text(displayName(race))),
            ],
            selected: {if (draft.race != null) draft.race!},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) notifier.setRace(selection.first);
            },
          ),
        ],
        if (background != null && background.casteChoices.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionTitle(l10n.caste),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final caste in background.casteChoices)
              ChoiceChip(
                label: Text(displayName(caste)),
                selected: draft.caste == caste,
                onSelected: (_) => notifier.setCaste(caste),
              ),
          ]),
        ],
        if (background != null) ...[
          const SizedBox(height: 24),
          SectionTitle(l10n.characterClass),
          ClassPicker(background: background),
        ],
        const SizedBox(height: 32),
        FilledButton(
          // Step 2 (abilities) is not built yet.
          onPressed: draft.isComplete
              ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PlaceholderPage(title: l10n.stepAbilities),
                  ))
              : null,
          child: Text(l10n.next),
        ),
      ]),
    );
  }
}
