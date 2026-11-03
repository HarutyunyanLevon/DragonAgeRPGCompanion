import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'character.dart';

/// One JSON file per character inside [directory]. Nothing else in the app
/// touches these files. Export and import are plain file copies.
class CharacterStorage {
  CharacterStorage(this.directory);

  final Directory directory;

  File _file(String id) => File(p.join(directory.path, '$id.json'));

  Future<List<Character>> loadAll() async {
    if (!await directory.exists()) return [];
    final characters = <Character>[];
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        characters.add(await _read(entity));
      }
    }
    characters.sort((a, b) => a.name.compareTo(b.name));
    return characters;
  }

  Future<Character> load(String id) => _read(_file(id));

  Future<void> save(Character character) async {
    await directory.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await _file(character.id).writeAsString(encoder.convert(character.toJson()));
  }

  Future<void> delete(String id) async {
    final file = _file(id);
    if (await file.exists()) await file.delete();
  }

  /// Copies a character file to [destination] (for sharing or backup).
  Future<void> exportTo(String id, File destination) async {
    await _file(id).copy(destination.path);
  }

  /// Reads a character file from [source], stores it, returns it.
  Future<Character> importFrom(File source) async {
    final character = await _read(source);
    await save(character);
    return character;
  }

  Future<Character> _read(File file) async {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return Character.fromJson(json);
  }
}
