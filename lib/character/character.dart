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

/// Where one Play widget sits on the grid of one device class: its cell
/// (column [x], row [y]) and its size in cells. [widget] is a
/// [PlayWidgetData.id].
@JsonSerializable()
class PlayTile {
  const PlayTile({
    required this.widget,
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
  });

  final String widget;

  @JsonKey(defaultValue: 0)
  final int x;
  @JsonKey(defaultValue: 0)
  final int y;
  final int width;
  final int height;

  PlayTile copyWith({int? x, int? y, int? width, int? height}) => PlayTile(
        widget: widget,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  factory PlayTile.fromJson(Map<String, dynamic> json) =>
      _$PlayTileFromJson(json);
  Map<String, dynamic> toJson() => _$PlayTileToJson(this);
}

/// One thing in a Play widget. [type] says what it is and which of the other
/// fields it uses:
/// - a reference to the character: "ability" (ref = ability id), "focus"
///   (ref = "ability/focus"), "weapon" (ref = gear id), "spell" (spell id),
///   "stat" (see play_items.dart), "talent", "specialization", "language",
///   "trait", "gear" (ref = gear id);
/// - free items: "text" (name, text), "checkbox" (name, checked), "counter"
///   (name, value), "resource" (name, value = current, max), "roll" (name, value = bonus, damage = dice such as "1d6+2").
/// In a default widget template a [ref] of "*" means "all of this type".
@JsonSerializable()
class PlayItem {
  const PlayItem({
    required this.type,
    this.ref = '',
    this.name = '',
    this.text = '',
    this.value = 0,
    this.checked = false,
    this.damage = '',
    this.max = 0,
  });

  final String type;

  @JsonKey(defaultValue: '')
  final String ref;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String text;
  @JsonKey(defaultValue: 0)
  final int value;
  @JsonKey(defaultValue: false)
  final bool checked;
  @JsonKey(defaultValue: '')
  final String damage;

  /// "resource" only: the most it can hold (value is 0..max).
  @JsonKey(defaultValue: 0)
  final int max;

  PlayItem copyWith({int? value, bool? checked}) => PlayItem(
        type: type,
        ref: ref,
        name: name,
        text: text,
        value: value ?? this.value,
        checked: checked ?? this.checked,
        damage: damage,
        max: max,
      );

  factory PlayItem.fromJson(Map<String, dynamic> json) =>
      _$PlayItemFromJson(json);
  Map<String, dynamic> toJson() => _$PlayItemToJson(this);
}

/// One widget of the Play tab: a titled box of items. The same widgets show
/// on every device class; only their place and size differ ([PlayTile]).
@JsonSerializable()
class PlayWidgetData {
  const PlayWidgetData({
    required this.id,
    required this.title,
    this.style = 'list',
    required this.items,
  });

  final String id;
  final String title;

  /// "list" (one row per item) or "tiles" (small boxes side by side).
  @JsonKey(defaultValue: 'list')
  final String style;

  @JsonKey(defaultValue: <PlayItem>[])
  final List<PlayItem> items;

  PlayWidgetData copyWith({String? title, String? style, List<PlayItem>? items}) =>
      PlayWidgetData(
        id: id,
        title: title ?? this.title,
        style: style ?? this.style,
        items: items ?? this.items,
      );

  factory PlayWidgetData.fromJson(Map<String, dynamic> json) =>
      _$PlayWidgetDataFromJson(json);
  Map<String, dynamic> toJson() => _$PlayWidgetDataToJson(this);
}

/// A saved Play layout: a named copy of all widgets (with items) and of
/// their places on every device class.
@JsonSerializable()
class PlayPreset {
  const PlayPreset({
    required this.name,
    required this.widgets,
    required this.layouts,
  });

  final String name;

  @JsonKey(defaultValue: <PlayWidgetData>[])
  final List<PlayWidgetData> widgets;

  @JsonKey(defaultValue: <String, List<PlayTile>>{})
  final Map<String, List<PlayTile>> layouts;

  PlayPreset copyWith({String? name}) =>
      PlayPreset(name: name ?? this.name, widgets: widgets, layouts: layouts);

  factory PlayPreset.fromJson(Map<String, dynamic> json) =>
      _$PlayPresetFromJson(json);
  Map<String, dynamic> toJson() => _$PlayPresetToJson(this);
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
    required this.playLayouts,
    this.playWidgets,
    this.playPresets,
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

  /// Where the Play widgets sit, per device class ("phone", "tablet",
  /// "desktop"). A widget without a place on a device gets the default place
  /// or goes below the others.
  @JsonKey(defaultValue: <String, List<PlayTile>>{})
  final Map<String, List<PlayTile>> playLayouts;

  /// The Play widgets and their items. Null until the Play tab first fills
  /// them from the default templates.
  final List<PlayWidgetData>? playWidgets;

  /// Saved layouts (null = none).
  final List<PlayPreset>? playPresets;

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
    Map<String, List<PlayTile>>? playLayouts,
    List<PlayWidgetData>? playWidgets,
    List<PlayPreset>? playPresets,
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
        playLayouts: playLayouts ?? this.playLayouts,
        playWidgets: playWidgets ?? this.playWidgets,
        playPresets: playPresets ?? this.playPresets,
      );

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterToJson(this);
}
