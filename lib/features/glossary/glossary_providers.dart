import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../spells/custom_spells.dart';
import 'glossary_entries.dart';
import 'glossary_history.dart';
import 'glossary_links.dart';
import 'glossary_notes.dart';

/// Every Glossary entry. Built again only when the rules, the spells or the
/// notes change.
final glossaryEntriesProvider = Provider<List<GlossaryEntry>>((ref) {
  final rules = ref.watch(rulesProvider).valueOrNull;
  if (rules == null) return const [];
  return buildGlossary(
    rules: rules,
    spells: ref.watch(allSpellsProvider),
    notes: ref.watch(glossaryNotesProvider).valueOrNull ?? const [],
  );
});

final glossaryLinkerProvider = Provider<GlossaryLinker>(
  (ref) => GlossaryLinker(ref.watch(glossaryEntriesProvider)),
);

/// The back / forward history. It lives as long as the app runs.
class GlossaryHistoryNotifier extends Notifier<GlossaryHistory> {
  @override
  GlossaryHistory build() => const GlossaryHistory();

  void open(String? key) => state = state.open(key);
  void back() => state = state.back();
  void forward() => state = state.forward();
}

final glossaryHistoryProvider =
    NotifierProvider<GlossaryHistoryNotifier, GlossaryHistory>(
  GlossaryHistoryNotifier.new,
);
