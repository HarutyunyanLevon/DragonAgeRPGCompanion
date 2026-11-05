import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

// The only file that talks to the file_picker package. If an update of the
// package renames something, this is the one place to fix.

/// Asks where to save and writes [text] there. False when cancelled.
Future<bool> saveTextFile(String fileName, String text) async {
  final saved = await FilePicker.saveFile(
    fileName: fileName,
    bytes: Uint8List.fromList(utf8.encode(text)),
  );
  return saved != null;
}

/// Asks for a file and returns its text; null when cancelled.
Future<String?> pickTextFile() async {
  final file = await FilePicker.pickFile();
  if (file == null) return null;
  return utf8.decode(await file.readAsBytes());
}
