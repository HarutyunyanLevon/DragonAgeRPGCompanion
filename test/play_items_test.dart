import 'dart:io';

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/play_items.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'character_test.dart' show sample;

PlayItem item(String name) => PlayItem(type: 'text', name: name);

PlayWidgetData widgetOf(String id, List<String> names) =>
    PlayWidgetData(id: id, title: id, items: [for (final n in names) item(n)]);

List<String> names(List<PlayWidgetData> widgets, String id) =>
    widgets.firstWhere((w) => w.id == id).items.map((i) => i.name).toList();

void main() {
  group('item edits', () {
    final widgets = [widgetOf('a', ['1', '2', '3']), widgetOf('b', ['x'])];

    test('add, replace and remove', () {
      expect(names(addItem(widgets, 'a', item('4')), 'a'), ['1', '2', '3', '4']);
      expect(names(replaceItem(widgets, 'a', 1, item('two')), 'a'),
          ['1', 'two', '3']);
      expect(names(removeItem(widgets, 'a', 0), 'a'), ['2', '3']);
    });

    test('moving inside one widget', () {
      expect(names(moveItem(widgets, 'a', 0, 'a', 3), 'a'), ['2', '3', '1']);
      expect(names(moveItem(widgets, 'a', 2, 'a', 0), 'a'), ['3', '1', '2']);
      expect(names(moveItem(widgets, 'a', 1, 'a', 2), 'a'), ['1', '2', '3']);
    });

    test('moving to another widget', () {
      final moved = moveItem(widgets, 'a', 1, 'b', 0);
      expect(names(moved, 'a'), ['1', '3']);
      expect(names(moved, 'b'), ['2', 'x']);
      expect(names(moveItem(widgets, 'a', 0, 'b', 1), 'b'), ['x', '1']);
    });

    test('rename and style', () {
      expect(renameWidget(widgets, 'a', 'New').first.title, 'New');
      expect(setWidgetStyle(widgets, 'b', 'tiles').last.style, 'tiles');
    });
  });

  group('saved layouts', () {
    final c = sample().copyWith(
      playWidgets: [widgetOf('a', ['1'])],
      playLayouts: const {
        'phone': [PlayTile(widget: 'a', width: 4, height: 2)],
      },
    );

    test('save keeps widgets and places; same name replaces', () {
      final saved = c.copyWith(playPresets: savePreset(c, 'Combat'));
      expect(saved.playPresets!.single.widgets.single.id, 'a');

      final again = savePreset(saved, 'Combat');
      expect(again.length, 1);
      expect(savePreset(saved, 'Travel').length, 2);
    });

    test('load brings widgets and places back', () {
      final preset = savePreset(c, 'Combat').single;
      final changed = c.copyWith(playWidgets: const [], playLayouts: const {});
      final loaded = loadPreset(changed, preset);
      expect(loaded.playWidgets!.single.id, 'a');
      expect(loaded.playLayouts['phone']!.single.width, 4);
    });

    test('rename and remove', () {
      final saved = c.copyWith(playPresets: savePreset(c, 'Combat'));
      expect(renamePreset(saved, 'Combat', 'War').single.name, 'War');
      expect(removePreset(saved, 'Combat'), isEmpty);
    });
  });

  group('default widgets', () {
    test('"*" items become what the character has', () async {
      final rules =
          await RulesLoader((path) => File(path).readAsString()).load();
      final c = sample();
      final widgets = materializeWidgets(c, rules);

      expect(widgets.map((w) => w.id), rules.widgetTemplates.map((w) => w.id));
      for (final w in widgets) {
        expect(w.items.where((i) => i.ref.endsWith('*')), isEmpty, reason: w.id);
      }
      final talents = widgets.firstWhere((w) => w.id == 'talents');
      expect(talents.items.any((i) => i.type == 'talent'), isTrue);
      expect(talents.items.any((i) => i.type == 'trait'), isTrue);
    });

    test('fresh widgets from a template get the given id', () async {
      final rules =
          await RulesLoader((path) => File(path).readAsString()).load();
      final copy = widgetFromTemplate(
          rules.widgetTemplates.first, sample(), rules, 'w1');
      expect(copy.id, 'w1');
    });
  });
}
