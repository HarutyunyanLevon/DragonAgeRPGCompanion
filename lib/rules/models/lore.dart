import 'package:json_annotation/json_annotation.dart';

part 'lore.g.dart';

/// A tag of lore entries ("character", "place", ...). The six book tags are
/// in lore.json; the player can add more (stored in the character).
@JsonSerializable()
class LoreTag {
  const LoreTag({required this.id, required this.name});

  final String id;
  final String name;

  factory LoreTag.fromJson(Map<String, dynamic> json) =>
      _$LoreTagFromJson(json);
  Map<String, dynamic> toJson() => _$LoreTagToJson(this);
}

/// One book entry of lore.json. [links] are the entries the book text
/// mentions (the "weak links"). lore.json also has `source_page_pdf`, which
/// the app does not use.
@JsonSerializable()
class LoreEntry {
  const LoreEntry({
    required this.id,
    required this.name,
    required this.tags,
    required this.section,
    required this.summary,
    required this.links,
  });

  final String id;
  final String name;

  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  final String section;
  final String summary;

  @JsonKey(defaultValue: <String>[])
  final List<String> links;

  factory LoreEntry.fromJson(Map<String, dynamic> json) =>
      _$LoreEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LoreEntryToJson(this);
}

/// The whole lore.json.
@JsonSerializable()
class LoreFile {
  const LoreFile({required this.tags, required this.entries});

  @JsonKey(defaultValue: <LoreTag>[])
  final List<LoreTag> tags;

  @JsonKey(defaultValue: <LoreEntry>[])
  final List<LoreEntry> entries;

  factory LoreFile.fromJson(Map<String, dynamic> json) =>
      _$LoreFileFromJson(json);
  Map<String, dynamic> toJson() => _$LoreFileToJson(this);
}
