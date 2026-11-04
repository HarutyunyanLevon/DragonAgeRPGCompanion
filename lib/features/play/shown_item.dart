import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/equipment.dart';
import '../../character/magic.dart';
import '../../character/play_items.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/money.dart';
import '../create/rule_info.dart';
import '../roll/ability_roll.dart';
import '../roll/roll_request.dart';
import '../roll/roll_sheet.dart';
import '../spells/cast_spell.dart';
import '../spells/custom_spells.dart';

/// What an item looks like and does on the Play tab, worked out from the item
/// and the character. [PlayItemView] draws it.
class ShownItem {
  const ShownItem({
    required this.title,
    this.value,
    this.subtitle,
    this.details,
    this.actionLabel,
    this.onAction,
    this.missing = false,
  });

  final String title;

  /// The big text next to the title: a bonus, a number, "3 / 20".
  final String? value;
  final String? subtitle;

  /// The description shown in the bottom card when the item is tapped.
  final Widget? details;

  /// The card's button ("Roll", "Cast") and what it does. Null: no button.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A tap opens the card.
  bool get hasCard => details != null || onAction != null;

  /// The item points at something the character no longer has.
  final bool missing;
}

/// The current value of a "stat" item, as the Sheet shows it.
String statValue(String key, Character c, RulesData rules, AppLocalizations l10n) {
  final n = combatNumbers(c, rules);
  return switch (key) {
    'class' => displayName(c.classId),
    'health' => '${c.health} / ${c.maxHealth}',
    'mana' => '${c.mana} / ${c.maxMana}',
    'defense' => '${n.defense}',
    'speed' => '${n.speed}',
    'armor' => '${n.armorRating}',
    'penalty' => '${n.armorPenalty}',
    'move' => '${n.speed}',
    'charge' => '${n.speed ~/ 2}',
    'run' => '${n.speed * 2}',
    'level' => '${c.level}',
    'xp' => '${c.xp}',
    'money' => moneyText(l10n, c.copper),
    _ => '',
  };
}

String statName(String key, AppLocalizations l10n) => switch (key) {
      'class' => l10n.statClass,
      'health' => l10n.health,
      'mana' => l10n.mana,
      'defense' => l10n.defense,
      'speed' => l10n.speed,
      'armor' => l10n.armorShort,
      'penalty' => l10n.penaltyShort,
      'move' => l10n.move,
      'charge' => l10n.charge,
      'run' => l10n.run,
      'level' => l10n.statLevel,
      'xp' => l10n.statExperience,
      'money' => l10n.money,
      _ => displayName(key),
    };

/// The description a stat opens, or null when it has none.
Widget? statInfo(String key, Character c, RulesData rules, AppLocalizations l10n) {
  final n = combatNumbers(c, rules);
  return switch (key) {
    'defense' => CombatStatInfo(stat: CombatStat.defense, numbers: n),
    'speed' => CombatStatInfo(stat: CombatStat.speed, numbers: n),
    'armor' => CombatStatInfo(stat: CombatStat.armorRating, numbers: n),
    'penalty' => Text(l10n.armorPenaltyRule),
    'move' => Text(l10n.moveRule),
    'charge' => Text(l10n.chargeRule),
    'run' => Text(l10n.runRule),
    'money' => const MoneyInfo(),
    _ => null,
  };
}

/// Works out how [item] looks and what a tap does. Health, mana, money and the
/// free items with controls (counter, checkbox) are handled by the view.
ShownItem showItem(BuildContext context, WidgetRef ref, PlayItem item,
    Character c, RulesData rules) {
  final l10n = AppLocalizations.of(context);

  ShownItem missing() =>
      ShownItem(title: l10n.itemMissing(displayName(item.ref)), missing: true);

  ShownItem withInfo(String title, String? value, Widget info) =>
      ShownItem(title: title, value: value, details: info);

  void roll(RollRequest request) => showRoll(context, rules, request);

  switch (item.type) {
    case 'ability':
      return ShownItem(
        title: displayName(item.ref),
        value: signed(c.ability(item.ref)),
        details: AbilityInfo(rules: rules, ability: item.ref),
        actionLabel: l10n.rollAction,
        onAction: () => rollAbility(context, c, rules, item.ref),
      );

    case 'focus':
      final (ability, focus) = splitFocusRef(item.ref);
      final owned = c.focuses.any((f) => f.ability == ability && f.focus == focus);
      if (!owned) return missing();
      return ShownItem(
        title: l10n.focusLabel(displayName(ability), displayName(focus)),
        value: signed(testBonus(c, ability, focus)),
        details: FocusInfo(rules: rules, ability: ability, focus: focus),
        actionLabel: l10n.rollAction,
        onAction: () => rollAbility(context, c, rules, ability, focus: focus),
      );

    case 'weapon':
      final weapon = rules.weaponById(item.ref);
      if (weapon == null || !c.inventory.any((i) => i.itemId == item.ref)) {
        return missing();
      }
      final numbers = weaponNumbers(c, weapon, rules);
      return ShownItem(
        title: weapon.name,
        value: signed(numbers.attack),
        subtitle: numbers.damage,
        details: ItemInfo(rules: rules, itemId: item.ref, name: weapon.name),
        actionLabel: l10n.rollAction,
        onAction: () => roll(RollRequest(
          title: weapon.name,
          bonus: numbers.attack,
          stunts: StuntSet.combat,
          damage: numbers.damage,
        )),
      );

    case 'spell':
      final spell = ref
          .watch(allSpellsProvider)
          .where((s) => s.id == item.ref && c.spellIds.contains(s.id))
          .firstOrNull;
      if (spell == null) return missing();
      return ShownItem(
        title: spell.name,
        value: spell.mana,
        details: SpellInfo(spell: spell),
        actionLabel: canCast(c, rules) ? l10n.cast : null,
        onAction: canCast(c, rules)
            ? () => castSpell(context, ref, c, rules, spell)
            : null,
      );

    case 'talent':
      final entry = c.talents.where((t) => t.id == item.ref).firstOrNull;
      if (entry == null) return missing();
      final talent = rules.talents.talentById(entry.id);
      return withInfo(talent.name, degreeName(l10n, entry.degree),
          TalentInfo(rules: rules, talent: talent, degree: entry.degree));

    case 'specialization':
      final entry =
          c.specializations.where((s) => s.id == item.ref).firstOrNull;
      if (entry == null) return missing();
      final specialization =
          rules.specializations.specializationById(entry.id);
      return withInfo(
          specialization.name,
          degreeName(l10n, entry.degree),
          SpecializationInfo(rules: rules, specialization: specialization));

    case 'language':
      if (!c.languages.contains(item.ref)) return missing();
      return withInfo(displayName(item.ref), null,
          LanguageInfo(rules: rules, language: item.ref));

    case 'trait':
      if (!c.traitIds.contains(item.ref)) return missing();
      return withInfo(displayName(item.ref), l10n.trait,
          Text(rules.backgrounds.racialTraits[item.ref] ?? ''));

    case 'gear':
      final owned = c.inventory.where((i) => i.itemId == item.ref).firstOrNull;
      if (owned == null) return missing();
      return withInfo(owned.name, '×${owned.quantity}',
          ItemInfo(rules: rules, itemId: item.ref, name: owned.name));

    case 'stat':
      return ShownItem(
        title: statName(item.ref, l10n),
        value: statValue(item.ref, c, rules, l10n),
        details: statInfo(item.ref, c, rules, l10n),
      );

    case 'roll':
      return ShownItem(
        title: item.name,
        value: signed(item.value),
        subtitle: item.damage.isEmpty ? null : item.damage,
        details: Text(item.damage.isEmpty
            ? signed(item.value)
            : '${signed(item.value)}, ${item.damage}'),
        actionLabel: l10n.rollAction,
        onAction: () => roll(RollRequest(
          title: item.name,
          bonus: item.value,
          damage: item.damage.isEmpty ? null : item.damage,
        )),
      );

    default: // text, checkbox, counter: the view draws their controls
      return ShownItem(title: item.name);
  }
}
