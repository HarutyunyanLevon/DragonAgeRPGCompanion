import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/row_picker.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import 'background_benefits.dart';
import 'benefit_results.dart';
import 'character_draft.dart';
import 'class_choices_page.dart';
import 'rule_info.dart';

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
    final facts = draft.benefitFacts(rules);
    final languageChoice = background.languageChoice;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(3, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        SectionTitle(l10n.backgroundFocusTitle),
        RowPicker(
          options: [
            for (var i = 0; i < background.focusChoices.length; i++)
              (
                '$i',
                l10n.focusLabel(
                  displayName(background.focusChoices[i].ability),
                  displayName(background.focusChoices[i].focus),
                ),
              ),
          ],
          picked: [if (benefits.focusIndex != null) '${benefits.focusIndex}'],
          limit: 1,
          onChange: (ids) =>
              notifier.setBenefits(benefits.withFocus(int.parse(ids.first))),
          describe: (id) {
            final focus = background.focusChoices[int.parse(id)];
            return FocusInfo(
                rules: rules, ability: focus.ability, focus: focus.focus);
          },
        ),
        const SizedBox(height: 24),
        Text(l10n.languagesKnown(
            background.languages.map(displayName).join(', '))),
        if (languageChoice != null) ...[
          const SizedBox(height: 12),
          SectionTitle(l10n.languageChoiceTitle(languageChoice.pick)),
          RowPicker(
            options: [
              for (final language in languageChoice.from)
                (language, displayName(language)),
            ],
            picked: benefits.languages,
            limit: languageChoice.pick,
            onChange: (languages) =>
                notifier.setBenefits(benefits.withLanguages(languages)),
            describe: (language) =>
                LanguageInfo(rules: rules, language: language),
          ),
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
                    builder: (_) => const ClassChoicesPage(),
                  ))
              : null,
          child: Text(l10n.next),
        ),
      ]),
    );
  }
}
