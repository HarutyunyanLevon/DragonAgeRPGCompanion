import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import 'ability_generation.dart';
import 'background_benefits_page.dart';
import 'character_draft.dart';

/// Wizard step 2 of 4: the eight abilities, made by rolling, arranging,
/// buying or typing them in (see [AbilityMethod]). The background's +1 is
/// shown on top.
class AbilitiesPage extends ConsumerStatefulWidget {
  const AbilitiesPage({super.key});

  @override
  ConsumerState<AbilitiesPage> createState() => _AbilitiesPageState();
}

class _AbilitiesPageState extends ConsumerState<AbilitiesPage> {
  /// First ability tapped for a swap.
  String? _swapFrom;

  AbilityGeneration get _generation => ref.read(characterDraftProvider).abilities;

  void _set(AbilityGeneration generation) =>
      ref.read(characterDraftProvider.notifier).setAbilities(generation);

  void _changeMethod(AbilityMethod method) {
    if (method == _generation.method) return;
    setState(() => _swapFrom = null);
    _set(_generation.changeMethod(method));
  }

  void _roll(BackgroundsFile file) {
    setState(() => _swapFrom = null);
    _set(_generation.rolled(Random(), file));
  }

  /// Scores outside the rules are allowed, but only after a "Proceed anyway".
  Future<void> _next(BackgroundsFile file) async {
    final l10n = AppLocalizations.of(context);
    if (_generation.outOfRange(file).isNotEmpty &&
        !await confirm(
          context,
          title: l10n.scoresOutOfRangeTitle,
          body: l10n.scoresOutOfRangeBody(file.minScore, file.maxScore),
          confirmLabel: l10n.proceedAnyway,
        )) {
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const BackgroundBenefitsPage(),
    ));
  }

  void _tapForSwap(String ability) {
    if (!_generation.canSwap) return;
    final from = _swapFrom;
    if (from == null) {
      setState(() => _swapFrom = ability);
    } else if (from == ability) {
      setState(() => _swapFrom = null);
    } else {
      _set(_generation.swapped(from, ability));
      setState(() => _swapFrom = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = ref.watch(rulesProvider).requireValue.backgrounds;
    final draft = ref.watch(characterDraftProvider);
    final generation = draft.abilities;
    final buy = file.buyMethod;

    final help = switch (generation.method) {
      AbilityMethod.roll => l10n.methodRollHelp,
      AbilityMethod.arrange => l10n.methodArrangeHelp,
      AbilityMethod.buy => l10n.methodBuyHelp(buy.points, buy.maxPerAbility),
      AbilityMethod.manual =>
        l10n.methodManualHelp(file.minScore, file.maxScore),
    };
    final outOfRange = generation.outOfRange(file);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(2, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        SegmentedButton<AbilityMethod>(
          segments: [
            ButtonSegment(
                value: AbilityMethod.roll, label: Text(l10n.methodRoll)),
            ButtonSegment(
                value: AbilityMethod.arrange, label: Text(l10n.methodArrange)),
            ButtonSegment(value: AbilityMethod.buy, label: Text(l10n.methodBuy)),
            ButtonSegment(
                value: AbilityMethod.manual, label: Text(l10n.methodManual)),
          ],
          selected: {generation.method},
          onSelectionChanged: (selection) => _changeMethod(selection.first),
        ),
        const SizedBox(height: 12),
        Text(help),
        const SizedBox(height: 12),
        if (generation.method == AbilityMethod.buy)
          Text(l10n.pointsLeft(generation.pointsLeft(buy)),
              style: Theme.of(context).textTheme.titleMedium)
        else if (generation.method != AbilityMethod.manual)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.casino_outlined),
              label: Text(
                  generation.hasRolled ? l10n.rollAgain : l10n.rollAbilities),
              onPressed: () => _roll(file),
            ),
          ),
        if (generation.method == AbilityMethod.arrange &&
            generation.hasRolled) ...[
          const SizedBox(height: 12),
          SectionTitle(l10n.rolledScores),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final chip in generation.poolChips)
              Opacity(
                opacity: chip.used ? 0.35 : 1,
                child: Chip(label: Text('${chip.score}')),
              ),
          ]),
        ],
        if (generation.canSwap) ...[
          const SizedBox(height: 8),
          Text(l10n.swapHint),
        ],
        if (outOfRange.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.scoresOutOfRangeWarning(
                outOfRange.length, file.minScore, file.maxScore),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 8),
        for (final ability in file.abilities)
          _AbilityRow(
            ability: ability,
            gainsBackgroundBonus: ability == draft.background?.abilityBonus,
            generation: generation,
            buy: buy,
            selected: ability == _swapFrom,
            outOfRange: outOfRange.contains(ability),
            onTap: () => _tapForSwap(ability),
            onChange: _set,
          ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: generation.isComplete(file) ? () => _next(file) : null,
          child: Text(l10n.next),
        ),
      ]),
    );
  }
}

/// One ability: its name, its score, and the control for the chosen method.
class _AbilityRow extends StatelessWidget {
  const _AbilityRow({
    required this.ability,
    required this.gainsBackgroundBonus,
    required this.generation,
    required this.buy,
    required this.selected,
    required this.outOfRange,
    required this.onTap,
    required this.onChange,
  });

  final String ability;
  final bool gainsBackgroundBonus;
  final AbilityGeneration generation;
  final BuyMethod buy;
  final bool selected;
  final bool outOfRange;
  final VoidCallback onTap;
  final ValueChanged<AbilityGeneration> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final score = generation.scores[ability];
    final bigNumber = Theme.of(context).textTheme.titleLarge;

    final Widget trailing;
    switch (generation.method) {
      case AbilityMethod.roll:
        trailing = Text(score?.toString() ?? '-', style: bigNumber);
      case AbilityMethod.arrange:
        trailing = DropdownButton<int>(
          value: score,
          hint: const Text('-'),
          items: [
            for (final option in generation.optionsFor(ability))
              DropdownMenuItem(value: option, child: Text('$option')),
          ],
          onChanged: (value) {
            if (value != null) onChange(generation.assigned(ability, value));
          },
        );
      case AbilityMethod.manual:
        trailing = SizedBox(
          width: 72,
          child: TextFormField(
            key: ValueKey('manual-$ability'),
            initialValue: score?.toString(),
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (text) =>
                onChange(generation.entered(ability, int.tryParse(text))),
          ),
        );
      case AbilityMethod.buy:
        trailing = Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: generation.canDecrease(ability)
                ? () => onChange(generation.adjusted(ability, -1))
                : null,
          ),
          SizedBox(
            width: 32,
            child: Text('${score ?? 0}',
                style: bigNumber, textAlign: TextAlign.center),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: generation.canIncrease(ability, buy)
                ? () => onChange(generation.adjusted(ability, 1))
                : null,
          ),
        ]);
    }

    // Buying starts every ability at 0, so it always has a score.
    final start = generation.method == AbilityMethod.buy ? (score ?? 0) : score;

    return ListTile(
      title: Text(displayName(ability)),
      subtitle: gainsBackgroundBonus
          ? Text(start == null
              ? l10n.backgroundBonus
              : l10n.backgroundBonusTotal(start + 1))
          : null,
      selected: selected,
      tileColor: outOfRange
          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.25)
          : null,
      onTap: onTap,
      trailing: trailing,
    );
  }
}
