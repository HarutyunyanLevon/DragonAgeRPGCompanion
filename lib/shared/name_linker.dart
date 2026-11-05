import 'linked_text.dart';

/// Finds the words in a text that name something else (a Glossary entry, a
/// lore entry...). Used by the Glossary and the Lore tab.
///
/// Rules, to keep the text readable:
///  - whole words only, ignoring upper / lower case, with an optional plural "s";
///  - the longest name wins ("Mana points" before "Mana");
///  - only the first mention of a thing in one text is a link;
///  - a text never links to the thing it belongs to.
class NameLinker {
  /// [keyByName] maps a lower-case name to the key of what it names.
  NameLinker(this._keyByName) {
    final names = _keyByName.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (names.isNotEmpty) {
      final alternatives = names.map(RegExp.escape).join('|');
      _pattern = RegExp(
        '(?<![A-Za-z0-9])($alternatives)s?(?![A-Za-z0-9])',
        caseSensitive: false,
      );
    }
  }

  final Map<String, String> _keyByName;
  RegExp? _pattern;

  /// The links in [text]. [selfKey] is the key of the thing the text belongs
  /// to, if any.
  List<LinkMatch> find(String text, {String? selfKey}) {
    final pattern = _pattern;
    if (pattern == null) return const [];

    final linked = <String>{};
    final result = <LinkMatch>[];
    for (final match in pattern.allMatches(text)) {
      final key = _keyByName[match.group(1)!.toLowerCase()];
      if (key == null || key == selfKey || !linked.add(key)) continue;
      result.add(LinkMatch(match.start, match.end, key));
    }
    return result;
  }
}
