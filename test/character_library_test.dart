import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/character_library.dart';
import 'package:dragon_age_companion/character/settings_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Character sample(String id, String name) => Character(
      id: id,
      name: name,
      backgroundId: 'fereldan-freeman',
      race: 'human',
      classId: 'warrior',
      abilities: const {},
      bankedAdvancements: const {},
      focuses: const [],
      talents: const [],
      specializations: const [],
      spellIds: const [],
      traitIds: const [],
      weaponGroups: const [],
      languages: const [],
      maxHealth: 30,
      health: 30,
      inventory: const [],
      owedGains: const [],
      goals: const [],
      ties: const [],
    );

void main() {
  group('CharacterLibrary', () {
    final characters = [
      sample('1000', 'Zed'),
      sample('3000', 'alma'),
      sample('2000', 'Bran'),
    ];

    test('is sorted by name, ignoring case', () {
      final library = CharacterLibrary(characters);
      expect(library.characters.map((c) => c.name), ['alma', 'Bran', 'Zed']);
    });

    test('selects the preferred character', () {
      final library = CharacterLibrary(characters, preferredId: '2000');
      expect(library.selected!.name, 'Bran');
    });

    test('falls back to the newest when the preferred one is gone', () {
      final library = CharacterLibrary(characters, preferredId: '9999');
      expect(library.selectedId, '3000');
      expect(CharacterLibrary(characters).selectedId, '3000');
    });

    test('no characters: nothing selected', () {
      final library = CharacterLibrary([], preferredId: '1000');
      expect(library.selectedId, isNull);
      expect(library.selected, isNull);
    });
  });

  group('SettingsStorage', () {
    late Directory dir;
    late SettingsStorage storage;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('settings_test');
      storage = SettingsStorage(File('${dir.path}/data/settings.json'));
    });

    tearDown(() => dir.delete(recursive: true));

    test('a missing file means nothing selected', () async {
      expect(await storage.loadSelectedId(), isNull);
    });

    test('remembers the selected id', () async {
      await storage.saveSelectedId('1234');
      expect(await storage.loadSelectedId(), '1234');
      await storage.saveSelectedId(null);
      expect(await storage.loadSelectedId(), isNull);
    });
  });
}
