import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/confirm_dialog.dart';

/// Saved Play layouts: save the current one under a name, load, rename or
/// delete a saved one. The sheet closes after every action; the caller does
/// the change.
Future<void> showLayoutsSheet(
  BuildContext context, {
  required List<PlayPreset> presets,
  required void Function(String name) onSave,
  required void Function(PlayPreset preset) onLoad,
  required void Function(PlayPreset preset, String newName) onRename,
  required void Function(PlayPreset preset) onDelete,
}) {
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      // Closes the sheet, then asks (if needed) and acts.
      Future<void> run(Future<void> Function() action) async {
        Navigator.pop(sheetContext);
        await action();
      }

      return ListView(shrinkWrap: true, children: [
        ListTile(
          leading: const Icon(Icons.save_outlined),
          title: Text(l10n.saveLayoutAs),
          onTap: () => run(() async {
            final name = await _askName(context, l10n.saveLayoutAs, '');
            if (name != null) onSave(name);
          }),
        ),
        const Divider(height: 1),
        if (presets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noSavedLayouts),
          ),
        for (final preset in presets)
          ListTile(
            title: Text(preset.name),
            onTap: () => run(() async {
              final ok = await confirm(context,
                  title: l10n.loadLayoutTitle(preset.name),
                  body: l10n.loadLayoutBody,
                  confirmLabel: l10n.loadLayout);
              if (ok) onLoad(preset);
            }),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: l10n.rename,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => run(() async {
                  final name =
                      await _askName(context, l10n.rename, preset.name);
                  if (name != null) onRename(preset, name);
                }),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => run(() async {
                  final ok = await confirm(context,
                      title: l10n.deleteLayoutTitle(preset.name),
                      confirmLabel: l10n.delete);
                  if (ok) onDelete(preset);
                }),
              ),
            ]),
          ),
      ]);
    },
  );
}

/// Asks for a name. Null when cancelled or empty.
Future<String?> _askName(BuildContext context, String title, String initial) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
            labelText: l10n.layoutName, helperText: l10n.layoutNameHelp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim();
            Navigator.pop(dialogContext, name.isEmpty ? null : name);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}
