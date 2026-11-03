import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../rules/rules_data.dart';
import '../rules/rules_loader.dart';
import 'character.dart';
import 'character_library.dart';
import 'character_storage.dart';
import 'settings_storage.dart';

/// The rulebook data, loaded once at startup.
final rulesProvider = FutureProvider<RulesData>(
  (ref) => RulesLoader(rootBundle.loadString).load(),
);

/// The app documents folder. Character files and settings live inside it.
final _documentsProvider = FutureProvider<Directory>(
  (ref) => getApplicationDocumentsDirectory(),
);

/// Where character files live (app documents folder / characters).
final characterStorageProvider = FutureProvider<CharacterStorage>((ref) async {
  final documents = await ref.watch(_documentsProvider.future);
  return CharacterStorage(Directory(p.join(documents.path, 'characters')));
});

final _settingsStorageProvider = FutureProvider<SettingsStorage>((ref) async {
  final documents = await ref.watch(_documentsProvider.future);
  return SettingsStorage(File(p.join(documents.path, 'settings.json')));
});

/// Every saved character and which one is selected. All changes go through
/// this notifier: it writes the file first, then updates the state.
class CharactersNotifier extends AsyncNotifier<CharacterLibrary> {
  late CharacterStorage _characters;
  late SettingsStorage _settings;

  @override
  Future<CharacterLibrary> build() async {
    _characters = await ref.watch(characterStorageProvider.future);
    _settings = await ref.watch(_settingsStorageProvider.future);
    return CharacterLibrary(
      await _characters.loadAll(),
      preferredId: await _settings.loadSelectedId(),
    );
  }

  /// Saves a new character and selects it.
  Future<void> add(Character character) async {
    await _characters.save(character);
    await _show([...state.requireValue.characters, character], character.id);
  }

  Future<void> select(String id) =>
      _show(state.requireValue.characters, id);

  /// Saves a changed character (same id). The selection stays.
  Future<void> save(Character character) async {
    final library = state.requireValue;
    await _characters.save(character);
    await _show([
      for (final c in library.characters) c.id == character.id ? character : c,
    ], library.selectedId);
  }

  /// Deletes a character. If it was selected, the newest one takes over.
  Future<void> delete(String id) async {
    final library = state.requireValue;
    await _characters.delete(id);
    await _show([
      for (final c in library.characters)
        if (c.id != id) c,
    ], library.selectedId);
  }

  Future<void> _show(List<Character> characters, String? preferredId) async {
    final library = CharacterLibrary(characters, preferredId: preferredId);
    await _settings.saveSelectedId(library.selectedId);
    state = AsyncData(library);
  }
}

final charactersProvider =
    AsyncNotifierProvider<CharactersNotifier, CharacterLibrary>(
  CharactersNotifier.new,
);

/// The selected character, or null when there are none.
final selectedCharacterProvider = Provider<AsyncValue<Character?>>(
  (ref) => ref.watch(charactersProvider).whenData((library) => library.selected),
);
