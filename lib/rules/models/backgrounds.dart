import 'package:json_annotation/json_annotation.dart';

part 'backgrounds.g.dart';

/// assets/rules/backgrounds.json

/// The races a character can be (race ids used in the rules files).
const playableRaces = ['human', 'elf', 'dwarf', 'qunari'];

@JsonSerializable()
class FocusRef {
  const FocusRef({required this.ability, required this.focus});

  final String ability;
  final String focus;

  factory FocusRef.fromJson(Map<String, dynamic> json) =>
      _$FocusRefFromJson(json);
  Map<String, dynamic> toJson() => _$FocusRefToJson(this);
}

/// What a background table row gives. Look at [type] to know which fields are set:
///   ability -> [ability]      focus -> [ability] + [focus]
///   language -> [language]    weaponGroup -> [group] (+ [ifClassHasGroup])
@JsonSerializable()
class TableResult {
  const TableResult({
    required this.type,
    this.ability,
    this.focus,
    this.language,
    this.group,
    this.ifClassHasGroup,
  });

  final String type;
  final String? ability;
  final String? focus;
  final String? language;
  final String? group;

  /// Take this focus instead when the class already grants the weapon group.
  final FocusRef? ifClassHasGroup;

  factory TableResult.fromJson(Map<String, dynamic> json) =>
      _$TableResultFromJson(json);
  Map<String, dynamic> toJson() => _$TableResultToJson(this);
}

@JsonSerializable()
class BackgroundTableRow {
  const BackgroundTableRow({required this.min, required this.max, required this.result});

  final int min;
  final int max;
  final TableResult result;

  factory BackgroundTableRow.fromJson(Map<String, dynamic> json) =>
      _$BackgroundTableRowFromJson(json);
  Map<String, dynamic> toJson() => _$BackgroundTableRowToJson(this);
}

@JsonSerializable()
class LanguageChoice {
  const LanguageChoice({required this.pick, required this.from});

  final int pick;
  final List<String> from;

  factory LanguageChoice.fromJson(Map<String, dynamic> json) =>
      _$LanguageChoiceFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageChoiceToJson(this);
}

@JsonSerializable()
class Background {
  const Background({
    required this.id,
    required this.name,
    required this.races,
    this.raceChoice = false,
    required this.abilityBonus,
    required this.focusChoices,
    required this.languages,
    this.languageChoice,
    required this.classes,
    this.trait,
    required this.casteChoices,
    required this.tables,
    required this.notes,
    this.homebrew = false,
  });

  final String id;
  final String name;
  final List<String> races;

  /// True when the player picks one of [races] (e.g. Apostate: human or elf).
  @JsonKey(defaultValue: false)
  final bool raceChoice;

  final String abilityBonus;
  final List<FocusRef> focusChoices;
  final List<String> languages;
  final LanguageChoice? languageChoice;
  final List<String> classes;

  /// "magic-resistance" or "magic-susceptibility", if the race has one.
  final String? trait;

  @JsonKey(defaultValue: <String>[])
  final List<String> casteChoices;

  /// 2d6 tables. Key "any", or "elf" / "human" when the background has one each.
  final Map<String, List<BackgroundTableRow>> tables;

  @JsonKey(defaultValue: <String>[])
  final List<String> notes;

  /// True for a background the player made up, false for book backgrounds.
  @JsonKey(defaultValue: false)
  final bool homebrew;

  /// The row that a 2d6 [roll] lands on.
  BackgroundTableRow rowForRoll(String tableKey, int roll) =>
      tables[tableKey]!.firstWhere((r) => roll >= r.min && roll <= r.max);

  /// The 2d6 table a character of [race] uses: the race's own table when the
  /// background has one per race (Apostate), else the shared "any" table.
  List<BackgroundTableRow> tableFor(String race) =>
      tables[race] ?? tables['any']!;

  factory Background.fromJson(Map<String, dynamic> json) =>
      _$BackgroundFromJson(json);
  Map<String, dynamic> toJson() => _$BackgroundToJson(this);
}

@JsonSerializable()
class ScoreRange {
  const ScoreRange({required this.min, required this.max, required this.score});

  final int min;
  final int max;
  final int score;

  factory ScoreRange.fromJson(Map<String, dynamic> json) =>
      _$ScoreRangeFromJson(json);
  Map<String, dynamic> toJson() => _$ScoreRangeToJson(this);
}

/// The "buying" rules (the buyMethod block in backgrounds.json): for the
/// abilities, and for the background benefits that replace the two rolls.
@JsonSerializable()
class BuyMethod {
  const BuyMethod({
    required this.points,
    required this.maxPerAbility,
    required this.backgroundBenefitPoints,
    required this.abilityIncreaseCost,
    required this.otherBenefitCost,
  });

  final int points; // 10 points to spend, +1 each
  final int maxPerAbility; // at most 3 on one ability

  final int backgroundBenefitPoints; // 3 advancements instead of two rolls
  final int abilityIncreaseCost; // 2: a "+1 ability" benefit
  final int otherBenefitCost; // 1: a focus, language or weapon group

  factory BuyMethod.fromJson(Map<String, dynamic> json) =>
      _$BuyMethodFromJson(json);
  Map<String, dynamic> toJson() => _$BuyMethodToJson(this);
}

@JsonSerializable()
class BackgroundsFile {
  const BackgroundsFile({
    required this.abilities,
    required this.abilityScoreTable,
    required this.buyMethod,
    required this.focusBonus,
    required this.backgrounds,
  });

  final List<String> abilities;
  final List<ScoreRange> abilityScoreTable;
  final BuyMethod buyMethod;
  final int focusBonus;
  final List<Background> backgrounds;

  /// Lowest and highest start score the rules allow (-2 and 4).
  int get minScore =>
      abilityScoreTable.map((r) => r.score).reduce((a, b) => a < b ? a : b);
  int get maxScore =>
      abilityScoreTable.map((r) => r.score).reduce((a, b) => a > b ? a : b);

  Background backgroundById(String id) =>
      backgrounds.firstWhere((b) => b.id == id);

  /// Starting ability score for a 3d6 [total] (3 -> -2, 18 -> 4).
  int scoreForRoll(int total) => abilityScoreTable
      .firstWhere((r) => total >= r.min && total <= r.max)
      .score;

  factory BackgroundsFile.fromJson(Map<String, dynamic> json) =>
      _$BackgroundsFileFromJson(json);
  Map<String, dynamic> toJson() => _$BackgroundsFileToJson(this);
}
