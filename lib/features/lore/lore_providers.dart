import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../character/lore_data.dart';
import '../../character/providers.dart';
import '../../rules/models/lore.dart';
import '../../rules/rules_data.dart';
import '../../shared/name_linker.dart';
import '../glossary/glossary_history.dart';

/// The two views of the Lore tab.
enum LoreMode { codex, graph }

final loreModeProvider = StateProvider<LoreMode>((ref) => LoreMode.codex);

/// True while the graph's tiles are being edited (the pencil in the app bar).
final loreEditingProvider = StateProvider<bool>((ref) => false);

/// Back / forward history of the Codex (same class as the Glossary's: a stack
/// of entry keys, null = the list).
final loreHistoryProvider =
    StateProvider<GlossaryHistory>((ref) => const GlossaryHistory());

/// Everything the Lore screens need, built from the rules and the selected
/// character's [LoreData]. Immutable: a change builds a new one.
class LoreContext {
  LoreContext(this.rules, this.data);

  final RulesData rules;
  final LoreData data;

  late final List<LoreItem> items = buildLoreItems(rules.loreEntries, data);
  late final Map<String, LoreItem> byId = {for (final i in items) i.id: i};
  late final List<LoreTag> tags = allTags(rules.loreTags, data);
  late final Map<String, int> tagColors = tagColorMap(tags, data);
  late final NameLinker linker = NameLinker(loreNameMap(items));
  late final Set<String> pinned = {for (final n in data.nodes) n.entryId};

  Color colorOf(String tagId) => Color(tagColors[tagId] ?? 0xFF90A4AE);

  String tagName(String tagId) =>
      tags.where((t) => t.id == tagId).firstOrNull?.name ?? tagId;

  /// The book's own version of an entry (without the player's additions).
  LoreEntry? bookEntry(String id) =>
      rules.loreEntries.where((e) => e.id == id).firstOrNull;

  bool isBookTag(String tagId) => rules.loreTags.any((t) => t.id == tagId);
}

/// The lore of the selected character; null while loading or without one.
/// Rebuilt only when the rules, the character or its lore change.
final loreProvider = Provider<LoreContext?>((ref) {
  final rules = ref.watch(rulesProvider).valueOrNull;
  final (id, data) = ref.watch(selectedCharacterProvider
      .select((c) => (c.valueOrNull?.id, c.valueOrNull?.lore)));
  if (rules == null || id == null) return null;
  return LoreContext(rules, data ?? const LoreData.empty());
});

/// Saves [data] as the selected character's lore.
Future<void> saveLore(WidgetRef ref, LoreData data) async {
  final character = ref.read(selectedCharacterProvider).valueOrNull;
  if (character == null) return;
  await ref
      .read(charactersProvider.notifier)
      .save(character.copyWith(lore: data));
}

/// Shows an entry in the Codex (switches to it and adds it to the history).
void openInCodex(WidgetRef ref, String id) {
  ref.read(loreModeProvider.notifier).state = LoreMode.codex;
  ref.read(loreHistoryProvider.notifier).update((h) => h.open(id));
}
