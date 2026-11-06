import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/play_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widget = PlayWidgetData(id: 'a', title: 'Combat', items: []);

  test('a titled widget has a header', () {
    expect(widget.hasHeader, isTrue);
  });

  test('a hidden or blank title has no header', () {
    expect(widget.copyWith(showTitle: false).hasHeader, isFalse);
    expect(widget.copyWith(title: '').hasHeader, isFalse);
    expect(widget.copyWith(title: '   ').hasHeader, isFalse);
  });

  test('hiding the title keeps the text', () {
    final hidden = setWidgetTitleShown([widget], 'a', false).single;
    expect(hidden.showTitle, isFalse);
    expect(hidden.title, 'Combat');
    expect(setWidgetTitleShown([hidden], 'a', true).single.hasHeader, isTrue);
  });

  test('the flag is saved and old saves show the title', () {
    final hidden = widget.copyWith(showTitle: false);
    expect(PlayWidgetData.fromJson(hidden.toJson()).showTitle, isFalse);

    final old = hidden.toJson()..remove('showTitle');
    expect(PlayWidgetData.fromJson(old).showTitle, isTrue);
  });
}
