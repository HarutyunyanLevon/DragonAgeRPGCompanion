/// A stunt bought with stunt points (SP): combat, exploration, roleplaying or
/// spell stunt. The lists live in core.json, exploration.json and magic.json.
class Stunt {
  const Stunt({
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

  factory Stunt.fromJson(Map<String, dynamic> json) => Stunt(
        id: json['id'] as String,
        name: json['name'] as String,
        spCost: json['spCost'] as int,
        effect: json['effect'] as String,
        variable: json['variable'] as bool? ?? false,
      );
}

/// Reads a JSON list of stunts.
List<Stunt> stuntsFromJson(Object? list) => [
      for (final s in list as List<dynamic>)
        Stunt.fromJson(s as Map<String, dynamic>),
    ];
