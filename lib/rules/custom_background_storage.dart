import 'dart:io';

import 'json_list_storage.dart';
import 'models/backgrounds.dart';

/// The player's custom backgrounds, kept in one JSON file (a plain list).
/// Characters refer to them by id.
class CustomBackgroundStorage extends JsonListStorage<Background> {
  CustomBackgroundStorage(File file)
      : super(file, fromJson: Background.fromJson, toJson: (b) => b.toJson());
}
