import 'package:dragon_age_companion/rules/slug.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('slug matches the ids used in the rules JSON', () {
    expect(slug('Winter’s Grasp'), 'winters-grasp');
    expect(slug('Light Blades'), 'light-blades');
    expect(slug('Backpack, traveler\'s'), 'backpack-travelers');
    expect(slug('  Fire Bomb '), 'fire-bomb');
  });
}
