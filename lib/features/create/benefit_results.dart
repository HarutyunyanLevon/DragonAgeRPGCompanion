import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import 'background_benefits.dart';
import 'character_draft.dart';

// The "table results" part of wizard step 3: roll / pick two results, or buy.

// ---- text

/// "+1 Magic", "Focus: Cunning (Healing)", "Speak Elven", "Weapon group: Bows"
String resultText(AppLocalizations l10n, TableResult result) =>
    switch (result.type) {
      'ability' => l10n.resultAbility(displayName(result.ability!)),
      'focus' => l10n.resultFocus(
          displayName(result.ability!), displayName(result.focus!)),
      'language' => l10n.resultLanguage(displayName(result.language!)),
      _ => l10n.resultWeaponGroup(displayName(result.group!)),
    };

/// "7-8: +1 Magic": a table row as the player reads it in the book.
String rowText(AppLocalizations l10n, BenefitFacts facts, int row) {
  final r = facts.table[row];
  final range = r.min == r.max ? '${r.min}' : '${r.min}-${r.max}';
  return '$range: ${resultText(l10n, facts.resultAt(row))}';
}

String conflictText(
        AppLocalizations l10n, BenefitConflict conflict, int maxScore) =>
    switch (conflict) {
      BenefitConflict.sameRow => l10n.conflictSameRow,
      BenefitConflict.alreadyOwned => l10n.conflictAlreadyOwned,
      BenefitConflict.abilityCap => l10n.conflictAbilityCap(maxScore),
      BenefitConflict.overBudget => l10n.conflictOverBudget,
    };

/// True when there is no [conflict], or the player confirmed "Proceed anyway".
Future<bool> allowed(
  BuildContext context,
  BenefitFacts facts,
  BenefitConflict? conflict,
) async {
  if (conflict == null) return true;
  final l10n = AppLocalizations.of(context);
  return confirm(
    context,
    title: l10n.benefitConflictTitle,
    body: conflictText(l10n, conflict, facts.maxScore),
    confirmLabel: l10n.proceedAnyway,
  );
}

/// One table row in a list. Dimmed when taking it would break a rule.
class TableRowTile extends StatelessWidget {
  const TableRowTile({
    super.key,
    required this.text,
    required this.dimmed,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String text;
  final bool dimmed;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: ListTile(
        title: Text(text),
        selected: selected,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// ---- roll mode

/// Two result slots. Each one can be rolled or picked from the table.
class RollResults extends ConsumerWidget {
  const RollResults({super.key, required this.facts, required this.benefits});

  final BenefitFacts facts;
  final BackgroundBenefits benefits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(characterDraftProvider.notifier);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.rollHelp),
      const SizedBox(height: 8),
      for (var slot = 0; slot < benefits.rolled.length; slot++)
        Card(
          child: ListTile(
            title: Text(l10n.resultNumber(slot + 1)),
            subtitle: Text(benefits.rolled[slot] == null
                ? l10n.notMadeYet
                : rowText(l10n, facts, benefits.rolled[slot]!)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.casino_outlined),
                tooltip: l10n.rollTable,
                onPressed: () => notifier
                    .setBenefits(benefits.rollSlot(facts, slot, Random())),
              ),
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: l10n.pickFromTable,
                onPressed: () => _pick(context, notifier, slot),
              ),
            ]),
          ),
        ),
    ]);
  }

  Future<void> _pick(
    BuildContext context,
    CharacterDraftNotifier notifier,
    int slot,
  ) async {
    final row = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TableSheet(facts: facts, benefits: benefits, slot: slot),
    );
    if (row == null || !context.mounted) return;

    final conflict = benefits.conflictFor(facts, row, slot: slot);
    if (!await allowed(context, facts, conflict) || !context.mounted) return;
    notifier.setBenefits(benefits.withRow(slot, row));
  }
}

/// The whole table, to pick a row for result [slot]. Tapping a row closes the
/// sheet and returns its index.
class _TableSheet extends StatelessWidget {
  const _TableSheet({
    required this.facts,
    required this.benefits,
    required this.slot,
  });

  final BenefitFacts facts;
  final BackgroundBenefits benefits;
  final int slot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(l10n.pickTableRow),
          for (var row = 0; row < facts.table.length; row++)
            TableRowTile(
              text: rowText(l10n, facts, row),
              dimmed: benefits.conflictFor(facts, row, slot: slot) != null,
              selected: benefits.rolled[slot] == row,
              onTap: () => Navigator.pop(context, row),
            ),
        ],
      ),
    );
  }
}

// ---- buy mode

/// The table rows with their cost. Tap to buy, tap again to give back.
class BuyResults extends ConsumerWidget {
  const BuyResults({super.key, required this.facts, required this.benefits});

  final BenefitFacts facts;
  final BackgroundBenefits benefits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(characterDraftProvider.notifier);
    final buy = facts.buy;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.buyBenefitsHelp(
          buy.backgroundBenefitPoints, buy.abilityIncreaseCost, buy.otherBenefitCost)),
      const SizedBox(height: 8),
      Text(l10n.advancementsLeft(benefits.pointsLeft(facts)),
          style: Theme.of(context).textTheme.titleMedium),
      for (var row = 0; row < facts.table.length; row++)
        TableRowTile(
          text: rowText(l10n, facts, row),
          dimmed: !benefits.bought.contains(row) &&
              benefits.conflictFor(facts, row) != null,
          selected: benefits.bought.contains(row),
          trailing: Text(l10n.cost(facts.costOf(row))),
          onTap: () => _toggle(context, notifier, row),
        ),
    ]);
  }

  Future<void> _toggle(
    BuildContext context,
    CharacterDraftNotifier notifier,
    int row,
  ) async {
    // Giving a row back is always fine; buying one may break a rule.
    if (!benefits.bought.contains(row)) {
      final conflict = benefits.conflictFor(facts, row);
      if (!await allowed(context, facts, conflict) || !context.mounted) return;
    }
    notifier.setBenefits(benefits.toggleBought(row));
  }
}
