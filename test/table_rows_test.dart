import 'dart:io';

import 'package:dragon_age_companion/features/create/table_row_editor.dart';
import 'package:dragon_age_companion/rules/models/backgrounds.dart';
import 'package:dragon_age_companion/rules/models/classes.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BackgroundsFile backgrounds;
  late ClassesFile classes;

  setUpAll(() async {
    final loader = RulesLoader((path) => File(path).readAsString());
    backgrounds = await loader.loadBackgrounds();
    classes = await loader.loadClasses();
  });

  test('every book table has the rows the editor shows', () {
    for (final background in backgrounds.backgrounds) {
      for (final table in background.tables.values) {
        final ranges = [for (final row in table) (row.min, row.max)];
        expect(ranges, tableRanges, reason: background.name);
      }
    }
  });

  test('sameAs compares what a row gives, not its fallback', () {
    const bows = TableResult(type: 'weaponGroup', group: 'bows');
    const withFallback = TableResult(
      type: 'weaponGroup',
      group: 'bows',
      ifClassHasGroup: FocusRef(ability: 'dexterity', focus: 'bows'),
    );
    const axes = TableResult(type: 'weaponGroup', group: 'axes');
    const strength = TableResult(type: 'ability', ability: 'strength');
    const strengthFocus =
        TableResult(type: 'focus', ability: 'strength', focus: 'might');

    expect(bows.sameAs(withFallback), isTrue);
    expect(bows.sameAs(axes), isFalse);
    expect(strength.sameAs(strengthFocus), isFalse);
  });

  test('allWeaponGroups lists every group once, sorted', () {
    final groups = classes.allWeaponGroups;

    expect(groups, containsAll(['axes', 'bows', 'brawling', 'staves']));
    expect(groups.toSet().length, groups.length);
    expect(groups, [...groups]..sort());
  });
}
