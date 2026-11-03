import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../rules/models/classes.dart';
import 'character_draft.dart';

/// Class choice. Classes the background does not allow are dimmed; tapping one
/// asks for confirmation (strict rules, but the player has the last word).
class ClassPicker extends ConsumerWidget {
  const ClassPicker({super.key, required this.background});

  final Background background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(rulesProvider).requireValue.classes.classes;
    final selected = ref.watch(characterDraftProvider).classId;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final c in classes)
          Opacity(
            opacity: background.classes.contains(c.id) ? 1 : 0.4,
            child: ChoiceChip(
              label: Text(c.name),
              selected: selected == c.id,
              onSelected: (_) => _pick(context, ref, c),
            ),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, ClassRules c) async {
    final notifier = ref.read(characterDraftProvider.notifier);
    if (background.classes.contains(c.id) || await _confirm(context, c)) {
      notifier.setClass(c.id);
    }
  }

  Future<bool> _confirm(BuildContext context, ClassRules c) async {
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.classNotAllowedTitle),
        content: Text(l10n.classNotAllowedBody(background.name, c.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.proceedAnyway),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }
}
