import 'package:flutter/material.dart';

import '../../character/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/classes.dart';
import '../../rules/models/gear.dart';
import '../../rules/models/specializations.dart';
import '../../rules/models/spell.dart';
import '../../rules/models/talents.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/money.dart';

// Descriptions of the things the wizard lets you choose. Each widget is the
// text inside a description box: a title line and a few facts.

/// "Name" in bold, or "Label: text" with the label in bold.
class _Line extends StatelessWidget {
  const _Line(this.text, {this.label});

  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(TextSpan(children: [
        if (label != null)
          TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: text),
      ])),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// "Cunning, Dexterity" -> every focus name of [ability].
String _focusNames(RulesData rules, String ability) => [
      for (final f in rules.focuses)
        if (f.ability == ability) f.name,
    ].join(', ');

// ---- abilities, focuses, languages

class AbilityInfo extends StatelessWidget {
  const AbilityInfo({super.key, required this.rules, required this.ability});

  final RulesData rules;
  final String ability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(displayName(ability)),
      _Line(rules.abilityDescriptions[ability] ?? ''),
      _Line(_focusNames(rules, ability), label: l10n.focuses),
    ]);
  }
}

class FocusInfo extends StatelessWidget {
  const FocusInfo({
    super.key,
    required this.rules,
    required this.ability,
    required this.focus,
  });

  final RulesData rules;
  final String ability;
  final String focus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final abilityName = displayName(ability);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(l10n.focusLabel(abilityName, displayName(focus))),
      _Line(l10n.focusRule(abilityName)),
      _Line(rules.abilityDescriptions[ability] ?? '', label: abilityName),
      _Line(_focusNames(rules, ability), label: l10n.focuses),
    ]);
  }
}

class LanguageInfo extends StatelessWidget {
  const LanguageInfo({super.key, required this.rules, required this.language});

  static const _maxBackgrounds = 5;

  final RulesData rules;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backgrounds = [
      for (final b in rules.backgrounds.backgrounds)
        if (b.languages.contains(language) ||
            (b.languageChoice?.from.contains(language) ?? false))
          b,
    ];
    final races = {for (final b in backgrounds) ...b.races};
    final names = backgrounds.take(_maxBackgrounds).map((b) => b.name).join(', ');
    final more = backgrounds.length - _maxBackgrounds;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(displayName(language)),
      _Line(races.map(displayName).join(', '), label: l10n.languageRaces),
      _Line(more > 0 ? l10n.andMore(names, more) : names,
          label: l10n.languageBackgrounds),
    ]);
  }
}

// ---- class, weapon groups, talents, spells

class ClassInfo extends StatelessWidget {
  const ClassInfo({super.key, required this.rules, required this.classRules});

  final RulesData rules;
  final ClassRules classRules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = classRules;
    final health = c.startingHealth;
    final mana = c.mana;
    final groups = c.weaponGroups;
    final talents = c.startingTalents;
    final level1 = c.levelData(1);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(c.name),
      _Line(c.primaryAbilities.map(displayName).join(', '),
          label: l10n.primaryAbilities),
      _Line(c.secondaryAbilities.map(displayName).join(', '),
          label: l10n.secondaryAbilities),
      _Line('${health.base} + ${displayName(health.plus)} + ${health.dice}',
          label: l10n.health),
      if (mana != null)
        _Line('${mana.startBase} + ${displayName(mana.plus)} + 1d6',
            label: l10n.mana),
      _Line(
        [
          ...groups.fixed.map(displayName),
          if (groups.pick > 0) l10n.pickOne(groups.pick),
        ].join(', '),
        label: l10n.weaponGroups,
      ),
      _Line(
        [
          ...talents.fixed.map((id) => rules.talents.talentById(id).name),
          l10n.pickFrom(
            talents.pick,
            talents.pickFrom
                .map((id) => rules.talents.talentById(id).name)
                .join(', '),
          ),
        ].join(', '),
        label: l10n.talents,
      ),
      if (c.startingSpells > 0)
        _Line('${c.startingSpells}', label: l10n.spells),
      _Line(c.startingEquipment, label: l10n.equipment),
      for (final power in level1.powers) _Line(power.text, label: power.name),
    ]);
  }
}

class WeaponGroupInfo extends StatelessWidget {
  const WeaponGroupInfo({super.key, required this.rules, required this.group});

  final RulesData rules;
  final String group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final facts = rules.weaponGroupById(group);
    final attack = displayName(facts.attackAbility);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(displayName(group)),
      _Line(l10n.attackRule(attack, l10n.focusLabel(attack, displayName(group)))),
      _Line(displayName(facts.damageAbility), label: l10n.damageAbility),
      for (final weapon in rules.weaponsIn(group))
        _Line(weapon.damage, label: weapon.name),
    ]);
  }
}

/// All three degrees of a talent. In the wizard ([degree] null) the talent is
/// picked as a starting talent, so its requirements do not matter. On the
/// Sheet [degree] is the degree the character has.
class TalentInfo extends StatelessWidget {
  const TalentInfo(
      {super.key, required this.rules, required this.talent, this.degree});

  final RulesData rules;
  final Talent talent;
  final int? degree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(talent.name),
      _Line(talent.degrees.novice,
          label: degree == null ? l10n.degreeNovice : l10n.degreeNameNovice),
      _Line(talent.degrees.journeyman,
          label: degree == null
              ? l10n.degreeJourneyman
              : l10n.degreeNameJourneyman),
      _Line(talent.degrees.master,
          label: degree == null ? l10n.degreeMaster : l10n.degreeNameMaster),
      if (talent.requirements.isNotEmpty)
        _Line(
          [
            talent.requirements
                .map((r) => requirementText(l10n, rules, r))
                .join('; '),
            if (degree == null) l10n.startingTalentNoRequirements,
          ].join('. '),
          label: l10n.requirements,
        ),
      for (final note in talent.notes) _Line(note),
    ]);
  }
}

/// A talent requirement in words: "Dexterity 3+", "Trained in: Bows".
String requirementText(
    AppLocalizations l10n, RulesData rules, Requirement r) {
  String names(List<String> ids) => ids.map(displayName).join(' / ');
  String all(List<Requirement> options) =>
      options.map((o) => requirementText(l10n, rules, o)).join(' / ');

  return switch (r.type) {
    'ability' => l10n.reqAbility(displayName(r.ability!), r.min!),
    'focus' => l10n.resultFocus(displayName(r.ability!), displayName(r.focus!)),
    'weaponGroup' => l10n.reqWeaponGroup(names(r.anyOf!)),
    'race' => l10n.reqRace(names(r.anyOf ?? [r.race!])),
    'talent' => l10n.reqTalent(
        rules.talents.talentById(r.talent!).name, displayName(r.degree!)),
    'story' => r.text!,
    'focusInAbility' => l10n.reqFocusIn(displayName(r.ability!)),
    _ => l10n.reqAnyOf(all(r.options!)), // focusAnyOf, talentAnyOf
  };
}

/// Everything about a spell except its name (the row shows that).
class SpellInfo extends StatelessWidget {
  const SpellInfo({super.key, required this.spell});

  final Spell spell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Line(spell.description),
      _Line('${spell.school}, ${spell.type}', label: l10n.spellType),
      _Line(spell.mana, label: l10n.mana),
      _Line(spell.castTime, label: l10n.castingTime),
      _Line(spell.tn, label: l10n.targetNumber),
      _Line(spell.test, label: l10n.spellTest),
      if (!spell.hasNoRequirement)
        _Line(spell.requirement, label: l10n.requirements),
    ]);
  }
}

/// A specialization: class, requirements, the three degrees and notes.
class SpecializationInfo extends StatelessWidget {
  const SpecializationInfo(
      {super.key, required this.rules, required this.specialization});

  final RulesData rules;
  final Specialization specialization;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = specialization;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(s.name),
      _Line(displayName(s.classId), label: l10n.characterClass),
      _Line(s.degrees.novice, label: l10n.degreeNameNovice),
      _Line(s.degrees.journeyman, label: l10n.degreeNameJourneyman),
      _Line(s.degrees.master, label: l10n.degreeNameMaster),
      if (s.requirements.isNotEmpty)
        _Line(
          s.requirements.map((r) => requirementText(l10n, rules, r)).join('; '),
          label: l10n.requirements,
        ),
      for (final note in s.notes) _Line(note),
    ]);
  }
}

// ---- gear

/// An armor, shield, weapon or other item: the facts from gear.json and the
/// price. [itemId] is null for a custom item (then only [note] is shown).
class ItemInfo extends StatelessWidget {
  const ItemInfo({
    super.key,
    required this.rules,
    required this.itemId,
    required this.name,
    this.note = '',
  });

  final RulesData rules;
  final String? itemId;
  final String name;
  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final armor = rules.armorById(itemId);
    final shield = rules.shieldById(itemId);
    final weapon = rules.weaponById(itemId);
    final entry = rules.catalog.where((e) => e.id == itemId).firstOrNull;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(name),
      if (armor != null) ...[
        _Line('${armor.armorRating}', label: l10n.armorRating),
        _Line('${armor.armorPenalty}', label: l10n.armorPenalty),
        _Line(l10n.armorPenaltyRule),
      ],
      if (shield != null) ...[
        _Line(signed(shield.defenseBonus), label: l10n.defense),
        _Line(l10n.shieldRule),
      ],
      if (weapon != null) ..._weaponLines(l10n, weapon),
      if (entry != null) ...[
        _Line(moneyText(l10n, entry.costCp), label: l10n.price),
        if (entry.note != null) _Line(entry.note!),
      ],
      if (itemId == null) _Line(l10n.customItem),
      if (note.isNotEmpty) _Line(note),
    ]);
  }

  List<Widget> _weaponLines(AppLocalizations l10n, Weapon weapon) {
    final group = rules.weaponGroupById(weapon.group);
    final range = weapon.range;

    return [
      _Line(displayName(weapon.group), label: l10n.weaponGroup),
      _Line(weapon.damage, label: l10n.damage),
      _Line(
          l10n.weaponAbilities(displayName(group.attackAbility),
              displayName(group.damageAbility)),
          label: l10n.usesAbilities),
      if (weapon.minStrength > 0)
        _Line('${weapon.minStrength}', label: l10n.minimumStrength),
      if (weapon.twoHanded) _Line(l10n.twoHanded),
      if (range != null)
        _Line(l10n.rangeLine(range.short, range.long, range.reload),
            label: l10n.range),
    ];
  }
}

// ---- combat numbers and money

/// How Defense, Speed or Armor Rating was worked out, with the character's
/// own numbers.
class CombatStatInfo extends StatelessWidget {
  const CombatStatInfo({super.key, required this.stat, required this.numbers});

  final CombatStat stat;
  final CombatNumbers numbers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = numbers;

    final (title, formula, rule) = switch (stat) {
      CombatStat.defense => (
          l10n.defense,
          l10n.defenseFormula(
              n.dexterityForDefense, n.shieldBonus, n.defense),
          l10n.defenseRule,
        ),
      CombatStat.speed => (
          l10n.speed,
          l10n.speedFormula(
              n.baseSpeed, n.dexterity, n.armorPenalty, n.speed),
          l10n.speedRule,
        ),
      CombatStat.armorRating => (
          l10n.armorRating,
          '${n.armorRating}',
          l10n.armorRatingRule,
        ),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(title),
      _Line(formula),
      _Line(rule),
    ]);
  }
}

enum CombatStat { defense, speed, armorRating }

/// What gold, silver and copper are worth.
class MoneyInfo extends StatelessWidget {
  const MoneyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Title(l10n.money),
      _Line(l10n.moneyRule(copperPerSilver, copperPerGold ~/ copperPerSilver)),
    ]);
  }
}
