import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/magic.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/spell.dart';
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/display_name.dart';
import 'custom_spells.dart';

/// A requirement in words: "Vulnerability Hex" or "Entropy Magic (Journeyman)".
String requirementLabel(
    AppLocalizations l10n, RulesData rules, SpellRequirement r) {
  return switch (r.type) {
    'spell' => rules.spellById(r.id).name,
    'talent' => l10n.reqTalent(
        rules.talents.talentById(r.id).name, degreeName(l10n, r.degree)),
    _ => l10n.reqTalent(rules.specializations.specializationById(r.id).name,
        degreeName(l10n, r.degree)),
  };
}

Future<void> _save(WidgetRef ref, Character character) =>
    ref.read(charactersProvider.notifier).save(character);

/// Adds the spell to the character. Strict rules: with unmet requirements it
/// asks "Proceed anyway?" first.
Future<void> learnSpell(BuildContext context, WidgetRef ref,
    Character character, RulesData rules, Spell spell) async {
  final l10n = AppLocalizations.of(context);
  final unmet = unmetRequirements(character, spell);
  if (unmet.isNotEmpty) {
    final ok = await confirm(
      context,
      title: l10n.spellRequirementsTitle,
      body: l10n.spellRequirementsBody(
        spell.name,
        unmet.map((r) => requirementLabel(l10n, rules, r)).join(', '),
      ),
      confirmLabel: l10n.proceedAnyway,
    );
    if (!ok) return;
  }
  await _save(ref, character.copyWith(spellIds: [...character.spellIds, spell.id]));
}

Future<void> forgetSpell(BuildContext context, WidgetRef ref,
    Character character, Spell spell) async {
  final l10n = AppLocalizations.of(context);
  final ok = await confirm(
    context,
    title: l10n.forgetSpellTitle(spell.name),
    confirmLabel: l10n.forgetSpell,
  );
  if (!ok) return;
  await _save(ref, character.copyWith(spellIds: _without(character, spell)));
}

/// Removes a homebrew spell from the library (and from this character).
Future<void> deleteHomebrewSpell(BuildContext context, WidgetRef ref,
    Character character, Spell spell) async {
  final l10n = AppLocalizations.of(context);
  final ok = await confirm(
    context,
    title: l10n.deleteSpellTitle(spell.name),
    body: l10n.deleteSpellBody,
    confirmLabel: l10n.remove,
  );
  if (!ok) return;
  await ref.read(customSpellsProvider.notifier).remove(spell.id);
  await _save(ref, character.copyWith(spellIds: _without(character, spell)));
}

List<String> _without(Character character, Spell spell) =>
    [for (final id in character.spellIds) if (id != spell.id) id];
