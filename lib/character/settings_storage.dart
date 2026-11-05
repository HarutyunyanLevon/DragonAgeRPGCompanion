import 'dart:convert';
import 'dart:io';

/// App settings kept in one small JSON file: which character was selected
/// last and which theme the player picked. Saving one value keeps the others.
class SettingsStorage {
  SettingsStorage(this.file);

  final File file;

  static const _selectedKey = 'selectedCharacterId';
  static const _themeKey = 'themeId';

  Future<String?> loadSelectedId() async =>
      (await _read())[_selectedKey] as String?;

  Future<void> saveSelectedId(String? id) => _write(_selectedKey, id);

  Future<String?> loadThemeId() async => (await _read())[_themeKey] as String?;

  Future<void> saveThemeId(String id) => _write(_themeKey, id);

  Future<Map<String, dynamic>> _read() async {
    if (!await file.exists()) return {};
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  /// Changes one value and keeps the rest of the file.
  Future<void> _write(String key, Object? value) async {
    final json = await _read();
    json[key] = value;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(json));
  }
}
