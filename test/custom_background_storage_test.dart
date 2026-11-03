import 'dart:io';

import 'package:dragon_age_companion/rules/custom_background_storage.dart';
import 'package:dragon_age_companion/rules/models/backgrounds.dart';
import 'package:flutter_test/flutter_test.dart';

Background sample(String id) => Background(
      id: id,
      name: 'Sample $id',
      races: const ['elf'],
      abilityBonus: 'dexterity',
      focusChoices: const [
        FocusRef(ability: 'dexterity', focus: 'stealth'),
        FocusRef(ability: 'cunning', focus: 'arcane-lore'),
      ],
      languages: const ['elven'],
      classes: const ['rogue'],
      casteChoices: const [],
      tables: const {
        'any': [
          BackgroundTableRow(
            min: 2,
            max: 12,
            result: TableResult(type: 'ability', ability: 'dexterity'),
          ),
        ],
      },
      notes: const [],
      homebrew: true,
    );

void main() {
  late Directory dir;
  late CustomBackgroundStorage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('custom_backgrounds_test');
    storage = CustomBackgroundStorage(File('${dir.path}/data/custom.json'));
  });

  tearDown(() async => dir.delete(recursive: true));

  test('loads nothing before the first save', () async {
    expect(await storage.load(), isEmpty);
  });

  test('saved backgrounds come back complete', () async {
    await storage.save([sample('custom-a'), sample('custom-b')]);

    final loaded = await storage.load();
    expect(loaded.map((b) => b.id), ['custom-a', 'custom-b']);
    expect(loaded.first.homebrew, isTrue);
    expect(loaded.first.focusChoices.last.focus, 'arcane-lore');
    expect(loaded.first.tables['any']!.single.result.ability, 'dexterity');
  });

  test('saving a shorter list removes the others', () async {
    await storage.save([sample('custom-a'), sample('custom-b')]);
    await storage.save([sample('custom-b')]);
    expect((await storage.load()).map((b) => b.id), ['custom-b']);
  });
}
