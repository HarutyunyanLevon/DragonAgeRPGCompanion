import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../rules/glossary_note_storage.dart';
import '../../rules/models/glossary.dart';

/// The player's glossary notes. Every change is written to the file at once.
class GlossaryNotesNotifier extends AsyncNotifier<List<GlossaryNote>> {
  late GlossaryNoteStorage _storage;

  @override
  Future<List<GlossaryNote>> build() async {
    final documents = await getApplicationDocumentsDirectory();
    _storage = GlossaryNoteStorage(
        File(p.join(documents.path, 'glossary_notes.json')));
    return _storage.load();
  }

  Future<void> add(String title, String text) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return _write(
        [...state.requireValue, GlossaryNote(id: id, title: title, text: text)]);
  }

  /// Replaces the note with the same id. (Not called "update": Riverpod's
  /// AsyncNotifier already has a method of that name.)
  Future<void> replace(GlossaryNote note) => _write([
        for (final n in state.requireValue) n.id == note.id ? note : n,
      ]);

  Future<void> remove(String id) =>
      _write([for (final n in state.requireValue) if (n.id != id) n]);

  Future<void> _write(List<GlossaryNote> notes) async {
    await _storage.save(notes);
    state = AsyncData(notes);
  }
}

final glossaryNotesProvider =
    AsyncNotifierProvider<GlossaryNotesNotifier, List<GlossaryNote>>(
  GlossaryNotesNotifier.new,
);
