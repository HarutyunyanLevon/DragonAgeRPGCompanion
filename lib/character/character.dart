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
  const DegreeEntry({required this.id, required this.degree});

  final String id; // talent id or specialization id
  final int degree; // 1 novice, 2 journeyman, 3 master

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
  });

  final String name;

  /// Id in gear.json / weapons, or null for a custom item.
  final String? itemId;

  @JsonKey(defaultValue: 1)
  final int quantity;

  @JsonKey(defaultValue: '')
  final String note;

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);
}

@JsonSerializable()
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.backgroundId,
    required this.race,
    required this.classId,
    this.level = 1,
    this.xp = 0,
    required this.abilities,
    this.bankedAdvancements = const {},
    this.focuses = const [],
    this.talents = const [],
    this.specializations = const [],
    this.spellIds = const [],
    this.weaponGroups = const [],
    this.languages = const [],
    required this.maxHealth,
    required this.health,
    this.maxMana = 0,
    this.mana = 0,
    this.copper = 0,
    this.inventory = const [],
    this.goals = const [],
    this.ties = const [],
  });

  final String id;
  final String name;
  final String backgroundId;
  final String race; // "human", "elf", "dwarf", "qunari"
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

  @JsonKey(defaultValue: <String>[])
  final List<String> goals;

  @JsonKey(defaultValue: <String>[])
  final List<String> ties;

  int ability(String abilityId) => abilities[abilityId] ?? 0;

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterToJson(this);
}
