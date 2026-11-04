import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../character/level_up.dart';
import '../../character/magic.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart' show FocusRef;
import '../../rules/rules_data.dart';
import '../../shared/die_row.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import 'gain_pickers.dart';

/// One scrolling page with a section for everything the new level gives.
/// Health and the ability advancement are required; every other gain can be
/// skipped ("gained via quest") and is then owed: the Sheet offers it later.
class LevelUpPage extends StatefulWidget {
  const LevelUpPage({
    super.key,
    required this.character,
    required this.rules,
    required this.onFinish,
    this.stepLabel,
  });

  final Character character;
  final RulesData rules;

  /// Gets the leveled-up character and decides what happens next (the Sheet
  /// saves it and closes the page, the wizard opens the next level).
  final Future<void> Function(Character leveledUp) onFinish;

  /// "Level 2 of 5" when the page is a step of the creation wizard.
  final String? stepLabel;

  @override
  State<LevelUpPage> createState() => _LevelUpPageState();
}

class _LevelUpPageState extends State<LevelUpPage> {
  // Keys of the skippable gains.
  static const _focusKey = 'focus';
  static const _classFocusKey = 'classFocus';
  static const _talentKey = 'talent';
  static const _weaponGroupKey = 'weaponGroup';
  static const _specializationKey = 'specialization';
  static const _spellKey = 'spell';

  late final _plan = LevelPlan(
    widget.rules.classes.classById(widget.character.classId),
    widget.character.level + 1,
  );

  String? _ability;
  int? _healthDie;
  int? _manaDie;
  FocusRef? _focus;
  FocusRef? _classFocus;
  String? _talent;
  String? _weaponGroup;
  String? _specialization;
  String? _spell;
  final _skipped = <String>{};

  Character get _character => widget.character;
  RulesData get _rules => widget.rules;

  /// Only mages learn spells at level-up.
  bool get _hasSpell => _plan.hasSpell && canCast(_character, _rules);

  bool _done(String key, Object? picked) =>
      picked != null || _skipped.contains(key);

  /// A skipped gain counts as not chosen (null), even if something was picked.
  T? _unlessSkipped<T>(String key, T? picked) =>
      _skipped.contains(key) ? null : picked;

  bool get _canFinish =>
      _ability != null &&
      _healthDie != null &&
      (!_plan.hasMana || _manaDie != null) &&
      _done(_focusKey, _focus) &&
      (!_plan.hasClassFocus || _done(_classFocusKey, _classFocus)) &&
      (!_plan.hasTalent || _done(_talentKey, _talent)) &&
      (!_plan.hasWeaponGroup || _done(_weaponGroupKey, _weaponGroup)) &&
      (!_plan.startsSpecialization ||
          _done(_specializationKey, _specialization)) &&
      (!_hasSpell || _done(_spellKey, _spell));

  void _setSkipped(String key, bool skipped) => setState(() {
        skipped ? _skipped.add(key) : _skipped.remove(key);
      });

  Future<void> _finish() async {
    final changed = applyLevelUp(
      _character,
      _rules,
      LevelUpChoices(
        ability: _ability!,
        healthDie: _healthDie!,
        manaDie: _manaDie ?? 0,
        focus: _unlessSkipped(_focusKey, _focus),
        classFocus: _unlessSkipped(_classFocusKey, _classFocus),
        talentId: _unlessSkipped(_talentKey, _talent),
        weaponGroup: _unlessSkipped(_weaponGroupKey, _weaponGroup),
        specializationId:
            _unlessSkipped(_specializationKey, _specialization),
        spellId: _unlessSkipped(_spellKey, _spell),
      ),
    );
    await widget.onFinish(changed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final classRules = _plan.classRules;

    // Health and mana use the ability scores AFTER this level's advancement.
    final scores = _ability == null
        ? _character.abilities
        : advanceAbility(_character, _rules.classes, _ability!).abilities;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.levelUpTo(_plan.level))),
      body: FormBody(children: [
        if (widget.stepLabel != null) ...[
          Text(widget.stepLabel!, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
        ],
        _GivesCard(character: _character, rules: _rules, plan: _plan),
        _GainSection(
          title: l10n.sectionAbilityAdvance,
          done: _ability != null,
          child: AbilityAdvancePicker(
            character: _character,
            rules: _rules,
            plan: _plan,
            picked: _ability,
            onPick: (id) => setState(() => _ability = id),
          ),
        ),
        _GainSection(
          title: l10n.sectionNewFocus,
          done: _done(_focusKey, _focus),
          skipped: _skipped.contains(_focusKey),
          onSkippedChanged: (v) => _setSkipped(_focusKey, v),
          child: FocusPicker(
            rules: _rules,
            options: focusChoices(_character, _rules, _plan.abilities),
            picked: _focus,
            onPick: (f) => setState(() => _focus = f),
          ),
        ),
        if (_plan.hasClassFocus)
          _GainSection(
            title: l10n.sectionClassFocus,
            done: _done(_classFocusKey, _classFocus),
            skipped: _skipped.contains(_classFocusKey),
            onSkippedChanged: (v) => _setSkipped(_classFocusKey, v),
            child: FocusPicker(
              rules: _rules,
              options: notOwned(_character, _plan.data.focusChoices),
              picked: _classFocus,
              onPick: (f) => setState(() => _classFocus = f),
            ),
          ),
        if (_plan.hasTalent)
          _GainSection(
            title: l10n.sectionNewTalent,
            done: _done(_talentKey, _talent),
            skipped: _skipped.contains(_talentKey),
            onSkippedChanged: (v) => _setSkipped(_talentKey, v),
            child: TalentPicker(
              character: _character,
              rules: _rules,
              picked: _talent,
              onPick: (id) => setState(() => _talent = id),
            ),
          ),
        if (_plan.hasWeaponGroup)
          _GainSection(
            title: l10n.sectionNewWeaponGroup,
            done: _done(_weaponGroupKey, _weaponGroup),
            skipped: _skipped.contains(_weaponGroupKey),
            onSkippedChanged: (v) => _setSkipped(_weaponGroupKey, v),
            child: WeaponGroupPicker(
              character: _character,
              rules: _rules,
              picked: _weaponGroup,
              onPick: (id) => setState(() => _weaponGroup = id),
            ),
          ),
        if (_plan.startsSpecialization)
          _GainSection(
            title: l10n.sectionNewSpecialization,
            done: _done(_specializationKey, _specialization),
            skipped: _skipped.contains(_specializationKey),
            onSkippedChanged: (v) => _setSkipped(_specializationKey, v),
            child: SpecializationPicker(
              character: _character,
              rules: _rules,
              picked: _specialization,
              onPick: (id) => setState(() => _specialization = id),
            ),
          ),
        if (_hasSpell)
          _GainSection(
            title: l10n.sectionNewSpell,
            done: _done(_spellKey, _spell),
            skipped: _skipped.contains(_spellKey),
            onSkippedChanged: (v) => _setSkipped(_spellKey, v),
            child: SpellChoicePicker(
              character: _character,
              picked: _spell,
              onPick: (id) => setState(() => _spell = id),
            ),
          ),
        DieRow(
          label: l10n.health,
          base: _character.maxHealth,
          ability: displayName(classRules.startingHealth.plus),
          score: scores[classRules.startingHealth.plus] ?? 0,
          die: _healthDie,
          onChanged: (die) => setState(() => _healthDie = die),
        ),
        if (_plan.hasMana)
          DieRow(
            label: l10n.mana,
            base: _character.maxMana,
            ability: displayName(classRules.mana!.plus),
            score: scores[classRules.mana!.plus] ?? 0,
            die: _manaDie,
            onChanged: (die) => setState(() => _manaDie = die),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _canFinish ? _finish : null,
          child: Text(l10n.finishLevelUp),
        ),
      ]),
    );
  }
}

/// A titled section. Skippable sections have a checkbox that replaces the
/// picker with a note; [done] shows a check mark in the title.
class _GainSection extends StatelessWidget {
  const _GainSection({
    required this.title,
    required this.done,
    required this.child,
    this.skipped = false,
    this.onSkippedChanged,
  });

  final String title;
  final bool done;
  final Widget child;
  final bool skipped;

  /// Null for gains that cannot be skipped.
  final ValueChanged<bool>? onSkippedChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: SectionTitle(title)),
          if (done)
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary),
        ]),
        if (onSkippedChanged != null)
          CheckboxListTile(
            value: skipped,
            onChanged: (v) => onSkippedChanged!(v ?? false),
            title: Text(l10n.skipGain),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        if (skipped) Text(l10n.skippedGainNote) else child,
      ]),
    );
  }
}

/// What the level gives without a choice: new class powers and a higher
/// degree of the specialization of the slot.
class _GivesCard extends StatelessWidget {
  const _GivesCard({
    required this.character,
    required this.rules,
    required this.plan,
  });

  final Character character;
  final RulesData rules;
  final LevelPlan plan;

  /// "Fire Mage becomes Journeyman" when this level raises a specialization.
  String? _specializationLine(AppLocalizations l10n) {
    final step = plan.data.specialization;
    if (step == null || plan.startsSpecialization) return null;
    final owned = specializationInSlot(character, step.slot);
    if (owned == null) return null;
    return l10n.specializationUpgrade(
      rules.specializations.specializationById(owned.id).name,
      degreeName(l10n, degreeNumber(step.degree)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final specialization = _specializationLine(l10n);
    if (plan.data.powers.isEmpty && specialization == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.levelGives, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final power in plan.data.powers) ...[
            Text(power.name, style: Theme.of(context).textTheme.titleSmall),
            Text(power.text),
            const SizedBox(height: 8),
          ],
          if (specialization != null) Text(specialization),
        ]),
      ),
    );
  }
}
