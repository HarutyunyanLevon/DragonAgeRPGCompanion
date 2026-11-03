import 'dart:convert';
import 'dart:io';

/// App settings kept in one small JSON file. For now it holds a single
/// value: which character was selected last.
class SettingsStorage {
  SettingsStorage(this.file);

  final File file;

  static const _selectedKey = 'selectedCharacterId';

  Future<String?> loadSelectedId() async {
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return json[_selectedKey] as String?;
  }

  Future<void> saveSelectedId(String? id) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({_selectedKey: id}));
  }
}
