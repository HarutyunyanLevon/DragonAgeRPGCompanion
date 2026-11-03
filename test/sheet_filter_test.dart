import 'package:dragon_age_companion/features/sheet/sheet_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an empty query matches everything and is not active', () {
    const filter = SheetFilter('  ');
    expect(filter.isActive, isFalse);
    expect(filter.matches(['Anything']), isTrue);
    expect(filter.matches([]), isTrue);
  });

  test('matching ignores case and looks at every text', () {
    const filter = SheetFilter('AXE');
    expect(filter.isActive, isTrue);
    expect(filter.matches(['Battle Axe']), isTrue);
    expect(filter.matches(['Mace', 'A big axe']), isTrue);
    expect(filter.matches(['Mace']), isFalse);
    expect(filter.matches([]), isFalse);
  });
}
