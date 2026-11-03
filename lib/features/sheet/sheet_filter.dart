import '../../character/character.dart';
import '../../rules/models/specializations.dart';
import '../../rules/models/talents.dart';
import '../../rules/rules_data.dart';
import '../../shared/display_name.dart';

/// The Sheet's search box: what was typed, and whether a row's texts (its
/// name and description) contain it. An empty query matches everything.
class SheetFilter {
  const SheetFilter(this.query);

  final String query;

  bool get isActive => query.trim().isNotEmpty;

  bool matches(Iterable<String> texts) {
    if (!isActive) return true;
    final wanted = query.trim().toLowerCase();
    return texts.any((text) => text.toLowerCase().contains(wanted));
  }
}

// What is searched for each kind of row: its name plus its description text.

List<String> talentTexts(Talent talent) => [
      talent.name,
      talent.degrees.novice,
      talent.degrees.journeyman,
      talent.degrees.master,
      ...talent.notes,
    ];

List<String> specializationTexts(Specialization specialization) => [
      specialization.name,
      specialization.degrees.novice,
      specialization.degrees.journeyman,
      specialization.degrees.master,
      ...specialization.notes,
    ];

List<String> abilityTexts(RulesData rules, String ability) =>
    [displayName(ability), rules.abilityDescriptions[ability] ?? ''];

List<String> itemTexts(RulesData rules, InventoryItem item) {
  final weapon = rules.weaponById(item.itemId);
  final entry = rules.catalog.where((e) => e.id == item.itemId).firstOrNull;
  return [
    item.name,
    item.note,
    if (entry != null) displayName(entry.category),
    if (weapon != null) displayName(weapon.group),
  ];
}
