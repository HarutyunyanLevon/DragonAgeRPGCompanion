import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../rules/models/classes.dart';
import '../../rules/models/rule_tables.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';
import '../../shared/linked_text.dart';

// Tables and lists shown under a term (the "extra" field of glossary.json).
// Each one is built from the game data, so the numbers can never differ from
// the rest of the app. Names inside the cells link to their entries.

/// A table with a bold header row. The last column takes the leftover width.
class _DataTable extends StatelessWidget {
  const _DataTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  Widget _cell(String text, {bool header = false}) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 16, 4),
        child: header
            ? Text(text, style: const TextStyle(fontWeight: FontWeight.bold))
            : LinkedText(text),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        columnWidths: {headers.length - 1: const FlexColumnWidth()},
        children: [
          TableRow(children: [for (final h in headers) _cell(h, header: true)]),
          for (final row in rows)
            TableRow(children: [for (final text in row) _cell(text)]),
        ],
      ),
    );
  }
}

Widget _classes(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colClass, l10n.primaryAbilities, l10n.health],
    rows: [
      for (final c in rules.classes.classes)
        [
          c.name,
          c.primaryAbilities.map(displayName).join(', '),
          '${c.startingHealth.base} + ${displayName(c.startingHealth.plus)} + ${c.startingHealth.dice}',
        ],
    ],
  );
}

Widget _abilities(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colAbility, l10n.colDescription],
    rows: [
      for (final ability in rules.backgrounds.abilities)
        [displayName(ability), rules.abilityDescriptions[ability] ?? ''],
    ],
  );
}

Widget _weaponGroups(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colGroup, l10n.colAttack, l10n.damageAbility],
    rows: [
      for (final g in rules.weaponGroups)
        [
          displayName(g.id),
          displayName(g.attackAbility),
          displayName(g.damageAbility),
        ],
    ],
  );
}

Widget _xpTable(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  final xp = rules.classes.xpByLevel;
  return _DataTable(
    headers: [l10n.colLevel, l10n.colXp],
    rows: [
      for (var i = 0; i < xp.length; i++) ['${i + 1}', '${xp[i]}'],
    ],
  );
}

Widget _advancementCost(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colRating, l10n.colCost],
    rows: [
      for (final a in rules.classes.advancementCost)
        ['${a.minRating} to ${a.maxRating}', '${a.cost}'],
    ],
  );
}

Widget _difficulties(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colDifficulty, l10n.colTn],
    rows: [
      for (final d in rules.ruleTables.difficulties) [d.name, '${d.number}'],
    ],
  );
}

Widget _thresholds(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colDifficulty, l10n.colThreshold],
    rows: [
      for (final d in rules.ruleTables.thresholds) [d.name, '${d.number}'],
    ],
  );
}

Widget _attackModifiers(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colModifier, l10n.colCircumstance],
    rows: [
      for (final m in rules.ruleTables.attackModifiers)
        [signed(m.modifier), m.circumstance],
    ],
  );
}

Widget _healing(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colMethod, l10n.colAmount],
    rows: [
      for (final h in rules.ruleTables.healing) [h.method, h.amount],
    ],
  );
}

Widget _majorActions(BuildContext context, RulesData rules) =>
    _actions(context, rules.ruleTables.majorActions);

Widget _minorActions(BuildContext context, RulesData rules) =>
    _actions(context, rules.ruleTables.minorActions);

Widget _actions(BuildContext context, List<ActionRule> actions) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colAction, l10n.colEffect],
    rows: [
      for (final a in actions) [a.name, a.effect],
    ],
  );
}

Widget _mishaps(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colDie, l10n.colMishap, l10n.colEffect],
    rows: [
      for (final m in rules.magic.mishaps) ['${m.die}', m.name, m.effect],
    ],
  );
}

Widget _armorStrain(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colArmor, l10n.colStrain],
    rows: [
      for (final e in rules.magic.armorStrain.entries)
        [displayName(e.key), '${e.value}'],
    ],
  );
}

Widget _spellStunts(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  return _DataTable(
    headers: [l10n.colSp, l10n.colStunt, l10n.colEffect],
    rows: [
      for (final s in rules.magic.standardStunts)
        [s.variable ? '${s.spCost}+' : '${s.spCost}', s.name, s.effect],
    ],
  );
}

Widget _schools(BuildContext context, RulesData rules) {
  final l10n = AppLocalizations.of(context);
  final schools = {for (final s in rules.spells) s.school}.toList()..sort();
  return _DataTable(
    headers: [l10n.colSchool, l10n.colSpells],
    rows: [
      for (final school in schools)
        [
          school,
          '${rules.spells.where((s) => s.school == school).length}',
        ],
    ],
  );
}

/// The powers of a class, level by level (shown on the class's entry).
class ClassPowersByLevel extends StatelessWidget {
  const ClassPowersByLevel({super.key, required this.classRules});

  final ClassRules classRules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ExpansionTile(
      title: Text(l10n.powersByLevel),
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final level in classRules.levels)
          if (level.powers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(l10n.levelN(level.level),
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final power in level.powers)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: LinkedText(power.text, label: power.name),
              ),
          ],
      ],
    );
  }
}

/// Extra names allowed in glossary.json, and what each one builds.
final Map<String, Widget Function(BuildContext, RulesData)> glossaryExtras = {
  'classes': _classes,
  'abilities': _abilities,
  'weapon-groups': _weaponGroups,
  'xp-table': _xpTable,
  'advancement-cost': _advancementCost,
  'difficulties': _difficulties,
  'thresholds': _thresholds,
  'attack-modifiers': _attackModifiers,
  'healing': _healing,
  'major-actions': _majorActions,
  'minor-actions': _minorActions,
  'mishaps': _mishaps,
  'armor-strain': _armorStrain,
  'spell-stunts': _spellStunts,
  'schools': _schools,
};
