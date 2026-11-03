import 'character.dart';

/// All saved characters plus the one that is selected. Immutable; the
/// notifier in providers.dart makes a new one after every change.
class CharacterLibrary {
  /// [characters] are sorted by name. The selected character is
  /// [preferredId] if it exists, otherwise the newest character.
  CharacterLibrary(List<Character> characters, {String? preferredId})
      : characters = ([...characters]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))),
        selectedId = _pick(characters, preferredId);

  final List<Character> characters;
  final String? selectedId;

  Character? get selected {
    for (final character in characters) {
      if (character.id == selectedId) return character;
    }
    return null;
  }

  static String? _pick(List<Character> characters, String? preferredId) {
    if (characters.any((c) => c.id == preferredId)) return preferredId;
    if (characters.isEmpty) return null;
    // Ids are creation times, so the highest id is the newest character.
    return characters
        .map((c) => c.id)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
  }
}
