import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../character/providers.dart';
import '../../rules/custom_spell_storage.dart';
import '../../rules/models/spell.dart';

/// The player's homebrew spells. Every change is written to the file at once.
class CustomSpellsNotifier extends AsyncNotifier<List<Spell>> {
  late CustomSpellStorage _storage;

  @override
  Future<List<Spell>> build() async {
    final documents = await getApplicationDocumentsDirectory();
    _storage =
        CustomSpellStorage(File(p.join(documents.path, 'custom_spells.json')));
    return _storage.load();
  }

  Future<void> add(Spell spell) => _write([...state.requireValue, spell]);

  Future<void> remove(String id) =>
      _write([for (final s in state.requireValue) if (s.id != id) s]);

  Future<void> _write(List<Spell> spells) async {
    await _storage.save(spells);
    state = AsyncData(spells);
  }
}

final customSpellsProvider =
    AsyncNotifierProvider<CustomSpellsNotifier, List<Spell>>(
  CustomSpellsNotifier.new,
);

/// The book's spells followed by the player's homebrew spells.
final allSpellsProvider = Provider<List<Spell>>((ref) {
  final book = ref.watch(rulesProvider).valueOrNull?.spells ?? const <Spell>[];
  final custom = ref.watch(customSpellsProvider).valueOrNull ?? const <Spell>[];
  return [...book, ...custom];
});
