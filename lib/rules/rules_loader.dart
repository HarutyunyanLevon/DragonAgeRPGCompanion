import 'dart:convert';

import '../character/character.dart';
import 'models/backgrounds.dart';
import 'models/classes.dart';
import 'models/focus_entry.dart';
import 'models/gear.dart';
import 'models/magic.dart';
import 'models/specializations.dart';
import 'models/stunt.dart';
import 'models/spell.dart';
import 'models/talents.dart';
import 'rules_data.dart';

/// Reads a text file by path. The app passes `rootBundle.loadString`;
/// tests pass a function that reads from disk.
typedef TextReader = Future<String> Function(String path);

class RulesLoader {
  RulesLoader(this._read, {this.folder = 'assets/rules'});

  final TextReader _read;
  final String folder;

  Future<Object?> _json(String file) async =>
      jsonDecode(await _read('$folder/$file'));

  Future<ClassesFile> loadClasses() async => ClassesFile.fromJson(
      await _json('classes.json') as Map<String, dynamic>);

  Future<BackgroundsFile> loadBackgrounds() async => BackgroundsFile.fromJson(
      await _json('backgrounds.json') as Map<String, dynamic>);

  Future<TalentsFile> loadTalents() async => TalentsFile.fromJson(
      await _json('talents.json') as Map<String, dynamic>);

  Future<SpecializationsFile> loadSpecializations() async =>
      SpecializationsFile.fromJson(
          await _json('specializations.json') as Map<String, dynamic>);

  /// The focus list inside core.json (the rest of that file has no model yet).
  Future<List<FocusEntry>> loadFocuses() async {
    final core = await _json('core.json') as Map<String, dynamic>;
    return [
      for (final f in core['focuses'] as List<dynamic>)
        FocusEntry.fromJson(f as Map<String, dynamic>)
    ];
  }

  Future<List<Spell>> loadSpells() async {
    final list = await _json('spells.json') as List<dynamic>;
    return [for (final s in list) Spell.fromJson(s as Map<String, dynamic>)];
  }

  Future<List<StarterSpellSet>> loadStarterSets() async {
    final list = await _json('starter_spells.json') as List<dynamic>;
    return [
      for (final s in list) StarterSpellSet.fromJson(s as Map<String, dynamic>)
    ];
  }

  Future<Map<String, String>> loadAbilityDescriptions() async =>
      (await _json('abilities.json') as Map<String, dynamic>)
          .cast<String, String>();

  /// Weapons, armor, shields and the item catalog (gear.json).
  Future<GearFile> loadGear() async =>
      GearFile.fromJson(await _json('gear.json') as Map<String, dynamic>);

  /// Armor strain, spell stunts and the mishap table (magic.json).
  Future<MagicFile> loadMagic() async =>
      MagicFile.fromJson(await _json('magic.json') as Map<String, dynamic>);

  /// One stunt list of a rules file, e.g. ('core.json', 'combatStunts').
  Future<List<Stunt>> loadStunts(String file, String key) async =>
      stuntsFromJson((await _json(file) as Map<String, dynamic>)[key]);

  /// The default Play widgets and where they sit per device class.
  Future<({List<PlayWidgetData> templates, Map<String, List<PlayTile>> layouts})>
      loadPlayDefaults() async {
    final json = await _json('default_layouts.json') as Map<String, dynamic>;
    final layouts = json['layouts'] as Map<String, dynamic>;
    return (
      templates: [
        for (final t in json['templates'] as List<dynamic>)
          PlayWidgetData.fromJson(t as Map<String, dynamic>)
      ],
      layouts: {
        for (final e in layouts.entries)
          e.key: [
            for (final t in e.value as List<dynamic>)
              PlayTile.fromJson(t as Map<String, dynamic>)
          ],
      },
    );
  }

  Future<RulesData> load() async {
    final gear = await loadGear();
    final play = await loadPlayDefaults();
    return RulesData(
      classes: await loadClasses(),
      backgrounds: await loadBackgrounds(),
      talents: await loadTalents(),
      specializations: await loadSpecializations(),
      focuses: await loadFocuses(),
      spells: await loadSpells(),
      starterSets: await loadStarterSets(),
      abilityDescriptions: await loadAbilityDescriptions(),
      weaponGroups: gear.weaponGroups,
      weapons: gear.weapons,
      armor: gear.armor,
      shields: gear.shields,
      catalog: gear.catalog,
      magic: await loadMagic(),
      combatStunts: await loadStunts('core.json', 'combatStunts'),
      explorationStunts: await loadStunts('exploration.json', 'explorationStunts'),
      roleplayingStunts: await loadStunts('exploration.json', 'roleplayingStunts'),
      widgetTemplates: play.templates,
      defaultLayouts: play.layouts,
    );
  }
}
