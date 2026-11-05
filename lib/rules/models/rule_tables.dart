/// The small tables of core.json the Glossary shows: difficulties, advanced
/// test thresholds, attack modifiers, healing and the actions. (Hand-written
/// fromJson: the file mixes shapes and the rest of it has no model yet.)

/// A name with a number: a difficulty and its TN, or an advanced test
/// difficulty and its success threshold.
class NamedNumber {
  const NamedNumber(this.name, this.number);

  final String name;
  final int number;
}

class AttackModifier {
  const AttackModifier(this.modifier, this.circumstance);

  final int modifier;
  final String circumstance;
}

class HealingMethod {
  const HealingMethod(this.method, this.amount);

  final String method;
  final String amount;
}

/// A major or minor action.
class ActionRule {
  const ActionRule(this.name, this.effect);

  final String name;
  final String effect;
}

class RuleTables {
  const RuleTables({
    required this.difficulties,
    required this.thresholds,
    required this.attackModifiers,
    required this.healing,
    required this.majorActions,
    required this.minorActions,
  });

  final List<NamedNumber> difficulties; // number = TN
  final List<NamedNumber> thresholds; // number = success threshold
  final List<AttackModifier> attackModifiers;
  final List<HealingMethod> healing;
  final List<ActionRule> majorActions;
  final List<ActionRule> minorActions;

  /// [core] is the decoded core.json.
  factory RuleTables.fromJson(Map<String, dynamic> core) {
    List<Map<String, dynamic>> list(String key) =>
        [for (final e in core[key] as List<dynamic>) e as Map<String, dynamic>];

    List<ActionRule> actions(String key) => [
          for (final a in list(key))
            ActionRule(a['name'] as String, a['effect'] as String),
        ];

    return RuleTables(
      difficulties: [
        for (final d in list('difficulties'))
          NamedNumber(d['name'] as String, d['tn'] as int),
      ],
      thresholds: [
        for (final d in list('advancedThresholds'))
          NamedNumber(d['name'] as String, d['threshold'] as int),
      ],
      attackModifiers: [
        for (final m in list('attackModifiers'))
          AttackModifier(m['mod'] as int, m['circumstance'] as String),
      ],
      healing: [
        for (final h in list('healing'))
          HealingMethod(h['method'] as String, h['amount'] as String),
      ],
      majorActions: actions('majorActions'),
      minorActions: actions('minorActions'),
    );
  }
}
