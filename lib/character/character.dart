import 'package:json_annotation/json_annotation.dart';

part 'character.g.dart';

/// A player character, saved as one JSON file. Everything about the
/// character lives in here (lore graph and widget layouts will be added
/// as new optional fields later).
///
/// Rules are referenced by id ("rogue", "light-blades"), never copied.

@JsonSerializable()
class CharacterFocus {
  const CharacterFocus({
    required this.ability,
    required this.focus,
    this.doubled = false,
  });

  final String ability; // "cunning"
  final String focus; // "arcane-lore"

  /// Taken twice (level 11+): bonus +3 instead of +2.
  @JsonKey(defaultValue: false)
  final bool doubled;

  int get bonus => doubled ? 3 : 2;

  factory CharacterFocus.fromJson(Map<String, dynamic> json) =>
      _$CharacterFocusFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterFocusToJson(this);
}

/// A talent or specialization with the degree reached.
@JsonSerializable()
class DegreeEntry {
  const DegreeEntry({required this.id, required this.degree, this.slot});

  final String id; // talent id or specialization id
  final int degree; // 1 novice, 2 journeyman, 3 master

  /// Specializations only: the level (6 or 14) of the class slot it fills.
  /// The class table raises its degree at the later levels of that slot.
  final int? slot;

  DegreeEntry withDegree(int newDegree) =>
      DegreeEntry(id: id, degree: newDegree, slot: slot);

  factory DegreeEntry.fromJson(Map<String, dynamic> json) =>
      _$DegreeEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DegreeEntryToJson(this);
}

@JsonSerializable()
class InventoryItem {
  const InventoryItem({
    required this.name,
    this.itemId,
    this.quantity = 1,
    this.note = '',
    this.equipped = false,
  });

  final String name;

  /// Id in gear.json (armor, shield, weapon, gear...), or null for a custom item.
  final String? itemId;

  @JsonKey(defaultValue: 1)
  final int quantity;

  @JsonKey(defaultValue: '')
  final String note;

  /// Worn armor, carried shield or wielded weapon.
  @JsonKey(defaultValue: false)
  final bool equipped;

  InventoryItem copyWith({int? quantity, bool? equipped}) => InventoryItem(
        name: name,
        itemId: itemId,
        quantity: quantity ?? this.quantity,
        note: note,
        equipped: equipped ?? this.equipped,
      );

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);
}

/// What the last level-up changed, so it can be undone. Only the fields a
/// level-up touches are kept: money, items and current health / mana are not.
@JsonSerializable()
class LevelUpUndo {
  const LevelUpUndo({
    required this.level,
    required this.abilities,
    required this.bankedAdvancements,
    required this.focuses,
    required this.talents,
    required this.specializations,
    required this.weaponGroups,
    required this.maxHealth,
    required this.maxMana,
    required this.owedGains,
    required this.learnedSpellIds,
  });

  /// The character as it was before the level-up.
  factory LevelUpUndo.before(Character before, {required List<String> learnedSpellIds}) =>
      LevelUpUndo(
        level: before.level,
        abilities: before.abilities,
        bankedAdvancements: before.bankedAdvancements,
        focuses: before.focuses,
        talents: before.talents,
        specializations: before.specializations,
        weaponGroups: before.weaponGroups,
        maxHealth: before.maxHealth,
        maxMana: before.maxMana,
        owedGains: before.owedGains,
        learnedSpellIds: learnedSpellIds,
      );

  final int level;
  final Map<String, int> abilities;

  @JsonKey(defaultValue: <String, int>{})
  final Map<String, int> bankedAdvancements;

  @JsonKey(defaultValue: <CharacterFocus>[])
  final List<CharacterFocus> focuses;

  @JsonKey(defaultValue: <DegreeEntry>[])
  final List<DegreeEntry> talents;

  @JsonKey(defaultValue: <DegreeEntry>[])
  final List<DegreeEntry> specializations;

  @JsonKey(defaultValue: <String>[])
  final List<String> weaponGroups;

  final int maxHealth;
  final int maxMana;

  @JsonKey(defaultValue: <String>[])
  final List<String> owedGains;

  /// Spells the level-up itself taught (Undo forgets only these).
  @JsonKey(defaultValue: <String>[])
  final List<String> learnedSpellIds;

  factory LevelUpUndo.fromJson(Map<String, dynamic> json) =>
      _$LevelUpUndoFromJson(json);
  Map<String, dynamic> toJson() => _$LevelUpUndoToJson(this);
}

@JsonSerializable()
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.backgroundId,
    required this.race,
    this.caste,
    required this.classId,
    this.level = 1,
    this.xp = 0,
    required this.abilities,
    required this.bankedAdvancements,
    required this.focuses,
    required this.talents,
    required this.specializations,
    required this.spellIds,
    required this.traitIds,
    required this.weaponGroups,
    required this.languages,
    required this.maxHealth,
    required this.health,
    this.maxMana = 0,
    this.mana = 0,
    this.copper = 0,
    required this.inventory,
    required this.owedGains,
    this.levelUpUndo,
    required this.goals,
    required this.ties,
  });

  final String id;
  final String name;
  final String backgroundId;
  final String race; // "human", "elf", "dwarf", "qunari"
  final String? caste; // dwarves only: "artisan", "miner", ...
  final String classId; // "mage", "rogue", "warrior"

  @JsonKey(defaultValue: 1)
  final int level;
  @JsonKey(defaultValue: 0)
  final int xp;

  /// Ability id -> current rating, e.g. {"strength": 2, ...}.
  final Map<String, int> abilities;

  /// Ability id -> advancements paid toward the next rating (costs 2-3 above 5).
  @JsonKey(defaultValue: <String, int>{})
  final Map<String, int> bankedAdvancements;

  @JsonKey(defaultValue: <CharacterFocus>[])
  final List<CharacterFocus> focuses;

  @JsonKey(defaultValue: <DegreeEntry>[])
  final List<DegreeEntry> talents;

  @JsonKey(defaultValue: <DegreeEntry>[])
  final List<DegreeEntry> specializations;

  /// Spell ids (see Spell.id). Custom homebrew spells will get their own list later.
  @JsonKey(defaultValue: <String>[])
  final List<String> spellIds;

  /// Racial trait ids (see BackgroundsFile.racialTraits). Filled when the
  /// character is created; older saves have none.
  @JsonKey(defaultValue: <String>[])
  final List<String> traitIds;

  @JsonKey(defaultValue: <String>[])
  final List<String> weaponGroups;

  @JsonKey(defaultValue: <String>[])
  final List<String> languages;

  // Rolled during creation and level-ups, so they are stored, not derived.
  final int maxHealth;
  final int health;
  @JsonKey(defaultValue: 0)
  final int maxMana;
  @JsonKey(defaultValue: 0)
  final int mana;

  /// Money in copper (1 sp = 100 cp, 1 gp = 10,000 cp).
  @JsonKey(defaultValue: 0)
  final int copper;

  @JsonKey(defaultValue: <InventoryItem>[])
  final List<InventoryItem> inventory;

  /// Gains skipped at level-up ("talent", "focus:primary", ...), taken later
  /// from the Sheet. The ids are listed in character/level_up.dart.
  @JsonKey(defaultValue: <String>[])
  final List<String> owedGains;

  /// Set by the last level-up; null when there is nothing to undo.
  final LevelUpUndo? levelUpUndo;

  @JsonKey(defaultValue: <String>[])
  final List<String> goals;

  @JsonKey(defaultValue: <String>[])
  final List<String> ties;

  int ability(String abilityId) => abilities[abilityId] ?? 0;

  /// A copy with something changed. Add more parameters when another screen
  /// needs to change something else. [clearLevelUpUndo] drops the undo data
  /// (passing null would mean "keep it").
  Character copyWith({
    int? level,
    int? xp,
    Map<String, int>? abilities,
    Map<String, int>? bankedAdvancements,
    List<CharacterFocus>? focuses,
    List<DegreeEntry>? talents,
    List<DegreeEntry>? specializations,
    List<String>? spellIds,
    List<String>? weaponGroups,
    int? maxHealth,
    int? health,
    int? maxMana,
    int? mana,
    int? copper,
    List<InventoryItem>? inventory,
    List<String>? owedGains,
    LevelUpUndo? levelUpUndo,
    bool clearLevelUpUndo = false,
  }) =>
      Character(
        id: id,
        name: name,
        backgroundId: backgroundId,
        race: race,
        caste: caste,
        classId: classId,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        abilities: abilities ?? this.abilities,
        bankedAdvancements: bankedAdvancements ?? this.bankedAdvancements,
        focuses: focuses ?? this.focuses,
        talents: talents ?? this.talents,
        specializations: specializations ?? this.specializations,
        spellIds: spellIds ?? this.spellIds,
        traitIds: traitIds,
        weaponGroups: weaponGroups ?? this.weaponGroups,
        languages: languages,
        maxHealth: maxHealth ?? this.maxHealth,
        health: health ?? this.health,
        maxMana: maxMana ?? this.maxMana,
        mana: mana ?? this.mana,
        copper: copper ?? this.copper,
        inventory: inventory ?? this.inventory,
        owedGains: owedGains ?? this.owedGains,
        levelUpUndo:
            clearLevelUpUndo ? null : (levelUpUndo ?? this.levelUpUndo),
        goals: goals,
        ties: ties,
      );

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterToJson(this);
}
