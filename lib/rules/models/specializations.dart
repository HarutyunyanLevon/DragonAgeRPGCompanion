import 'package:json_annotation/json_annotation.dart';

import 'talents.dart';

part 'specializations.g.dart';

/// assets/rules/specializations.json (the Grey Warden part has no model yet).
/// Requirements and degrees have the same shape as talents.

@JsonSerializable()
class Specialization {
  const Specialization({
    required this.id,
    required this.name,
    required this.classId,
    required this.requirements,
    required this.degrees,
    required this.notes,
  });

  final String id; // "arcane-warrior"
  final String name;

  @JsonKey(name: 'class')
  final String classId; // "mage"

  final List<Requirement> requirements;
  final Degrees degrees;

  @JsonKey(defaultValue: <String>[])
  final List<String> notes;

  factory Specialization.fromJson(Map<String, dynamic> json) =>
      _$SpecializationFromJson(json);
  Map<String, dynamic> toJson() => _$SpecializationToJson(this);
}

@JsonSerializable()
class SpecializationsFile {
  const SpecializationsFile({required this.specializations});

  final List<Specialization> specializations;

  Specialization specializationById(String id) =>
      specializations.firstWhere((s) => s.id == id);

  factory SpecializationsFile.fromJson(Map<String, dynamic> json) =>
      _$SpecializationsFileFromJson(json);
  Map<String, dynamic> toJson() => _$SpecializationsFileToJson(this);
}
