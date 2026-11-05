import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/providers.dart';
import 'theme_specs.dart';

/// The theme the player picked. Loaded from settings.json at startup and
/// saved there on every change.
class ThemeIdNotifier extends AsyncNotifier<AppThemeId> {
  @override
  Future<AppThemeId> build() async {
    final settings = await ref.watch(settingsStorageProvider.future);
    return AppThemeId.fromName(await settings.loadThemeId());
  }

  Future<void> select(AppThemeId id) async {
    final settings = await ref.read(settingsStorageProvider.future);
    await settings.saveThemeId(id.name);
    state = AsyncData(id);
  }
}

final themeIdProvider =
    AsyncNotifierProvider<ThemeIdNotifier, AppThemeId>(ThemeIdNotifier.new);
