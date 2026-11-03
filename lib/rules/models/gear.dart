import 'package:json_annotation/json_annotation.dart';

part 'gear.g.dart';

/// Parts of assets/rules/gear.json: weapon groups, weapons, armor, shields,
/// and a flat [CatalogEntry] list of everything that can be bought (used by
/// the "Add item" sheet).

@JsonSerializable()
class WeaponGroup {
  const WeaponGroup({
    required this.id,
    required this.attackAbility,
    required this.damageAbility,
  });

  final String id; // "axes"
  final String attackAbility; // "strength"
  final String damageAbility; // "strength", bows: "perception"

  factory WeaponGroup.fromJson(Map<String, dynamic> json) =>
      _$WeaponGroupFromJson(json);
  Map<String, dynamic> toJson() => _$WeaponGroupToJson(this);
}

/// Missile weapons: distances in yards and the action that reloads.
@JsonSerializable()
class WeaponRange {
  const WeaponRange({
    required this.short,
    required this.long,
    required this.reload,
  });

  final int short;
  final int long; // attacks beyond short range are at -2
  final String reload; // "minor" or "major"

  factory WeaponRange.fromJson(Map<String, dynamic> json) =>
      _$WeaponRangeFromJson(json);
  Map<String, dynamic> toJson() => _$WeaponRangeToJson(this);
}

@JsonSerializable()
class Weapon {
  const Weapon({
    required this.id,
    required this.name,
    required this.group,
    required this.damage,
    this.minStrength = 0,
    this.costCp = 0,
    this.twoHanded = false,
    this.range,
  });

  final String id;
  final String name;
  final String group; // WeaponGroup.id
  final String damage; // "2d6", "1d6+2"

  /// Strength needed to use the weapon without a damage penalty.
  @JsonKey(defaultValue: 0)
  final int minStrength;

  @JsonKey(defaultValue: 0)
  final int costCp;

  @JsonKey(defaultValue: false)
  final bool twoHanded;

  /// Only missile weapons have a range.
  final WeaponRange? range;

  factory Weapon.fromJson(Map<String, dynamic> json) => _$WeaponFromJson(json);
  Map<String, dynamic> toJson() => _$WeaponToJson(this);
}

@JsonSerializable()
class Armor {
  const Armor({
    required this.id,
    required this.name,
    required this.armorRating,
    required this.armorPenalty,
    required this.costCp,
    this.note,
  });

  final String id; // "heavy-leather"
  final String name;
  final int armorRating;

  /// Subtracted from Speed (and from Dexterity without Armor Training).
  final int armorPenalty;
  final int costCp;
  final String? note;

  factory Armor.fromJson(Map<String, dynamic> json) => _$ArmorFromJson(json);
  Map<String, dynamic> toJson() => _$ArmorToJson(this);
}

@JsonSerializable()
class Shield {
  const Shield({
    required this.id,
    required this.name,
    required this.defenseBonus,
    required this.costCp,
  });

  final String id; // "medium-shield"
  final String name;
  final int defenseBonus;
  final int costCp;

  factory Shield.fromJson(Map<String, dynamic> json) => _$ShieldFromJson(json);
  Map<String, dynamic> toJson() => _$ShieldToJson(this);
}

/// One buyable thing, whatever its kind. [category] is "armor", "shields",
/// "weapons", "ammunition" or a key of the "gear" section ("traveling", ...).
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.costCp,
    this.note,
  });

  final String id;
  final String name;
  final String category;
  final int costCp;
  final String? note;
}

/// The whole gear.json, read by hand (the file mixes several shapes).
class GearFile {
  const GearFile({
    required this.weaponGroups,
    required this.weapons,
    required this.armor,
    required this.shields,
    required this.catalog,
  });

  final List<WeaponGroup> weaponGroups;
  final List<Weapon> weapons;
  final List<Armor> armor;
  final List<Shield> shields;
  final List<CatalogEntry> catalog;

  factory GearFile.fromJson(Map<String, dynamic> json) {
    List<T> read<T>(String key, T Function(Map<String, dynamic>) parse) => [
          for (final entry in json[key] as List<dynamic>)
            parse(entry as Map<String, dynamic>)
        ];

    CatalogEntry catalogItem(Map<String, dynamic> item, String category) =>
        CatalogEntry(
          id: item['id'] as String,
          name: item['name'] as String,
          category: category,
          costCp: (item['costCp'] as num?)?.toInt() ?? 0,
          note: item['note'] as String?,
        );

    final armor = read('armor', Armor.fromJson);
    final shields = read('shields', Shield.fromJson);
    final weapons = read('weapons', Weapon.fromJson);
    final gear = json['gear'] as Map<String, dynamic>;

    return GearFile(
      weaponGroups: read('weaponGroups', WeaponGroup.fromJson),
      weapons: weapons,
      armor: armor,
      shields: shields,
      catalog: [
        for (final a in armor)
          CatalogEntry(
              id: a.id,
              name: a.name,
              category: 'armor',
              costCp: a.costCp,
              note: a.note),
        for (final s in shields)
          CatalogEntry(
              id: s.id, name: s.name, category: 'shields', costCp: s.costCp),
        for (final w in weapons)
          CatalogEntry(
              id: w.id, name: w.name, category: 'weapons', costCp: w.costCp),
        ...read('ammunition', (item) => catalogItem(item, 'ammunition')),
        for (final group in gear.entries)
          for (final item in group.value as List<dynamic>)
            catalogItem(item as Map<String, dynamic>, group.key),
      ],
    );
  }
}
