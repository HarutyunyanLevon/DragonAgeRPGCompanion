import 'package:json_annotation/json_annotation.dart';

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
    this.gains = const [],
    this.specialization,
    this.powers = const [],
  });

  final int level;

  /// What the level-up screen has to offer: spell, talent, focus, weaponGroup.
  @JsonKey(defaultValue: <String>[])
  final List<String> gains;

  final SpecializationStep? specialization;

  @JsonKey(defaultValue: <ClassPower>[])
  final List<ClassPower> powers;

  factory ClassLevel.fromJson(Map<String, dynamic> json) =>
      _$ClassLevelFromJson(json);
  Map<String, dynamic> toJson() => _$ClassLevelToJson(this);
}

@JsonSerializable()
class ClassRules {
  const ClassRules({
    required this.id,
    required this.name,
    required this.primaryAbilities,
    required this.secondaryAbilities,
    required this.startingHealth,
    required this.weaponGroups,
    required this.startingTalents,
    required this.startingEquipment,
    required this.levels,
  });

  final String id;
  final String name;
  final List<String> primaryAbilities;
  final List<String> secondaryAbilities;
  final StartingHealth startingHealth;
  final PickList weaponGroups;
  final PickList startingTalents;
  final String startingEquipment;
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

@JsonSerializable()
class ClassesFile {
  const ClassesFile({
    required this.xpByLevel,
    required this.advancementCost,
    required this.classes,
  });

  /// Total XP needed to reach level 1, 2, 3, ... (index 0 is level 1).
  final List<int> xpByLevel;
  final List<AdvancementCost> advancementCost;
  final List<ClassRules> classes;

  ClassRules classById(String id) => classes.firstWhere((c) => c.id == id);

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
