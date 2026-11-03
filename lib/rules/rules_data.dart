import 'models/backgrounds.dart';
import 'models/classes.dart';
import 'models/spell.dart';
import 'models/talents.dart';

/// All rules the app has typed models for. Read-only after loading.
/// Other rules files (gear, magic, poisons, ...) get typed here when a
/// feature needs them.
class RulesData {
  const RulesData({
    required this.classes,
    required this.backgrounds,
    required this.talents,
    required this.spells,
  });

  final ClassesFile classes;
  final BackgroundsFile backgrounds;
  final TalentsFile talents;
  final List<Spell> spells;

  Spell spellById(String id) => spells.firstWhere((s) => s.id == id);
}
