import '../../character/character.dart';
import '../../character/starting_equipment.dart';
import '../../character/equipment.dart';
import '../../rules/rules_data.dart';
import 'character_draft.dart';

/// Final ability scores: step 2 score + the background's +1 + each "+1
/// ability" table result.
Map<String, int> finalAbilities(CharacterDraft draft, RulesData rules) {
  final results = draft.benefits.results(draft.benefitFacts(rules));
  return {
    for (final ability in rules.backgrounds.abilities)
      ability: (draft.abilities.scores[ability] ?? 0) +
          (draft.background!.abilityBonus == ability ? 1 : 0) +
          results.where((r) => r.type == 'ability' && r.ability == ability).length,
  };
}

/// The weapon groups the new character will have: the class's fixed ones,
/// the picks and the background table results.
List<String> finalWeaponGroups(CharacterDraft draft, RulesData rules) {
  final classRules = rules.classes.classById(draft.classId!);
  final results = draft.benefits.results(draft.benefitFacts(rules));
  return {
    ...classRules.weaponGroups.fixed,
    ...draft.classChoices.weaponGroups,
    for (final r in results)
      if (r.type == 'weaponGroup') r.group!,
  }.toList();
}

/// The talent ids the new character will have (all at the first degree).
List<String> finalTalentIds(CharacterDraft draft, RulesData rules) => [
      ...rules.classes.classById(draft.classId!).startingTalents.fixed,
      ...draft.classChoices.talents,
    ];

/// The free starting items for the picks made so far.
List<InventoryItem> draftStartingItems(CharacterDraft draft, RulesData rules) =>
    startingItems(
      classRules: rules.classes.classById(draft.classId!),
      talentIds: finalTalentIds(draft, rules),
      weaponIds: draft.gearChoices.weaponIds,
      rules: rules,
    );

/// Makes the level 1 [Character] from a finished wizard [draft].
/// [healthDie] and [manaDie] are the d6 results (manaDie only matters for
/// classes with mana). A "Proceed anyway" duplicate is only kept once.
Character buildCharacter({
  required CharacterDraft draft,
  required RulesData rules,
  required String id,
  required int healthDie,
  int manaDie = 0,
}) {
  final background = draft.background!;
  final classRules = rules.classes.classById(draft.classId!);
  final benefits = draft.benefits;
  final choices = draft.classChoices;
  final results = benefits.results(draft.benefitFacts(rules));
  final abilities = finalAbilities(draft, rules);
  final gear = draft.gearChoices;

  // Starting items first, then what was bought (not equipped).
  var inventory = draftStartingItems(draft, rules);
  for (final id in gear.bought) {
    final entry = rules.catalogEntry(id);
    inventory = addItem(inventory, InventoryItem(name: entry.name, itemId: id));
  }

  final backgroundFocus = background.focusChoices[benefits.focusIndex!];
  final focuses = {
    (backgroundFocus.ability, backgroundFocus.focus),
    for (final r in results)
      if (r.type == 'focus') (r.ability!, r.focus!),
  };

  final health = classRules.startingHealth;
  final maxHealth = health.base + (abilities[health.plus] ?? 0) + healthDie;
  final mana = classRules.mana;
  final maxMana =
      mana == null ? 0 : mana.startBase + (abilities[mana.plus] ?? 0) + manaDie;

  return Character(
    id: id,
    name: draft.name.trim(),
    backgroundId: background.id,
    race: draft.race!,
    caste: draft.caste,
    classId: classRules.id,
    abilities: abilities,
    bankedAdvancements: const {},
    focuses: [
      for (final (ability, focus) in focuses)
        CharacterFocus(ability: ability, focus: focus),
    ],
    talents: [
      for (final talent in finalTalentIds(draft, rules))
        DegreeEntry(id: talent, degree: 1),
    ],
    specializations: const [],
    spellIds: choices.spells,
    traitIds: [if (background.trait != null) background.trait!],
    weaponGroups: finalWeaponGroups(draft, rules),
    languages: {
      ...background.languages,
      ...benefits.languages,
      for (final r in results)
        if (r.type == 'language') r.language!,
    }.toList(),
    maxHealth: maxHealth,
    health: maxHealth,
    maxMana: maxMana,
    mana: maxMana,
    inventory: inventory,
    copper: gear.leftCopper(rules),
    owedGains: const [],
    goals: const [],
    ties: const [],
    playLayouts: const {},
  );
}
