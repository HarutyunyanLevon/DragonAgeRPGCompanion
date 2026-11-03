import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../rules/rules_data.dart';
import '../rules/rules_loader.dart';
import 'character_storage.dart';

/// The rulebook data, loaded once at startup.
final rulesProvider = FutureProvider<RulesData>(
  (ref) => RulesLoader(rootBundle.loadString).load(),
);

/// Where character files live (app documents folder / characters).
final characterStorageProvider = FutureProvider<CharacterStorage>((ref) async {
  final documents = await getApplicationDocumentsDirectory();
  return CharacterStorage(Directory(p.join(documents.path, 'characters')));
});
