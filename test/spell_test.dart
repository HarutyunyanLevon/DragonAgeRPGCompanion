import 'package:dragon_age_companion/rules/models/spell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Spell reads the spells.json shape and derives its id', () {
    final spell = Spell.fromJson({
      'name': 'Winter’s Grasp',
      'school': 'Primal',
      'type': 'Attack',
      'mana': '3 MP',
      'castTime': 'Major Action',
      'tn': '12',
      'test': 'Constitution (Stamina) vs. Spellpower',
      'requirement': '',
      'description': 'Frost.',
      'source_page_pdf': 128,
    });
    expect(spell.id, 'winters-grasp');
    expect(spell.sourcePagePdf, 128);
  });
}
