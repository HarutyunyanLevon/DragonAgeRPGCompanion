import 'package:json_annotation/json_annotation.dart';

import '../slug.dart';

part 'spell.g.dart';

/// One entry of assets/rules/spells.json (a plain list of spells).
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
    required this.description,
    required this.sourcePagePdf,
  });

  final String name;
  final String school;
  final String type;
  final String mana; // text on purpose: "7 MP", "3-9 MP", "20+ MP"
  final String castTime;
  final String tn;
  final String test;
  final String requirement; // "None", "" or free text
  final String description;

  @JsonKey(name: 'source_page_pdf')
  final int sourcePagePdf;

  /// Same id style as the other rules files ("winters-grasp").
  String get id => slug(name);

  factory Spell.fromJson(Map<String, dynamic> json) => _$SpellFromJson(json);
  Map<String, dynamic> toJson() => _$SpellToJson(this);
}
