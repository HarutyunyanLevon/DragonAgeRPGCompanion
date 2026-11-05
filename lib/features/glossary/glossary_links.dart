import '../../shared/name_linker.dart';
import 'glossary_entries.dart';

/// Finds the words in a text that name a Glossary entry (rules in
/// [NameLinker]). The first entry with a name keeps it (terms come first).
class GlossaryLinker extends NameLinker {
  GlossaryLinker(List<GlossaryEntry> entries) : super(_namesOf(entries));

  static Map<String, String> _namesOf(List<GlossaryEntry> entries) {
    final keyByName = <String, String>{};
    for (final entry in entries) {
      for (final name in entry.linkNames) {
        keyByName.putIfAbsent(name.toLowerCase(), () => entry.key);
      }
    }
    return keyByName;
  }
}
