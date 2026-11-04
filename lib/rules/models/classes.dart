import 'package:json_annotation/json_annotation.dart';

import 'backgrounds.dart' show FocusRef;

part 'classes.g.dart';

/// assets/rules/classes.json

@JsonSerializable()
class AdvancementCost {
  const AdvancementCost({
    required this.minRating,
    required this.maxRating,
    required this.cost,
  });

  final int minRating;
  final int maxRating;
  final int cost;

  factory AdvancementCost.fromJson(Map<String, dynamic> json) =>
      _$AdvancementCostFromJson(json);
  Map<String, dynamic> toJson() => _$AdvancementCostToJson(this);
}

@JsonSerializable()
class StartingHealth {
  const StartingHealth({
    required this.base,
    required this.dice,
    required this.plus,
  });

  final int base;
  final String dice; // "1d6"
  final String plus; // ability id, "constitution"

  factory StartingHealth.fromJson(Map<String, dynamic> json) =>
      _$StartingHealthFromJson(json);
  Map<String, dynamic> toJson() => _$StartingHealthToJson(this);
}

/// "Take these, plus pick N from this list."
@JsonSerializable()
class PickList {
  const PickList({
    required this.fixed,
    required this.pick,
    required this.pickFrom,
  });

  final List<String> fixed;
  final int pick;
  final List<String> pickFrom;

  factory PickList.fromJson(Map<String, dynamic> json) =>
      _$PickListFromJson(json);
  Map<String, dynamic> toJson() => _$PickListToJson(this);
}

@JsonSerializable()
class ClassPower {
  const ClassPower({required this.name, required this.text});

  final String name;
  final String text;

  factory ClassPower.fromJson(Map<String, dynamic> json) =>
      _$ClassPowerFromJson(json);
  Map<String, dynamic> toJson() => _$ClassPowerToJson(this);
}

/// A specialization step gained at a level, e.g. slot 6, degree "journeyman".
@JsonSerializable()
class SpecializationStep {
  const SpecializationStep({required this.slot, required this.degree});

  final int slot; // 6 or 14: the level the specialization was started at
  final String degree; // novice | journeyman | master

  factory SpecializationStep.fromJson(Map<String, dynamic> json) =>
      _$SpecializationStepFromJson(json);
  Map<String, dynamic> toJson() => _$SpecializationStepToJson(this);
}

@JsonSerializable()
class ClassLevel {
  const ClassLevel({
    required this.level,
    required this.gains,
    required this.focusChoices,
    this.specialization,
    required this.powers,
  });

  final int level;

  /// What the level-up screen has to offer: spell, talent, focus, weaponGroup.
  @JsonKey(defaultValue: <String>[])
  final List<String> gains;

  /// The "focus" gain only: the focuses to pick from (warrior level 2).
  @JsonKey(defaultValue: <FocusRef>[])
  final List<FocusRef> focusChoices;

  final SpecializationStep? specialization;

  @JsonKey(defaultValue: <ClassPower>[])
  final List<ClassPower> powers;

  factory ClassLevel.fromJson(Map<String, dynamic> json) =>
      _$ClassLevelFromJson(json);
  Map<String, dynamic> toJson() => _$ClassLevelToJson(this);
}

/// Mana at level 1: [startBase] + the [plus] ability + 1d6. Only mages have it.
@JsonSerializable()
class StartingMana {
  const StartingMana({required this.startBase, required this.plus});

  final int startBase;
  final String plus; // ability id, "magic"

  factory StartingMana.fromJson(Map<String, dynamic> json) =>
      _$StartingManaFromJson(json);
  Map<String, dynamic> toJson() => _$StartingManaToJson(this);
}

@JsonSerializable()
class ClassRules {
  const ClassRules({
    required this.id,
    required this.name,
    required this.primaryAbilities,
    required this.secondaryAbilities,
    required this.startingHealth,
    this.mana,
    this.startingSpells = 0,
    required this.weaponGroups,
    required this.startingTalents,
    required this.startingEquipment,
    this.startingArmor,
    this.startingWeapons = 0,
    this.startingExtraItem,
    required this.levels,
  });

  final String id;
  final String name;
  final List<String> primaryAbilities;
  final List<String> secondaryAbilities;
  final StartingHealth startingHealth;

  /// Null for classes without mana.
  final StartingMana? mana;

  /// How many spells a level 1 character picks.
  @JsonKey(defaultValue: 0)
  final int startingSpells;

  final PickList weaponGroups;
  final PickList startingTalents;
  final String startingEquipment; // the book's sentence, shown as text

  /// The same sentence as data: armor id ("heavy-leather", null for mages),
  /// how many weapons to pick, and one extra item (a mage's staff).
  final String? startingArmor;
  @JsonKey(defaultValue: 0)
  final int startingWeapons;
  final String? startingExtraItem;

  final List<ClassLevel> levels;

  /// Even levels must raise a primary ability, odd levels a secondary one.
  bool isAdvancementAllowed({required String ability, required int level}) {
    final allowed = level.isEven ? primaryAbilities : secondaryAbilities;
    return allowed.contains(ability);
  }

  ClassLevel levelData(int level) => levels.firstWhere((l) => l.level == level);

  factory ClassRules.fromJson(Map<String, dynamic> json) =>
      _$ClassRulesFromJson(json);
  Map<String, dynamic> toJson() => _$ClassRulesToJson(this);
}

/// Speed = base for the race + Dexterity - armor penalty.
@JsonSerializable()
class SpeedRules {
  const SpeedRules({required this.baseByRace});

  final Map<String, int> baseByRace; // {"human": 10, "dwarf": 8, ...}

  factory SpeedRules.fromJson(Map<String, dynamic> json) =>
      _$SpeedRulesFromJson(json);
  Map<String, dynamic> toJson() => _$SpeedRulesToJson(this);
}

/// Starting money: [base] + [dice] silver, e.g. 50 + 3d6.
@JsonSerializable()
class StartingSilver {
  const StartingSilver({required this.base, required this.dice});

  final int base;
  final String dice; // "3d6"

  factory StartingSilver.fromJson(Map<String, dynamic> json) =>
      _$StartingSilverFromJson(json);
  Map<String, dynamic> toJson() => _$StartingSilverToJson(this);
}

/// What every new character gets (the class-specific part is in ClassRules).
@JsonSerializable()
class StartingGear {
  const StartingGear({required this.everyone, required this.silver});

  final List<String> everyone; // ["backpack", "traveler's garb", ...]
  final StartingSilver silver;

  factory StartingGear.fromJson(Map<String, dynamic> json) =>
      _$StartingGearFromJson(json);
  Map<String, dynamic> toJson() => _$StartingGearToJson(this);
}

@JsonSerializable()
class ClassesFile {
  const ClassesFile({
    required this.xpByLevel,
    required this.advancementCost,
    required this.classes,
    required this.startingGear,
    required this.speed,
  });

  /// Total XP needed to reach level 1, 2, 3, ... (index 0 is level 1).
  final List<int> xpByLevel;
  final List<AdvancementCost> advancementCost;
  final List<ClassRules> classes;
  final StartingGear startingGear;
  final SpeedRules speed;

  ClassRules classById(String id) => classes.firstWhere((c) => c.id == id);

  /// Every weapon group some class mentions, sorted.
  List<String> get allWeaponGroups => {
        for (final c in classes) ...[
          ...c.weaponGroups.fixed,
          ...c.weaponGroups.pickFrom,
        ],
      }.toList()
        ..sort();

  /// Highest level whose XP total is reached.
  int levelForXp(int xp) {
    var level = 1;
    for (var i = 0; i < xpByLevel.length; i++) {
      if (xp >= xpByLevel[i]) level = i + 1;
    }
    return level;
  }

  int xpForLevel(int level) => xpByLevel[level - 1];

  /// Advancements needed to raise an ability TO [newRating].
  int advancementsNeeded(int newRating) {
    return advancementCost
        .firstWhere((c) => newRating >= c.minRating && newRating <= c.maxRating)
        .cost;
  }

  factory ClassesFile.fromJson(Map<String, dynamic> json) =>
      _$ClassesFileFromJson(json);
  Map<String, dynamic> toJson() => _$ClassesFileToJson(this);
}
