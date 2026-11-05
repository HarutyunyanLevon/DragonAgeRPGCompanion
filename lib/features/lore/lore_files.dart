import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/lore.dart';
import '../../character/lore_data.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/slug.dart';
import '../../shared/file_dialogs.dart';
import 'lore_providers.dart';

/// Saves the selected character's lore (own entries, tags, graph) as a JSON
/// file the player can keep or give to another character.
Future<void> exportLore(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final lore = ref.read(loreProvider);
  final name = ref.read(selectedCharacterProvider).valueOrNull?.name ?? 'lore';
  if (lore == null) return;

  final text = const JsonEncoder.withIndent('  ').convert(lore.data.toJson());
  final saved = await saveTextFile('lore-${slug(name)}.json', text);
  if (saved) messenger.showSnackBar(SnackBar(content: Text(l10n.loreExported)));
}

/// Reads a lore file and adds what it has to the selected character's lore.
/// Entries, tags, nodes and strings that are already there stay as they are.
Future<void> importLore(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final lore = ref.read(loreProvider);
  if (lore == null) return;

  final text = await pickTextFile();
  if (text == null) return;

  try {
    final imported = LoreData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    await saveLore(ref, mergeLore(lore.data, imported));
    messenger.showSnackBar(SnackBar(content: Text(l10n.loreImported)));
  } on Object {
    // Not JSON, or not a lore file.
    messenger.showSnackBar(SnackBar(content: Text(l10n.loreImportFailed)));
  }
}
