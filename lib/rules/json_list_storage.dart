import 'dart:convert';
import 'dart:io';

/// A list of things kept in one JSON file (a plain list). The custom
/// backgrounds and the custom spells are stored this way.
class JsonListStorage<T> {
  JsonListStorage(
    this.file, {
    required this.fromJson,
    required this.toJson,
  });

  final File file;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;

  Future<List<T>> load() async {
    if (!await file.exists()) return [];
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return [for (final json in list) fromJson(json as Map<String, dynamic>)];
  }

  Future<void> save(List<T> items) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert([for (final i in items) toJson(i)]));
  }
}
