import 'package:json_annotation/json_annotation.dart';

import '../slug.dart';

part 'spell.g.dart';

/// One thing a spell needs before it can be learned (spells.json "requires").
/// [type] is "spell", "talent" or "specialization" and [id] is that spell /
/// talent / specialization. [degree] (1 Novice, 2 Journeyman, 3 Master) is
/// only used for talents and specializations.
@JsonSerializable()
class SpellRequirement {
  const SpellRequirement({
    required this.type,
    required this.id,
    this.degree = 1,
  });

  final String type;
  final String id;

  @JsonKey(defaultValue: 1)
  final int degree;

  factory SpellRequirement.fromJson(Map<String, dynamic> json) =>
      _$SpellRequirementFromJson(json);
  Map<String, dynamic> toJson() => _$SpellRequirementToJson(this);
}

/// One entry of assets/rules/spells.json (a plain list of spells), or a
/// homebrew spell of the player (custom_spells.json, same shape).
@JsonSerializable()
class Spell {
  const Spell({
    required this.name,
    required this.school,
    required this.type,
    required this.mana,
    required this.castTime,
    required this.tn,
    required this.test,
    required this.requirement,
    required this.requires,
    required this.description,
    this.sourcePagePdf = 0,
    this.homebrew = false,
  });

  final String name;
  final String school;
  final String type;
  final String mana; // text on purpose: "7 MP", "3-9 MP", "20+ MP"
  final String castTime;
  final String tn;
  final String test;

  /// The requirement as the book prints it ("None", "" or text), for display.
  final String requirement;

  /// The same requirement as data, for checking. Empty: nothing is needed.
  @JsonKey(defaultValue: <SpellRequirement>[])
  final List<SpellRequirement> requires;

  final String description;

  @JsonKey(name: 'source_page_pdf', defaultValue: 0)
  final int sourcePagePdf;

  /// True for a spell the player made up.
  @JsonKey(defaultValue: false)
  final bool homebrew;

  /// Same id style as the other rules files ("winters-grasp").
  String get id => slug(name);

  /// A level 1 mage may only start with spells that need nothing else.
  bool get hasNoRequirement => requires.isEmpty;

  factory Spell.fromJson(Map<String, dynamic> json) => _$SpellFromJson(json);
  Map<String, dynamic> toJson() => _$SpellToJson(this);
}

/// A suggested set of starting spells (assets/rules/starter_spells.json).
@JsonSerializable()
class StarterSpellSet {
  const StarterSpellSet({required this.name, required this.spells});

  final String name; // "Balanced"
  final List<String> spells; // spell ids

  factory StarterSpellSet.fromJson(Map<String, dynamic> json) =>
      _$StarterSpellSetFromJson(json);
  Map<String, dynamic> toJson() => _$StarterSpellSetToJson(this);
}
