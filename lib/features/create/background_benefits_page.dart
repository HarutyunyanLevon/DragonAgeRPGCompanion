import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import '../../shared/placeholder_page.dart';
import 'background_benefits.dart';
import 'benefit_results.dart';
import 'character_draft.dart';

/// Wizard step 3 of 4: what the background gives besides its +1 ability
/// (that one is shown in step 2): a focus, the languages, and two table
/// results that are rolled, picked or bought.
class BackgroundBenefitsPage extends ConsumerWidget {
  const BackgroundBenefitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final draft = ref.watch(characterDraftProvider);
    final notifier = ref.read(characterDraftProvider.notifier);

    // Steps 1 and 2 are done, so these are all set.
    final background = draft.background!;
    final benefits = draft.benefits;
    final facts = BenefitFacts(
      background: background,
      race: draft.race!,
      classRules: rules.classes.classById(draft.classId!),
      startScores: draft.abilities.scores,
      maxScore: rules.backgrounds.maxScore,
      buy: rules.backgrounds.buyMethod,
    );
    final languageChoice = background.languageChoice;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(3, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        SectionTitle(l10n.backgroundFocusTitle),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (var i = 0; i < background.focusChoices.length; i++)
            ChoiceChip(
              label: Text(l10n.focusLabel(
                displayName(background.focusChoices[i].ability),
                displayName(background.focusChoices[i].focus),
              )),
              selected: benefits.focusIndex == i,
              onSelected: (_) => notifier.setBenefits(benefits.withFocus(i)),
            ),
        ]),
        const SizedBox(height: 24),
        Text(l10n.languagesKnown(
            background.languages.map(displayName).join(', '))),
        if (languageChoice != null) ...[
          const SizedBox(height: 12),
          SectionTitle(l10n.languageChoiceTitle(languageChoice.pick)),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final language in languageChoice.from)
              FilterChip(
                label: Text(displayName(language)),
                selected: benefits.languages.contains(language),
                // Disabled once the limit is reached (unless already chosen).
                onSelected: benefits.languages.contains(language) ||
                        benefits.languages.length < languageChoice.pick
                    ? (on) => notifier.setBenefits(benefits.withLanguages([
                          for (final l in benefits.languages)
                            if (l != language) l,
                          if (on) language,
                        ]))
                    : null,
              ),
          ]),
        ],
        const SizedBox(height: 24),
        SectionTitle(l10n.tableResults),
        SegmentedButton<BenefitMode>(
          segments: [
            ButtonSegment(value: BenefitMode.roll, label: Text(l10n.methodRoll)),
            ButtonSegment(value: BenefitMode.buy, label: Text(l10n.methodBuy)),
          ],
          selected: {benefits.mode},
          onSelectionChanged: (selection) =>
              notifier.setBenefits(benefits.changeMode(selection.first)),
        ),
        const SizedBox(height: 12),
        if (benefits.mode == BenefitMode.roll)
          RollResults(facts: facts, benefits: benefits)
        else
          BuyResults(facts: facts, benefits: benefits),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: benefits.isComplete(facts)
              ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    // Step 4 (class choices, health, mana, save) is not built yet.
                    builder: (_) =>
                        PlaceholderPage(title: l10n.stepClassChoices),
                  ))
              : null,
          child: Text(l10n.next),
        ),
      ]),
    );
  }
}
