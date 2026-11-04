import 'dart:io';

import 'json_list_storage.dart';
import 'models/spell.dart';

/// The player's homebrew spells, kept in one JSON file (a plain list).
/// Characters refer to them by id, like book spells.
class CustomSpellStorage extends JsonListStorage<Spell> {
  CustomSpellStorage(File file)
      : super(file, fromJson: Spell.fromJson, toJson: (s) => s.toJson());
}
