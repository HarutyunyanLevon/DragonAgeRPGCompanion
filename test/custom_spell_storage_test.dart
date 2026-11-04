import 'dart:io';

import 'package:dragon_age_companion/rules/custom_spell_storage.dart';
import 'package:dragon_age_companion/rules/models/spell.dart';
import 'package:flutter_test/flutter_test.dart';

Spell sample(String name) => Spell(
      name: name,
      school: 'Primal',
      type: 'Attack',
      mana: '5 MP',
      castTime: 'Major Action',
      tn: '12',
      test: 'Dexterity (Acrobatics) vs. Spellpower',
      requirement: 'Arcane Bolt',
      description: 'Homebrew.',
      requires: const [SpellRequirement(type: 'spell', id: 'arcane-bolt')],
      homebrew: true,
    );

void main() {
  late Directory dir;
  late CustomSpellStorage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('custom_spells_test');
    storage = CustomSpellStorage(File('${dir.path}/data/custom_spells.json'));
  });

  tearDown(() async => dir.delete(recursive: true));

  test('loads nothing before the first save', () async {
    expect(await storage.load(), isEmpty);
  });

  test('saved spells come back complete', () async {
    await storage.save([sample('Ember Lash'), sample('Frost Nip')]);

    final loaded = await storage.load();
    expect(loaded.map((s) => s.id), ['ember-lash', 'frost-nip']);
    expect(loaded.first.homebrew, isTrue);
    expect(loaded.first.requires.single.id, 'arcane-bolt');
  });
}
