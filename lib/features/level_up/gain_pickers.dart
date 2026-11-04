import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/level_up.dart';
import '../../character/magic.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart' show FocusRef;
import '../../rules/models/talents.dart' show Talent;
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart' show SubsectionTitle;
import '../../shared/info_row.dart';
import '../create/rule_info.dart';
import '../spells/custom_spells.dart';

/// One row of a pick list. [unmet] lists the rules the choice breaks: the row
/// is dimmed and picking it asks "Proceed anyway?" (strict rules, no GM).
class Choice {
  const Choice({
    required this.id,
    required this.title,
    required this.description,
    this.subtitle,
    this.unmet = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<String> unmet;

  /// Shown when the row is opened.
  final Widget description;
}

/// Pick exactly one of [choices] (radio buttons, each row opens its
/// description). [picked] is the id picked so far.
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.choices,
    required this.picked,
    required this.onPick,
  });

  final List<Choice> choices;
  final String? picked;
  final ValueChanged<String> onPick;

  Future<void> _pick(BuildContext context, Choice choice) async {
    if (choice.unmet.isNotEmpty) {
      final l10n = AppLocalizations.of(context);
      final ok = await confirm(
        context,
        title: l10n.requirementsNotMetTitle,
        body: l10n.requirementsNotMetBody(choice.title, choice.unmet.join('; ')),
        confirmLabel: l10n.proceedAnyway,
      );
      if (!ok) return;
    }
    onPick(choice.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final choice in choices)
        Opacity(
          opacity: choice.unmet.isEmpty ? 1 : 0.5,
          child: InfoRow(
            leading: Radio<String>(
              value: choice.id,
              groupValue: picked,
              onChanged: (_) => _pick(context, choice),
            ),
            title: choice.title,
            subtitle: choice.subtitle,
            child: choice.description,
          ),
        ),
    ]);
  }
}

/// The ability to advance. Even levels need a primary ability, odd levels a
/// secondary one; the other abilities are dimmed.
class AbilityAdvancePicker extends StatelessWidget {
  const AbilityAdvancePicker({
    super.key,
    required this.character,
    required this.rules,
    required this.plan,
    required this.picked,
    required this.onPick,
  });

  final Character character;
  final RulesData rules;
  final LevelPlan plan;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ChoiceList(
      picked: picked,
      onPick: onPick,
      choices: [
        for (final ability in rules.backgrounds.abilities)
          Choice(
            id: ability,
            title: displayName(ability),
            subtitle: l10n.advancementState(
              character.ability(ability),
              character.bankedAdvancements[ability] ?? 0,
              rules.classes.advancementsNeeded(character.ability(ability) + 1),
            ),
            unmet: plan.abilities.contains(ability)
                ? const []
                : [plan.level.isEven ? l10n.needsPrimary : l10n.needsSecondary],
            description: AbilityInfo(rules: rules, ability: ability),
          ),
      ],
    );
  }
}

/// A focus out of [options] (see focusChoices in character/level_up.dart).
class FocusPicker extends StatelessWidget {
  const FocusPicker({
    super.key,
    required this.rules,
    required this.options,
    required this.picked,
    required this.onPick,
  });

  final RulesData rules;
  final List<FocusRef> options;
  final FocusRef? picked;
  final ValueChanged<FocusRef> onPick;

  static String _id(FocusRef f) => '${f.ability}/${f.focus}';

  @override
  Widget build(BuildContext context) {
    return ChoiceList(
      picked: picked == null ? null : _id(picked!),
      onPick: (id) => onPick(options.firstWhere((f) => _id(f) == id)),
      choices: [
        for (final f in options)
          Choice(
            id: _id(f),
            title: displayName(f.focus),
            subtitle: displayName(f.ability),
            description:
                FocusInfo(rules: rules, ability: f.ability, focus: f.focus),
          ),
      ],
    );
  }
}

/// A new talent, or the next degree of one the character has.
class TalentPicker extends StatelessWidget {
  const TalentPicker({
    super.key,
    required this.character,
    required this.rules,
    required this.picked,
    required this.onPick,
  });

  final Character character;
  final RulesData rules;
  final String? picked;
  final ValueChanged<String> onPick;

  Choice _choice(AppLocalizations l10n, Talent talent) {
    final owned = character.talents.where((t) => t.id == talent.id).firstOrNull;

    return Choice(
      id: talent.id,
      title: talent.name,
      // A talent the character has gains its next degree.
      subtitle: owned == null
          ? null
          : l10n.talentRaise(degreeName(l10n, owned.degree),
              degreeName(l10n, owned.degree + 1)),
      unmet: [
        for (final r in unmetTalentRequirements(character, talent))
          requirementText(l10n, rules, r),
      ],
      description:
          TalentInfo(rules: rules, talent: talent, degree: owned?.degree ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ChoiceList(
      picked: picked,
      onPick: onPick,
      choices: [
        for (final talent in talentChoices(character, rules))
          _choice(l10n, talent),
      ],
    );
  }
}

class SpecializationPicker extends StatelessWidget {
  const SpecializationPicker({
    super.key,
    required this.character,
    required this.rules,
    required this.picked,
    required this.onPick,
  });

  final Character character;
  final RulesData rules;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ChoiceList(
      picked: picked,
      onPick: onPick,
      choices: [
        for (final s in specializationChoices(character, rules))
          Choice(
            id: s.id,
            title: s.name,
            unmet: [
              for (final r in unmetPrerequisites(character, s.requirements))
                requirementText(l10n, rules, r),
            ],
            description:
                SpecializationInfo(rules: rules, specialization: s),
          ),
      ],
    );
  }
}

class WeaponGroupPicker extends StatelessWidget {
  const WeaponGroupPicker({
    super.key,
    required this.character,
    required this.rules,
    required this.picked,
    required this.onPick,
  });

  final Character character;
  final RulesData rules;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ChoiceList(
      picked: picked,
      onPick: onPick,
      choices: [
        for (final group in weaponGroupChoices(character, rules))
          Choice(
            id: group,
            title: displayName(group),
            description: WeaponGroupInfo(rules: rules, group: group),
          ),
      ],
    );
  }
}

/// A spell the character can learn now (book and homebrew), in school
/// sections with school chips and a search. Spells with unmet requirements
/// are left out; the Spells tab can still learn them with "Proceed anyway".
class SpellChoicePicker extends ConsumerStatefulWidget {
  const SpellChoicePicker({
    super.key,
    required this.character,
    required this.picked,
    required this.onPick,
  });

  final Character character;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  ConsumerState<SpellChoicePicker> createState() => _SpellChoicePickerState();
}

class _SpellChoicePickerState extends ConsumerState<SpellChoicePicker> {
  String _query = '';

  /// The school picked in the chips; null shows all schools.
  String? _school;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.toLowerCase();

    // Only spells the character can learn now: not known, requirements met.
    final learnable = [
      for (final s in ref.watch(allSpellsProvider))
        if (!widget.character.spellIds.contains(s.id) &&
            unmetRequirements(widget.character, s).isEmpty)
          s,
    ];
    final schools = {for (final s in learnable) s.school}.toList()..sort();
    final shown = [
      for (final s in learnable)
        if ((_school == null || s.school == _school) &&
            s.name.toLowerCase().contains(query))
          s,
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.searchSpells,
        ),
        onChanged: (text) => setState(() => _query = text),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [
        ChoiceChip(
          label: Text(l10n.filterAll),
          selected: _school == null,
          onSelected: (_) => setState(() => _school = null),
        ),
        for (final school in schools)
          ChoiceChip(
            label: Text(school),
            selected: _school == school,
            onSelected: (_) => setState(() => _school = school),
          ),
      ]),
      for (final school in schools)
        if (shown.any((s) => s.school == school)) ...[
          SubsectionTitle(school),
          ChoiceList(
            picked: widget.picked,
            onPick: widget.onPick,
            choices: [
              for (final spell in shown.where((s) => s.school == school))
                Choice(
                  id: spell.id,
                  title: spell.name,
                  subtitle: '${spell.mana} · ${spell.castTime}',
                  description: SpellInfo(spell: spell),
                ),
            ],
          ),
        ],
    ]);
  }
}
