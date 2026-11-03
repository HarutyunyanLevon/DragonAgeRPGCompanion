import 'package:json_annotation/json_annotation.dart';

part 'talents.g.dart';

/// assets/rules/talents.json

/// One requirement. Look at [type]; only the fields for that type are set:
///   ability -> [ability] + [min]       focus -> [ability] + [focus]
///   weaponGroup -> [anyOf] (group ids) race -> [anyOf] (race ids)
///   talent -> [talent] + [degree]      story -> [text]
///   focusAnyOf / talentAnyOf -> [options] (any one of them is enough)
///   focusInAbility -> [ability] (any focus of that ability)
@JsonSerializable()
class Requirement {
  const Requirement({
    required this.type,
    this.ability,
    this.min,
    this.focus,
    this.talent,
    this.degree,
    this.race,
    this.text,
    this.anyOf,
    this.options,
  });

  final String type;
  final String? ability;
  final int? min;
  final String? focus;
  final String? talent;
  final String? degree;
  final String? race;
  final String? text;
  final List<String>? anyOf;
  final List<Requirement>? options;

  factory Requirement.fromJson(Map<String, dynamic> json) =>
      _$RequirementFromJson(json);
  Map<String, dynamic> toJson() => _$RequirementToJson(this);
}

@JsonSerializable()
class Degrees {
  const Degrees({
    required this.novice,
    required this.journeyman,
    required this.master,
  });

  final String novice;
  final String journeyman;
  final String master;

  /// [degree] is 1 (novice), 2 (journeyman) or 3 (master).
  String textFor(int degree) => [novice, journeyman, master][degree - 1];

  factory Degrees.fromJson(Map<String, dynamic> json) =>
      _$DegreesFromJson(json);
  Map<String, dynamic> toJson() => _$DegreesToJson(this);
}

@JsonSerializable()
class Talent {
  const Talent({
    required this.id,
    required this.name,
    this.optional = false,
    required this.classes,
    required this.requirements,
    required this.degrees,
    required this.notes,
  });

  final String id;
  final String name;

  @JsonKey(defaultValue: false)
  final bool optional;

  final List<String> classes;
  final List<Requirement> requirements;
  final Degrees degrees;

  @JsonKey(defaultValue: <String>[])
  final List<String> notes;

  factory Talent.fromJson(Map<String, dynamic> json) => _$TalentFromJson(json);
  Map<String, dynamic> toJson() => _$TalentToJson(this);
}

@JsonSerializable()
class TalentsFile {
  const TalentsFile({required this.talents});

  final List<Talent> talents;

  Talent talentById(String id) => talents.firstWhere((t) => t.id == id);

  factory TalentsFile.fromJson(Map<String, dynamic> json) =>
      _$TalentsFileFromJson(json);
  Map<String, dynamic> toJson() => _$TalentsFileToJson(this);
}
