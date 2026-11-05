import 'dart:io';

import 'package:dragon_age_companion/character/settings_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late SettingsStorage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('settings_test');
    storage = SettingsStorage(File('${dir.path}/data/settings.json'));
  });

  tearDown(() async => dir.delete(recursive: true));

  test('loads nothing before the first save', () async {
    expect(await storage.loadSelectedId(), isNull);
    expect(await storage.loadThemeId(), isNull);
  });

  test('saving the theme keeps the selected character', () async {
    await storage.saveSelectedId('abc');
    await storage.saveThemeId('chantry');

    expect(await storage.loadSelectedId(), 'abc');
    expect(await storage.loadThemeId(), 'chantry');
  });

  test('saving the selected character keeps the theme', () async {
    await storage.saveThemeId('warrior');
    await storage.saveSelectedId('xyz');

    expect(await storage.loadThemeId(), 'warrior');
    expect(await storage.loadSelectedId(), 'xyz');
  });
}
