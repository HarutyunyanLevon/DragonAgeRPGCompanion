import 'package:json_annotation/json_annotation.dart';

part 'focus_entry.g.dart';

/// One entry of the "focuses" list in assets/rules/core.json.
@JsonSerializable()
class FocusEntry {
  const FocusEntry({
    required this.id,
    required this.ability,
    required this.name,
  });

  final String id; // "arcane-lore"
  final String ability; // "cunning"
  final String name; // "Arcane Lore"

  factory FocusEntry.fromJson(Map<String, dynamic> json) =>
      _$FocusEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FocusEntryToJson(this);
}
