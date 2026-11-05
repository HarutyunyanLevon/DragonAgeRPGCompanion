import 'dart:ui' show Rect;

import 'package:json_annotation/json_annotation.dart';

import '../rules/models/lore.dart';
import 'character.dart';

part 'lore_data.g.dart';

/// An entry the player wrote. Looks like a book entry ([LoreEntry]) but
/// lives in the character.
@JsonSerializable()
class MyLoreEntry {
  const MyLoreEntry({
    required this.id,
    required this.name,
    required this.tags,
    required this.text,
    required this.links,
  });

  final String id;
  final String name;

  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  @JsonKey(defaultValue: '')
  final String text;

  /// Ids of the entries this one points to (book or own).
  @JsonKey(defaultValue: <String>[])
  final List<String> links;

  factory MyLoreEntry.fromJson(Map<String, dynamic> json) =>
      _$MyLoreEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MyLoreEntryToJson(this);
}

/// What the player added to a book entry (its text stays read-only): extra
/// tags, extra links and a private note.
@JsonSerializable()
class LoreAddition {
  const LoreAddition({
    required this.entryId,
    required this.tags,
    required this.links,
    this.note = '',
  });

  final String entryId;

  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  @JsonKey(defaultValue: <String>[])
  final List<String> links;

  @JsonKey(defaultValue: '')
  final String note;

  bool get isEmpty => tags.isEmpty && links.isEmpty && note.trim().isEmpty;

  factory LoreAddition.fromJson(Map<String, dynamic> json) =>
      _$LoreAdditionFromJson(json);
  Map<String, dynamic> toJson() => _$LoreAdditionToJson(this);
}

/// An entry pinned on the graph, as a tile: a box with the entry's name and
/// free items (text, checkbox, counter...), like a Play widget. ([x], [y]) is
/// the top-left corner on the (endless) graph; negative values are fine.
@JsonSerializable()
class GraphNode {
  const GraphNode({
    required this.entryId,
    required this.x,
    required this.y,
    this.width = defaultTileWidth,
    this.height = defaultTileHeight,
    this.style = 'list',
    this.items = const [],
  });

  static const defaultTileWidth = 220.0;
  static const defaultTileHeight = 170.0;

  final String entryId;
  final double x;
  final double y;

  @JsonKey(defaultValue: defaultTileWidth)
  final double width;

  @JsonKey(defaultValue: defaultTileHeight)
  final double height;

  /// "list" or "tiles", like a Play widget.
  @JsonKey(defaultValue: 'list')
  final String style;

  @JsonKey(defaultValue: <PlayItem>[])
  final List<PlayItem> items;

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  GraphNode copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? style,
    List<PlayItem>? items,
  }) =>
      GraphNode(
        entryId: entryId,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        style: style ?? this.style,
        items: items ?? this.items,
      );

  factory GraphNode.fromJson(Map<String, dynamic> json) =>
      _$GraphNodeFromJson(json);
  Map<String, dynamic> toJson() => _$GraphNodeToJson(this);
}

/// A strong link: a string the player drew between two nodes. Undirected.
@JsonSerializable()
class GraphString {
  const GraphString({
    required this.id,
    required this.from,
    required this.to,
    this.label = '',
  });

  final String id;
  final String from; // entry id
  final String to; // entry id

  @JsonKey(defaultValue: '')
  final String label;

  GraphString copyWith({String? label}) =>
      GraphString(id: id, from: from, to: to, label: label ?? this.label);

  factory GraphString.fromJson(Map<String, dynamic> json) =>
      _$GraphStringFromJson(json);
  Map<String, dynamic> toJson() => _$GraphStringToJson(this);
}

/// Everything the Lore tab keeps for one character: own entries, additions to
/// book entries, own tags and tag colors, and the graph. Stored inside the
/// character, so exporting a character carries its lore.
///
/// Immutable. The functions that change it are in `lore.dart`.
@JsonSerializable()
class LoreData {
  const LoreData({
    required this.myEntries,
    required this.additions,
    required this.myTags,
    required this.tagColors,
    required this.palette,
    required this.nodes,
    required this.strings,
  });

  /// No lore yet.
  const LoreData.empty()
      : myEntries = const [],
        additions = const [],
        myTags = const [],
        tagColors = const {},
        palette = const [],
        nodes = const [],
        strings = const [];

  @JsonKey(defaultValue: <MyLoreEntry>[])
  final List<MyLoreEntry> myEntries;

  @JsonKey(defaultValue: <LoreAddition>[])
  final List<LoreAddition> additions;

  /// Tags the player made (the book tags are in lore.json).
  @JsonKey(defaultValue: <LoreTag>[])
  final List<LoreTag> myTags;

  /// Tag id -> color (ARGB number). A tag without one gets a default color.
  @JsonKey(defaultValue: <String, int>{})
  final Map<String, int> tagColors;

  /// Colors the player added to the picker (ARGB numbers).
  @JsonKey(defaultValue: <int>[])
  final List<int> palette;

  @JsonKey(defaultValue: <GraphNode>[])
  final List<GraphNode> nodes;

  @JsonKey(defaultValue: <GraphString>[])
  final List<GraphString> strings;

  LoreData copyWith({
    List<MyLoreEntry>? myEntries,
    List<LoreAddition>? additions,
    List<LoreTag>? myTags,
    Map<String, int>? tagColors,
    List<int>? palette,
    List<GraphNode>? nodes,
    List<GraphString>? strings,
  }) =>
      LoreData(
        myEntries: myEntries ?? this.myEntries,
        additions: additions ?? this.additions,
        myTags: myTags ?? this.myTags,
        tagColors: tagColors ?? this.tagColors,
        palette: palette ?? this.palette,
        nodes: nodes ?? this.nodes,
        strings: strings ?? this.strings,
      );

  factory LoreData.fromJson(Map<String, dynamic> json) =>
      _$LoreDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoreDataToJson(this);
}
