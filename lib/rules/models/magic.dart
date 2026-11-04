/// The parts of magic.json the app uses: armor strain, the standard spell
/// stunts and the mishap table. (Hand-written fromJson: the file mixes shapes.)

/// A stunt a caster can buy with the stunt points of a successful casting
/// roll with doubles.
class SpellStunt {
  const SpellStunt({
    required this.id,
    required this.name,
    required this.spCost,
    required this.effect,
    this.variable = false,
  });

  final String id;
  final String name;
  final int spCost;
  final String effect;

  /// [spCost] is a minimum: the player chooses how many SP to spend.
  final bool variable;

  factory SpellStunt.fromJson(Map<String, dynamic> json) => SpellStunt(
        id: json['id'] as String,
        name: json['name'] as String,
        spCost: json['spCost'] as int,
        effect: json['effect'] as String,
        variable: json['variable'] as bool? ?? false,
      );
}

/// One row of the mishap table (read with the Dragon Die of the saving test).
class Mishap {
  const Mishap({required this.die, required this.name, required this.effect});

  final int die;
  final String name;
  final String effect;

  factory Mishap.fromJson(Map<String, dynamic> json) => Mishap(
        die: json['die'] as int,
        name: json['name'] as String,
        effect: json['effect'] as String,
      );
}

class MagicFile {
  const MagicFile({
    required this.armorStrain,
    required this.standardStunts,
    required this.mishaps,
  });

  /// Armor id -> mana added to every spell. Armor that is not listed adds 0.
  final Map<String, int> armorStrain;
  final List<SpellStunt> standardStunts;
  final List<Mishap> mishaps;

  Mishap mishapFor(int die) => mishaps.firstWhere((m) => m.die == die);

  factory MagicFile.fromJson(Map<String, dynamic> json) {
    final strain = json['armorStrain'] as Map<String, dynamic>;
    final mishaps = json['mishaps'] as Map<String, dynamic>;
    return MagicFile(
      // The map also holds a "note" text; only the numbers are strain values.
      armorStrain: {
        for (final e in strain.entries)
          if (e.value is int) e.key: e.value as int,
      },
      standardStunts: [
        for (final s in json['standardStunts'] as List<dynamic>)
          SpellStunt.fromJson(s as Map<String, dynamic>),
      ],
      mishaps: [
        for (final m in mishaps['table'] as List<dynamic>)
          Mishap.fromJson(m as Map<String, dynamic>),
      ],
    );
  }
}
