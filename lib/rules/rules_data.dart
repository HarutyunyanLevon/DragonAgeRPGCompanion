import 'models/backgrounds.dart';
import 'models/classes.dart';
import 'models/focus_entry.dart';
import 'models/gear.dart';
import 'models/magic.dart';
import 'models/specializations.dart';
import 'models/spell.dart';
import 'models/talents.dart';

/// All rules the app has typed models for. Read-only after loading.
/// Other rules files (magic, poisons, ...) get typed here when a
/// feature needs them.
class RulesData {
  const RulesData({
    required this.classes,
    required this.backgrounds,
    required this.talents,
    required this.specializations,
    required this.focuses,
    required this.spells,
    required this.starterSets,
    required this.abilityDescriptions,
    required this.weaponGroups,
    required this.weapons,
    required this.armor,
    required this.shields,
    required this.catalog,
    required this.magic,
  });

  final ClassesFile classes;
  final BackgroundsFile backgrounds;
  final TalentsFile talents;
  final SpecializationsFile specializations;
  final List<FocusEntry> focuses;
  final List<Spell> spells;
  final List<StarterSpellSet> starterSets;

  /// Ability id -> one-line description.
  final Map<String, String> abilityDescriptions;
  final List<WeaponGroup> weaponGroups;
  final List<Weapon> weapons;
  final List<Armor> armor;
  final List<Shield> shields;

  /// Everything buyable, for the "Add item" sheet.
  final List<CatalogEntry> catalog;

  /// Armor strain, spell stunts and mishaps (magic.json).
  final MagicFile magic;

  WeaponGroup weaponGroupById(String id) =>
      weaponGroups.firstWhere((g) => g.id == id);

  List<Weapon> weaponsIn(String group) =>
      [for (final w in weapons) if (w.group == group) w];

  Spell spellById(String id) => spells.firstWhere((s) => s.id == id);

  // Inventory items point here by id. A custom item has no id, so these
  // return null for it (and for ids that are not armor / shield / weapon).
  Armor? armorById(String? id) => armor.where((a) => a.id == id).firstOrNull;

  Shield? shieldById(String? id) =>
      shields.where((s) => s.id == id).firstOrNull;

  Weapon? weaponById(String? id) =>
      weapons.where((w) => w.id == id).firstOrNull;

  CatalogEntry catalogEntry(String id) => catalog.firstWhere((e) => e.id == id);
}
