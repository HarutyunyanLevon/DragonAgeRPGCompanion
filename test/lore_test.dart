import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset, Rect, Size;

import 'package:dragon_age_companion/character/character.dart';
import 'package:dragon_age_companion/character/lore.dart';
import 'package:dragon_age_companion/character/lore_data.dart';
import 'package:dragon_age_companion/character/play_items.dart';
import 'package:dragon_age_companion/rules/models/lore.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:dragon_age_companion/shared/name_linker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader((path) => File(path).readAsString()).load();
  });

  const empty = LoreData.empty();

  Map<String, LoreItem> byId([LoreData data = empty]) => {
        for (final i in buildLoreItems(rules.loreEntries, data)) i.id: i,
      };

  group('lore.json', () {
    test('has 6 tags and entries with unique ids', () {
      expect(rules.loreTags.length, 6);
      final ids = rules.loreEntries.map((e) => e.id).toList();
      expect(ids.length, greaterThan(200));
      expect(ids.toSet().length, ids.length);
    });

    test('every tag and every link points at something that exists', () {
      final tags = rules.loreTags.map((t) => t.id).toSet();
      final ids = rules.loreEntries.map((e) => e.id).toSet();
      for (final entry in rules.loreEntries) {
        expect(entry.name, isNotEmpty);
        expect(entry.summary, isNotEmpty, reason: entry.id);
        expect(entry.tags, isNotEmpty, reason: entry.id);
        for (final tag in entry.tags) {
          expect(tags, contains(tag), reason: '${entry.id}: $tag');
        }
        for (final link in entry.links) {
          expect(ids, contains(link), reason: '${entry.id} -> $link');
        }
      }
    });
  });

  group('entries and tags', () {
    test('own entries come first, additions are merged into book entries', () {
      final data = const LoreData.empty().copyWith(
        myEntries: [
          const MyLoreEntry(
              id: 'my-tavern', name: 'The Tavern', tags: ['place'], text: 'Our base.', links: []),
        ],
        additions: [
          const LoreAddition(
              entryId: 'ferelden', tags: ['event'], links: ['orlais', 'my-tavern'], note: 'home'),
        ],
      );
      final items = buildLoreItems(rules.loreEntries, data);

      expect(items.first.id, 'my-tavern');
      expect(items.first.isMine, isTrue);

      final ferelden = items.firstWhere((i) => i.id == 'ferelden');
      expect(ferelden.tags, ['place', 'faction', 'event']);
      expect(ferelden.links, contains('my-tavern'));
      expect(ferelden.links.where((l) => l == 'orlais').length, 1); // no duplicate
      expect(ferelden.note, 'home');
    });

    test('an empty addition is dropped', () {
      var data = setAddition(empty,
          const LoreAddition(entryId: 'ferelden', tags: [], links: [], note: 'x'));
      expect(data.additions.length, 1);
      data = setAddition(
          data, const LoreAddition(entryId: 'ferelden', tags: [], links: [], note: ' '));
      expect(data.additions, isEmpty);
    });

    test('tags get default colors, the player can change them', () {
      final tags = allTags(rules.loreTags, empty);
      final colors = tagColorMap(tags, empty);
      expect(colors.length, tags.length);
      expect(colors[tags.first.id], lorePalette.first);

      final changed = tagColorMap(tags, setTagColor(empty, tags.first.id, 0xFF112233));
      expect(changed[tags.first.id], 0xFF112233);
    });

    test('own tags: add, color, remove from everything', () {
      var data = addTag(empty, const LoreTag(id: 'tag-fun', name: 'Fun'), 0xFF010203);
      data = data.copyWith(myEntries: [
        const MyLoreEntry(id: 'my-a', name: 'A', tags: ['tag-fun', 'place'], text: '', links: []),
      ]);
      expect(allTags(rules.loreTags, data).last.id, 'tag-fun');
      expect(data.tagColors['tag-fun'], 0xFF010203);

      data = removeTag(data, 'tag-fun');
      expect(data.myTags, isEmpty);
      expect(data.tagColors, isEmpty);
      expect(data.myEntries.single.tags, ['place']);
    });

    test('hex colors', () {
      expect(parseHexColor('#C9A227'), 0xFFC9A227);
      expect(parseHexColor('c9a227'), 0xFFC9A227);
      expect(parseHexColor('#C9A22'), isNull);
      expect(parseHexColor('zzzzzz'), isNull);
    });

    test('palette keeps each new color once', () {
      var data = addPaletteColor(empty, 0xFF123456);
      data = addPaletteColor(data, 0xFF123456);
      data = addPaletteColor(data, lorePalette.first);
      expect(data.palette, [0xFF123456]);
    });

    test('unique ids', () {
      expect(uniqueId('my-a', const []), 'my-a');
      expect(uniqueId('my-a', ['my-a']), 'my-a-2');
      expect(uniqueId('my-a', ['my-a', 'my-a-2']), 'my-a-3');
    });
  });

  group('links in text', () {
    test('link names drop "(...)", a leading "The" and the part after a comma', () {
      expect(loreLinkNames('Thedas (Overview)'), ['Thedas']);
      expect(loreLinkNames('The Fade (the Beyond)'), ['The Fade', 'Fade']);
      expect(loreLinkNames('Moira, the Rebel Queen'),
          ['Moira, the Rebel Queen', 'Moira']);
      expect(loreLinkNames('Orlais'), ['Orlais']);
    });

    test('names found in a text are suggested, once each, never the entry itself', () {
      final items = buildLoreItems(rules.loreEntries, empty);
      final linker = NameLinker(loreNameMap(items));
      final ids = suggestLinks(
          'We left Orlais for Ferelden, then back to Orlais.', 'ferelden', linker);
      expect(ids, ['orlais']);
    });
  });

  group('graph', () {
    test('the first entry lands around the middle of the graph', () {
      final node = pinEntry(empty, 'ferelden', byId()).nodes.single;
      expect(node.rect.center, Offset.zero);
      expect(node.width, GraphNode.defaultTileWidth);
    });

    bool anyOverlap(List<GraphNode> nodes) {
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          if (nodes[i].rect.overlaps(nodes[j].rect)) return true;
        }
      }
      return false;
    }

    test('a linked entry lands near its partner, not on top of other tiles', () {
      final items = byId();
      var data = pinEntry(empty, 'ferelden', items);
      data = pinEntry(data, 'orlais', items); // Ferelden links to Orlais
      data = pinEntry(data, 'denerim', items); // Ferelden links to Denerim

      final ferelden = data.nodes.firstWhere((n) => n.entryId == 'ferelden');
      for (final node in data.nodes.where((n) => n.entryId != 'ferelden')) {
        expect((node.rect.center - ferelden.rect.center).distance, lessThan(700),
            reason: node.entryId);
      }
      expect(anyOverlap(data.nodes), isFalse);
    });

    test('pinning twice or an unknown id changes nothing', () {
      final items = byId();
      final data = pinEntry(empty, 'ferelden', items);
      expect(pinEntry(data, 'ferelden', items).nodes.length, 1);
      expect(pinEntry(data, 'no-such-entry', items).nodes.length, 1);
    });

    test('the graph has no limits; tiles keep a minimum size', () {
      var data = pinEntry(empty, 'ferelden', byId());
      data = moveNode(data, 'ferelden', const Offset(-90000, 120000));
      expect(data.nodes.single.x, -90000);
      expect(data.nodes.single.y, 120000);

      data = resizeNode(data, 'ferelden', const Size(10, 10));
      expect(data.nodes.single.width, minTileWidth);
      expect(data.nodes.single.height, minTileHeight);
      data = resizeNode(data, 'ferelden', const Size(400, 300));
      expect(data.nodes.single.rect.size, const Size(400, 300));
    });

    test('tile items are edited through Play widgets', () {
      final items = byId();
      var data = pinEntry(empty, 'ferelden', items);
      data = pinEntry(data, 'orlais', items);

      var widgets = nodeWidgets(data, items);
      expect(widgets.map((w) => w.id), ['ferelden', 'orlais']);
      expect(widgets.first.title, items['ferelden']!.name);

      widgets = addItem(widgets, 'ferelden', const PlayItem(type: 'counter', name: 'Rumors'));
      widgets = moveItem(widgets, 'ferelden', 0, 'orlais', 0);
      widgets = setWidgetStyle(widgets, 'orlais', 'tiles');
      data = applyNodeWidgets(data, widgets);

      expect(data.nodes.first.items, isEmpty);
      expect(data.nodes.last.items.single.name, 'Rumors');
      expect(data.nodes.last.style, 'tiles');
    });

    test('a tile of an entry that is gone is left out of the widgets', () {
      final items = byId();
      final data = pinEntry(empty, 'ferelden', items);
      expect(nodeWidgets(data, {}), isEmpty);
    });

    test('strings: one per pair, label can change, unpin removes them', () {
      final items = byId();
      var data = pinEntry(empty, 'ferelden', items);
      data = pinEntry(data, 'orlais', items);
      data = addString(data, id: '1', from: 'ferelden', to: 'orlais', label: 'enemies');
      data = addString(data, id: '2', from: 'orlais', to: 'ferelden', label: 'rivals');
      expect(data.strings.length, 1);
      expect(data.strings.single.label, 'rivals');

      expect(addString(data, id: '3', from: 'orlais', to: 'orlais').strings.length, 1);

      data = setStringLabel(data, '1', '');
      expect(data.strings.single.label, '');
      expect(removeString(data, '1').strings, isEmpty);
      expect(unpinEntry(data, 'orlais').strings, isEmpty);
      expect(unpinEntry(data, 'orlais').nodes.length, 1);
    });

    test('organize: no overlaps, tied tiles together, sizes and middle kept', () {
      var data = empty;
      for (final id in ['my-a', 'my-b', 'my-c']) {
        data = addMyEntry(
            data, MyLoreEntry(id: id, name: id, tags: const [], text: '', links: const []));
      }
      final items = byId(data);
      for (final id in ['my-a', 'my-b', 'my-c', 'orlais']) {
        data = pinEntry(data, id, items);
      }
      // Pile them up, make one bigger, tie a to c.
      data = data.copyWith(nodes: [
        for (final n in data.nodes) n.copyWith(x: 1000, y: 500),
      ]);
      data = resizeNode(data, 'orlais', const Size(400, 300));
      data = addString(data, id: '1', from: 'my-a', to: 'my-c');
      final sizes = data.nodes.map((n) => n.rect.size).toList();

      final tidy = organizeNodes(data, items);
      expect(anyOverlap(tidy.nodes), isFalse);
      expect(tidy.nodes.map((n) => n.rect.size).toList(), sizes);
      expect(tidy.nodes.map((n) => n.entryId), data.nodes.map((n) => n.entryId));

      Rect bounds(List<GraphNode> nodes) =>
          nodes.map((n) => n.rect).reduce((a, b) => a.expandToInclude(b));
      expect((bounds(tidy.nodes).center - bounds(data.nodes).center).distance, lessThan(1));

      GraphNode node(String id) => tidy.nodes.firstWhere((n) => n.entryId == id);
      // The tied pair is first, side by side; the others come after.
      expect(node('my-a').y, node('my-c').y);
      expect((node('my-a').x - node('my-c').x).abs(),
          lessThan(GraphNode.defaultTileWidth + 100));
      expect(node('my-b').y, greaterThan(node('my-a').y));
    });

    test('organize with no tiles changes nothing', () {
      expect(organizeNodes(empty, byId()).nodes, isEmpty);
    });

    test('a new tag gets an unused id and the next default color', () {
      final tags = allTags(rules.loreTags, empty);
      final (data, tag) = createTag(empty, tags, 'Rumors');
      expect(tags.map((t) => t.id), isNot(contains(tag.id)));
      expect(data.myTags.single.name, 'Rumors');
      expect(data.tagColors[tag.id], lorePalette[tags.length % lorePalette.length]);
      final (_, second) = createTag(data, allTags(rules.loreTags, data), 'Rumors');
      expect(second.id, isNot(tag.id));
    });

    test('deleting an own entry removes its node, strings and links to it', () {
      var data = addMyEntry(empty,
          const MyLoreEntry(id: 'my-a', name: 'A', tags: [], text: '', links: []));
      data = addMyEntry(data,
          const MyLoreEntry(id: 'my-b', name: 'B', tags: [], text: '', links: ['my-a']));
      data = setAddition(
          data, const LoreAddition(entryId: 'ferelden', tags: [], links: ['my-a']));
      final items = byId(data);
      data = pinEntry(data, 'my-a', items);
      data = pinEntry(data, 'my-b', items);
      data = addString(data, id: '1', from: 'my-a', to: 'my-b');

      data = removeMyEntry(data, 'my-a');
      expect(data.myEntries.map((e) => e.id), ['my-b']);
      expect(data.myEntries.single.links, isEmpty);
      expect(data.additions.single.links, isEmpty);
      expect(data.nodes.map((n) => n.entryId), ['my-b']);
      expect(data.strings, isEmpty);
    });
  });

  group('storage and import', () {
    test('LoreData survives a JSON round trip', () {
      var data = addMyEntry(empty,
          const MyLoreEntry(id: 'my-a', name: 'A', tags: ['place'], text: 't', links: ['orlais']));
      data = addTag(data, const LoreTag(id: 'tag-x', name: 'X'), 0xFF445566);
      data = addPaletteColor(data, 0xFF778899);
      data = setAddition(data,
          const LoreAddition(entryId: 'orlais', tags: ['event'], links: [], note: 'n'));
      data = pinEntry(data, 'orlais', byId(data));
      data = applyNodeWidgets(
          data,
          addItem(nodeWidgets(data, byId(data)), 'orlais',
              const PlayItem(type: 'checkbox', name: 'Seen', checked: true)));
      data = addString(data, id: '7', from: 'orlais', to: 'orlais');

      final copy = LoreData.fromJson(
          jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(copy.toJson()), jsonEncode(data.toJson()));
      expect(copy.myEntries.single.name, 'A');
      expect(copy.tagColors['tag-x'], 0xFF445566);
      expect(copy.nodes.single.entryId, 'orlais');
      expect(copy.nodes.single.items.single.checked, isTrue);
    });

    test('an old save without lore data reads as empty lists', () {
      final data = LoreData.fromJson(<String, dynamic>{});
      expect(data.myEntries, isEmpty);
      expect(data.nodes, isEmpty);
      expect(data.tagColors, isEmpty);
    });

    test('a node saved before tiles existed gets the default size', () {
      final node = GraphNode.fromJson(<String, dynamic>{'entryId': 'a', 'x': 1, 'y': 2});
      expect(node.width, GraphNode.defaultTileWidth);
      expect(node.height, GraphNode.defaultTileHeight);
      expect(node.style, 'list');
      expect(node.items, isEmpty);
    });

    test('import adds what is missing and keeps what is there', () {
      final mine = const LoreData.empty().copyWith(
        myEntries: [
          const MyLoreEntry(id: 'my-a', name: 'Mine', tags: [], text: '', links: []),
        ],
        tagColors: {'place': 1},
        additions: [
          const LoreAddition(entryId: 'orlais', tags: ['event'], links: [], note: 'mine'),
        ],
      );
      final theirs = const LoreData.empty().copyWith(
        myEntries: [
          const MyLoreEntry(id: 'my-a', name: 'Theirs', tags: [], text: '', links: []),
          const MyLoreEntry(id: 'my-b', name: 'New', tags: [], text: '', links: []),
        ],
        tagColors: {'place': 2, 'event': 3},
        additions: [
          const LoreAddition(entryId: 'orlais', tags: ['place'], links: [], note: 'theirs'),
          const LoreAddition(entryId: 'ferelden', tags: [], links: [], note: 'new'),
        ],
        palette: [0xFF000001],
      );

      final merged = mergeLore(mine, theirs);
      expect(merged.myEntries.map((e) => e.name), ['Mine', 'New']);
      expect(merged.tagColors, {'place': 1, 'event': 3});
      expect(merged.palette, [0xFF000001]);

      final orlais = merged.additions.firstWhere((a) => a.entryId == 'orlais');
      expect(orlais.tags, ['event', 'place']);
      expect(orlais.note, 'mine');
      expect(merged.additions.any((a) => a.entryId == 'ferelden'), isTrue);
    });
  });
}
