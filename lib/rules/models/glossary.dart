import 'package:json_annotation/json_annotation.dart';

import '../slug.dart';

part 'glossary.g.dart';

/// One rulebook term of assets/rules/glossary.json (a plain list).
/// [topic] groups the terms in the Glossary tab ("Combat", "Magic"...).
///
/// Optional fields:
///  - [aliases]: other words that link to this term ("TN" for "Target Number").
///  - [autoLink]: false for everyday words ("Move", "Run") that should not turn
///    into a link wherever they appear. The term is still searchable.
///  - [extra]: a table or list built from game data and shown under the text
///    (see glossary_extras.dart for the allowed names).
@JsonSerializable()
class GlossaryTerm {
  const GlossaryTerm({
    required this.topic,
    required this.name,
    required this.text,
    required this.aliases,
    this.autoLink = true,
    this.extra,
  });

  final String topic;
  final String name;
  final String text;

  @JsonKey(defaultValue: <String>[])
  final List<String> aliases;

  @JsonKey(defaultValue: true)
  final bool autoLink;

  final String? extra;

  /// Same id style as the other rules files ("dragon-die").
  String get id => slug(name);

  /// The words in a text that link to this term. A name with brackets
  /// ("Heal (action)") is never written like that in a text, so only its
  /// aliases count.
  List<String> get linkNames =>
      [if (!name.contains('(')) name, ...aliases];

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) =>
      _$GlossaryTermFromJson(json);
  Map<String, dynamic> toJson() => _$GlossaryTermToJson(this);
}

/// A note the player wrote (house rule, table ruling...). Kept in the shared
/// library file glossary_notes.json, the same for every character.
@JsonSerializable()
class GlossaryNote {
  const GlossaryNote({
    required this.id,
    required this.title,
    required this.text,
  });

  final String id; // time of creation in ms, so a title can change
  final String title;
  final String text;

  GlossaryNote copyWith({String? title, String? text}) =>
      GlossaryNote(id: id, title: title ?? this.title, text: text ?? this.text);

  factory GlossaryNote.fromJson(Map<String, dynamic> json) =>
      _$GlossaryNoteFromJson(json);
  Map<String, dynamic> toJson() => _$GlossaryNoteToJson(this);
}
