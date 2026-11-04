import 'dart:convert';
import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/character_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Character sample({String id = 'c1', String name = 'Aveline'}) => Character(
      id: id,
      name: name,
      backgroundId: 'fereldan-noble',
      race: 'human',
      classId: 'warrior',
      abilities: const {'strength': 3, 'dexterity': 2, 'constitution': 1},
      bankedAdvancements: const {'strength': 1},
      focuses: const [
        CharacterFocus(ability: 'strength', focus: 'axes', doubled: true)
      ],
      talents: const [DegreeEntry(id: 'single-weapon-style', degree: 2)],
      specializations: const [],
      spellIds: const [],
      traitIds: const ['magic-resistance'],
      weaponGroups: const ['axes'],
      languages: const ['trade-tongue'],
      maxHealth: 38,
      health: 30,
      copper: 5200,
      inventory: const [InventoryItem(name: 'Battle Axe', itemId: 'axes-battle-axe')],
      owedGains: const [],
      goals: const ['Prove myself worthy'],
      ties: const [],
      playLayouts: const {},
    );

void main() {
  group('Character JSON', () {
    test('survives a save and load round trip', () {
      final original = sample();
      final text = jsonEncode(original.toJson());
      final copy = Character.fromJson(jsonDecode(text) as Map<String, dynamic>);

      expect(copy.name, 'Aveline');
      expect(copy.abilities['strength'], 3);
      expect(copy.bankedAdvancements['strength'], 1);
      expect(copy.focuses.single.bonus, 3);
      expect(copy.talents.single.degree, 2);
      expect(copy.traitIds, ['magic-resistance']);
      expect(copy.inventory.single.itemId, 'axes-battle-axe');
      expect(jsonEncode(copy.toJson()), text);
    });

    test('play widgets and layouts survive a round trip', () {
      final original = sample().copyWith(
        playWidgets: const [
          PlayWidgetData(id: 'notes', title: 'Notes', items: [
            PlayItem(type: 'text', name: 'Poisoned'),
          ]),
        ],
        playLayouts: {
          'phone': [const PlayTile(widget: 'notes', width: 4, height: 2)],
        },
      );
      final copy = Character.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);

      expect(copy.playWidgets!.single.items.single.name, 'Poisoned');
      expect(copy.playLayouts['phone']!.single.widget, 'notes');
    });

    test('older saves with missing optional fields still load', () {
      final minimal = {
        'id': 'old',
        'name': 'Old Save',
        'backgroundId': 'avvar',
        'race': 'human',
        'classId': 'rogue',
        'abilities': {'dexterity': 3},
        'maxHealth': 20,
        'health': 20,
      };
      final c = Character.fromJson(minimal);
      expect(c.level, 1);
      expect(c.focuses, isEmpty);
      expect(c.traitIds, isEmpty);
      expect(c.ability('magic'), 0);
    });
  });

  group('CharacterStorage', () {
    late Directory dir;
    late CharacterStorage storage;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('characters_test');
      storage = CharacterStorage(Directory('${dir.path}/characters'));
    });

    tearDown(() async => dir.delete(recursive: true));

    test('lists nothing before the first save', () async {
      expect(await storage.loadAll(), isEmpty);
    });

    test('saves, loads, lists (sorted by name) and deletes', () async {
      await storage.save(sample(id: 'b', name: 'Bran'));
      await storage.save(sample(id: 'a', name: 'Aveline'));

      expect((await storage.loadAll()).map((c) => c.name), ['Aveline', 'Bran']);
      expect((await storage.load('a')).name, 'Aveline');

      await storage.delete('a');
      expect((await storage.loadAll()).map((c) => c.id), ['b']);
    });

    test('saving again overwrites the same file', () async {
      await storage.save(sample(name: 'First'));
      await storage.save(sample(name: 'Second'));
      final all = await storage.loadAll();
      expect(all.length, 1);
      expect(all.single.name, 'Second');
    });

    test('export then import gives the same character', () async {
      await storage.save(sample());
      final exported = File('${dir.path}/export.json');
      await storage.exportTo('c1', exported);

      final other = CharacterStorage(Directory('${dir.path}/other'));
      final imported = await other.importFrom(exported);
      expect(imported.name, 'Aveline');
      expect((await other.loadAll()).length, 1);
    });
  });
}
