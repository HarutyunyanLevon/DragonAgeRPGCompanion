import 'dart:io';

import 'package:dragon_age_companion/features/glossary/glossary_entries.dart';
import 'package:dragon_age_companion/features/glossary/glossary_extras.dart';
import 'package:dragon_age_companion/features/glossary/glossary_history.dart';
import 'package:dragon_age_companion/features/glossary/glossary_links.dart';
import 'package:dragon_age_companion/features/sheet/sheet_filter.dart';
import 'package:dragon_age_companion/rules/glossary_note_storage.dart';
import 'package:dragon_age_companion/rules/models/glossary.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader((path) => File(path).readAsString()).load();
  });

  group('glossary.json', () {
    test('every term has a topic, a name and a text', () {
      expect(rules.glossaryTerms, isNotEmpty);
      for (final term in rules.glossaryTerms) {
        expect(term.topic, isNotEmpty, reason: term.name);
        expect(term.name, isNotEmpty);
        expect(term.text, isNotEmpty, reason: term.name);
      }
    });

    test('term ids are unique', () {
      final ids = rules.glossaryTerms.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every "extra" names a table the app can build', () {
      for (final term in rules.glossaryTerms) {
        if (term.extra == null) continue;
        expect(glossaryExtras.containsKey(term.extra), isTrue,
            reason: '${term.name}: ${term.extra}');
      }
    });
  });

  group('buildGlossary', () {
    const note = GlossaryNote(
        id: '1', title: 'House rule', text: 'Re-roll a natural 3 once.');

    List<GlossaryEntry> build() =>
        buildGlossary(rules: rules, spells: rules.spells, notes: [note]);

    test('has entries of every category', () {
      final categories = build().map((e) => e.category).toSet();
      expect(categories, GlossaryCategory.values.toSet());
    });

    test('has the three classes and all weapon groups', () {
      final entries = build();
      expect(
          entries.where((e) => e.category == GlossaryCategory.classes).length, 3);
      expect(
          entries
              .where((e) => e.category == GlossaryCategory.weaponGroups)
              .length,
          rules.weaponGroups.length);
    });

    test('search finds terms by name and by description text', () {
      final entries = build();
      List<String> find(String query) => [
            for (final e in entries)
              if (SheetFilter(query).matches(e.searchTexts)) e.title
          ];

      expect(find('dragon die'), contains('Dragon Die'));
      expect(find('re-roll a natural'), ['House rule']);
      expect(find('no such text anywhere'), isEmpty);
    });
  });

  group('GlossaryLinker', () {
    late GlossaryLinker linker;
    late List<GlossaryEntry> entries;

    setUpAll(() {
      entries = buildGlossary(rules: rules, spells: rules.spells, notes: []);
      linker = GlossaryLinker(entries);
    });

    String keyOf(String title) => entries.firstWhere((e) => e.title == title).key;

    /// The linked pieces of [text].
    List<String> linked(String text, {String? selfKey}) => [
          for (final m in linker.find(text, selfKey: selfKey))
            text.substring(m.start, m.end)
        ];

    test('links names, aliases and plurals, ignoring case', () {
      expect(linked('A warrior rolls a TN and the Dragon Die.'),
          ['warrior', 'TN', 'Dragon Die']);
      expect(linked('Three classes exist.'), ['classes']);
    });

    test('only the first mention of an entry is a link', () {
      expect(linked('Strength, Dexterity and Strength again.'),
          ['Strength', 'Dexterity']);
    });

    test('an entry does not link to itself', () {
      expect(linked('The Dragon Die is special.', selfKey: keyOf('Dragon Die')),
          isEmpty);
    });

    test('everyday words marked autoLink: false are not links', () {
      expect(linked('You move, run and charge.'), isEmpty);
    });

    test('the longest name wins and links lead to the right entry', () {
      final matches = linker.find('Spend Mana points to cast.');
      expect(matches.single.target, keyOf('Mana points (MP)'));
    });
  });

  group('GlossaryHistory', () {
    test('starts on the list and goes back and forward like a browser', () {
      var history = const GlossaryHistory();
      expect(history.current, isNull);
      expect(history.canGoBack, isFalse);

      history = history.open('a').open('b');
      expect(history.current, 'b');

      history = history.back();
      expect(history.current, 'a');
      expect(history.canGoForward, isTrue);

      history = history.forward();
      expect(history.current, 'b');
      expect(history.canGoForward, isFalse);
    });

    test('opening something new drops the forward entries', () {
      var history = const GlossaryHistory().open('a').open('b').back();
      history = history.open('c');

      expect(history.canGoForward, isFalse);
      expect(history.back().current, 'a');
    });

    test('opening the entry that is already open changes nothing', () {
      final history = const GlossaryHistory().open('a');
      expect(history.open('a').stack.length, 2);
    });
  });

  group('GlossaryNoteStorage', () {
    late Directory dir;
    late GlossaryNoteStorage storage;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('glossary_notes_test');
      storage = GlossaryNoteStorage(File('${dir.path}/data/notes.json'));
    });

    tearDown(() async => dir.delete(recursive: true));

    test('loads nothing before the first save', () async {
      expect(await storage.load(), isEmpty);
    });

    test('saved notes come back, and a note can be changed', () async {
      const note = GlossaryNote(id: '7', title: 'Ruling', text: 'Old text');
      await storage.save([note, note.copyWith(title: 'Other')]);

      final loaded = await storage.load();
      expect(loaded.map((n) => n.title), ['Ruling', 'Other']);
      expect(loaded.first.text, 'Old text');
      expect(note.copyWith(text: 'New').id, '7');
    });
  });
}
