import 'dart:convert';
import 'dart:io';

import 'models/backgrounds.dart';

/// The player's custom backgrounds, kept in one JSON file (a plain list).
/// Characters refer to them by id.
class CustomBackgroundStorage {
  CustomBackgroundStorage(this.file);

  final File file;

  Future<List<Background>> load() async {
    if (!await file.exists()) return [];
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return [
      for (final json in list) Background.fromJson(json as Map<String, dynamic>)
    ];
  }

  Future<void> save(List<Background> backgrounds) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
        encoder.convert([for (final b in backgrounds) b.toJson()]));
  }
}
