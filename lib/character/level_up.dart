import 'dart:math';

import '../rules/models/backgrounds.dart' show FocusRef;
import '../rules/models/classes.dart';
import '../rules/models/specializations.dart';
import '../rules/models/talents.dart';
import '../rules/rules_data.dart';
import 'character.dart';

/// Level-up rules (book, file 02) as pure functions: what a level gives, how
/// the choices change the character, which gains are still owed, and Undo.
/// The screens only collect the choices.

/// The highest level the app levels up to for now (levels 11-20 need a
/// different health / mana rule and doubled focuses).
const maxLevel = 10;

// ---------------------------------------------------------------------------
// Owed gains: stored in Character.owedGains as plain strings.

const owedTalent = 'talent';
const owedWeaponGroup = 'weaponGroup';
const owedFocusPrimary = 'focus:primary';
const owedFocusSecondary = 'focus:secondary';
const _owedClassFocus = 'classFocus:'; // + the class level that gave it
const _owedSpecialization = 'specialization:'; // + the slot (6 or 14)

String owedClassFocus(int classLevel) => '$_owedClassFocus$classLevel';
String owedSpecialization(int slot) => '$_owedSpecialization$slot';

bool isOwedClassFocus(String id) => id.startsWith(_owedClassFocus);
bool isOwedSpecialization(String id) => id.startsWith(_owedSpecialization);

/// The number after the colon: the class level or the slot.
int owedNumber(String id) => int.parse(id.split(':').last);

/// A copy without one entry of [owedId] (the same gain can be owed twice).
Character withoutOwed(Character character, String owedId) {
  final owed = [...character.owedGains]..remove(owedId);
  return character.copyWith(owedGains: owed);
}

// ---------------------------------------------------------------------------
// What a level gives

/// 'novice' -> 1, 'journeyman' -> 2, 'master' -> 3.
int degreeNumber(String degree) =>
    const {'novice': 1, 'journeyman': 2, 'master': 3}[degree]!;

/// What reaching [level] gives a class: the class table row plus the rules
/// every level shares (an ability advancement, a focus, health, mana).
class LevelPlan {
  LevelPlan(this.classRules, this.level) : data = classRules.levelData(level);

  final ClassRules classRules;

  /// The NEW level.
  final int level;
  final ClassLevel data;

  bool get hasMana => classRules.mana != null;

  /// Even levels use primary abilities, odd levels secondary ones.
  List<String> get abilities =>
      level.isEven ? classRules.primaryAbilities : classRules.secondaryAbilities;
  String get owedFocus => level.isEven ? owedFocusPrimary : owedFocusSecondary;

  bool get hasSpell => data.gains.contains('spell');
  bool get hasTalent => data.gains.contains('talent');
  bool get hasWeaponGroup => data.gains.contains('weaponGroup');
  bool get hasClassFocus => data.focusChoices.isNotEmpty;

  /// A new specialization is chosen at the first step of a slot (Novice).
  bool get startsSpecialization => data.specialization?.degree == 'novice';
}

/// The picks of one level-up. Required picks are never null; a skippable
/// gain that is null was skipped (it becomes an owed gain).
class LevelUpChoices {
  const LevelUpChoices({
    required this.ability,
    required this.healthDie,
    this.manaDie = 0,
    this.focus,
    this.classFocus,
    this.talentId,
    this.weaponGroup,
    this.specializationId,
    this.spellId,
  });

  final String ability;
  final int healthDie;
  final int manaDie;
  final FocusRef? focus;
  final FocusRef? classFocus;
  final String? talentId;
  final String? weaponGroup;
  final String? specializationId;
  final String? spellId;
}

// ---------------------------------------------------------------------------
// The single gains (also used for owed gains taken from the Sheet)

/// One advancement on [ability]. The rating rises when all the advancements
/// it costs are paid; until then they are banked.
Character advanceAbility(
    Character character, ClassesFile classes, String ability) {
  final banked = (character.bankedAdvancements[ability] ?? 0) + 1;
  final newRating = character.ability(ability) + 1;
  final raised = banked >= classes.advancementsNeeded(newRating);

  return character.copyWith(
    abilities: {
      ...character.abilities,
      ability: raised ? newRating : character.ability(ability),
    },
    bankedAdvancements: {
      ...character.bankedAdvancements,
      ability: raised ? 0 : banked,
    },
  );
}

Character addFocus(Character character, FocusRef focus) {
  if (_hasFocus(character, focus)) return character;
  return character.copyWith(focuses: [
    ...character.focuses,
    CharacterFocus(ability: focus.ability, focus: focus.focus),
  ]);
}

/// A new talent at Novice, or one degree more of a talent the character has.
Character addTalent(Character character, String talentId) {
  final owned = character.talents.where((t) => t.id == talentId).firstOrNull;
  if (owned == null) {
    return character.copyWith(
        talents: [...character.talents, DegreeEntry(id: talentId, degree: 1)]);
  }
  return character.copyWith(talents: [
    for (final t in character.talents)
      t.id == talentId ? t.withDegree(min(t.degree + 1, 3)) : t,
  ]);
}

Character addWeaponGroup(Character character, String group) {
  if (character.weaponGroups.contains(group)) return character;
  return character.copyWith(weaponGroups: [...character.weaponGroups, group]);
}

/// The degree a specialization of the class slot [slot] has at [level]:
/// Novice at the slot level, Journeyman 2 levels later, Master 4 later.
int specializationDegreeAt(int slot, int level) =>
    level >= slot + 4 ? 3 : (level >= slot + 2 ? 2 : 1);

/// A new specialization in the class slot [slot]. Added late, it starts at the
/// degree the class table gives for the character's current level.
Character addSpecialization(Character character, String id, int slot) {
  return character.copyWith(specializations: [
    ...character.specializations,
    DegreeEntry(
        id: id,
        degree: specializationDegreeAt(slot, character.level),
        slot: slot),
  ]);
}

/// The specialization of [slot], if the character has one.
DegreeEntry? specializationInSlot(Character character, int slot) =>
    character.specializations.where((s) => s.slot == slot).firstOrNull;

bool _hasFocus(Character character, FocusRef focus) => character.focuses
    .any((f) => f.ability == focus.ability && f.focus == focus.focus);

// ---------------------------------------------------------------------------
// The options a gain offers

/// Focuses of [abilities] the character does not have yet, sorted.
List<FocusRef> focusChoices(
    Character character, RulesData rules, List<String> abilities) {
  final choices = [
    for (final f in rules.focuses)
      if (abilities.contains(f.ability))
        FocusRef(ability: f.ability, focus: f.id),
  ];
  return notOwned(character, choices)
    ..sort((a, b) => a.ability != b.ability
        ? a.ability.compareTo(b.ability)
        : a.focus.compareTo(b.focus));
}

/// [choices] without the focuses the character has.
List<FocusRef> notOwned(Character character, List<FocusRef> choices) =>
    [for (final f in choices) if (!_hasFocus(character, f)) f];

/// Every weapon group the character does not have.
List<String> weaponGroupChoices(Character character, RulesData rules) => [
      for (final g in rules.weaponGroups)
        if (!character.weaponGroups.contains(g.id)) g.id,
    ];

/// Talents of the character's class that are not at Master yet.
List<Talent> talentChoices(Character character, RulesData rules) => [
      for (final t in rules.talents.talents)
        if (t.classes.contains(character.classId) && _talentDegree(character, t.id) < 3)
          t,
    ];

/// Specializations of the character's class it does not have yet.
List<Specialization> specializationChoices(
        Character character, RulesData rules) =>
    [
      for (final s in rules.specializations.specializations)
        if (s.classId == character.classId &&
            !character.specializations.any((e) => e.id == s.id))
          s,
    ];

int _talentDegree(Character character, String talentId) =>
    character.talents.where((t) => t.id == talentId).firstOrNull?.degree ?? 0;

/// The requirements of a NEW talent [talent] the character does not meet.
/// A talent the character already has needs none for its next degree.
List<Requirement> unmetTalentRequirements(Character character, Talent talent) =>
    _talentDegree(character, talent.id) > 0
        ? const []
        : unmetPrerequisites(character, talent.requirements);

// ---------------------------------------------------------------------------
// Requirements of talents and specializations

List<Requirement> unmetPrerequisites(
        Character character, List<Requirement> requirements) =>
    [
      for (final r in requirements)
        if (!meetsPrerequisite(character, r)) r,
    ];

/// Whether the character meets one requirement. A "story" requirement can
/// only be judged by the player, so it counts as not met.
bool meetsPrerequisite(Character character, Requirement r) => switch (r.type) {
      'ability' => character.ability(r.ability!) >= r.min!,
      'focus' => character.focuses
          .any((f) => f.ability == r.ability && f.focus == r.focus),
      'focusInAbility' => character.focuses.any((f) => f.ability == r.ability),
      'weaponGroup' => r.anyOf!.any(character.weaponGroups.contains),
      'race' => (r.anyOf ?? [r.race!]).contains(character.race),
      'talent' => _talentDegree(character, r.talent!) >= degreeNumber(r.degree!),
      'focusAnyOf' ||
      'talentAnyOf' =>
        r.options!.any((o) => meetsPrerequisite(character, o)),
      _ => false,
    };

// ---------------------------------------------------------------------------
// The whole level-up

/// Whether the character has enough experience for the next level.
bool hasXpForNextLevel(Character character, ClassesFile classes) =>
    character.xp >= classes.xpForLevel(character.level + 1);

/// The character after leveling up with [choices]. Health and mana grow by the
/// roll plus the ability AFTER this level's advancement; current health and
/// mana grow by the same amount. Skipped gains become owed gains.
Character applyLevelUp(
    Character before, RulesData rules, LevelUpChoices choices) {
  final classRules = rules.classes.classById(before.classId);
  final plan = LevelPlan(classRules, before.level + 1);
  final owed = [...before.owedGains];

  var c = advanceAbility(before, rules.classes, choices.ability);

  final healthGain =
      choices.healthDie + c.ability(classRules.startingHealth.plus);
  c = c.copyWith(
    level: plan.level,
    maxHealth: c.maxHealth + healthGain,
    health: c.health + healthGain,
  );
  if (classRules.mana != null) {
    final manaGain = choices.manaDie + c.ability(classRules.mana!.plus);
    c = c.copyWith(maxMana: c.maxMana + manaGain, mana: c.mana + manaGain);
  }

  // The focus every level gives.
  if (choices.focus == null) {
    owed.add(plan.owedFocus);
  } else {
    c = addFocus(c, choices.focus!);
  }

  if (plan.hasClassFocus) {
    if (choices.classFocus == null) {
      owed.add(owedClassFocus(plan.level));
    } else {
      c = addFocus(c, choices.classFocus!);
    }
  }

  if (plan.hasTalent) {
    if (choices.talentId == null) {
      owed.add(owedTalent);
    } else {
      c = addTalent(c, choices.talentId!);
    }
  }

  if (plan.hasWeaponGroup) {
    if (choices.weaponGroup == null) {
      owed.add(owedWeaponGroup);
    } else {
      c = addWeaponGroup(c, choices.weaponGroup!);
    }
  }

  final step = plan.data.specialization;
  if (step != null) {
    if (plan.startsSpecialization) {
      if (choices.specializationId == null) {
        owed.add(owedSpecialization(step.slot));
      } else {
        c = addSpecialization(c, choices.specializationId!, step.slot);
      }
    } else {
      c = _raiseSpecialization(c, step);
    }
  }

  final learned = [if (choices.spellId != null) choices.spellId!];

  return c.copyWith(
    spellIds: [...c.spellIds, ...learned],
    owedGains: owed,
    levelUpUndo: LevelUpUndo.before(before, learnedSpellIds: learned),
  );
}

/// Journeyman / Master step of a slot: raises the specialization in that slot
/// (nothing happens when the character has none).
Character _raiseSpecialization(Character character, SpecializationStep step) {
  final degree = degreeNumber(step.degree);
  return character.copyWith(specializations: [
    for (final s in character.specializations)
      s.slot == step.slot && s.degree < degree ? s.withDegree(degree) : s,
  ]);
}

/// Takes back the last level-up (only what it changed, see [LevelUpUndo]).
/// Current health and mana drop to the old maximum if they are above it.
Character undoLevelUp(Character character) {
  final undo = character.levelUpUndo!;
  return character.copyWith(
    level: undo.level,
    abilities: undo.abilities,
    bankedAdvancements: undo.bankedAdvancements,
    focuses: undo.focuses,
    talents: undo.talents,
    specializations: undo.specializations,
    weaponGroups: undo.weaponGroups,
    maxHealth: undo.maxHealth,
    health: min(character.health, undo.maxHealth),
    maxMana: undo.maxMana,
    mana: min(character.mana, undo.maxMana),
    owedGains: undo.owedGains,
    spellIds: [
      for (final id in character.spellIds)
        if (!undo.learnedSpellIds.contains(id)) id,
    ],
    clearLevelUpUndo: true,
  );
}
