import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../rules/custom_background_storage.dart';
import '../../rules/models/backgrounds.dart';

/// The saved custom backgrounds. Every change is written to the file at once.
class CustomBackgroundsNotifier extends AsyncNotifier<List<Background>> {
  late CustomBackgroundStorage _storage;

  @override
  Future<List<Background>> build() async {
    final documents = await getApplicationDocumentsDirectory();
    _storage = CustomBackgroundStorage(
        File(p.join(documents.path, 'custom_backgrounds.json')));
    return _storage.load();
  }

  Future<void> add(Background background) =>
      _write([...state.requireValue, background]);

  Future<void> remove(String id) =>
      _write([for (final b in state.requireValue) if (b.id != id) b]);

  Future<void> _write(List<Background> backgrounds) async {
    await _storage.save(backgrounds);
    state = AsyncData(backgrounds);
  }
}

final customBackgroundsProvider =
    AsyncNotifierProvider<CustomBackgroundsNotifier, List<Background>>(
  CustomBackgroundsNotifier.new,
);
