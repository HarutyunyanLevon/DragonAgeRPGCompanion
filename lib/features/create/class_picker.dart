import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart';
import '../../rules/models/classes.dart';
import '../../shared/confirm_dialog.dart';
import 'character_draft.dart';
import 'rule_info.dart';

/// Class choice. Classes the background does not allow are dimmed; tapping one
/// asks for confirmation (strict rules, but the player has the last word).
class ClassPicker extends ConsumerWidget {
  const ClassPicker({super.key, required this.background});

  final Background background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider).requireValue;
    final selected = ref.watch(characterDraftProvider).classId;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final c in rules.classes.classes)
            Opacity(
              opacity: background.classes.contains(c.id) ? 1 : 0.4,
              child: ChoiceChip(
                label: Text(c.name),
                selected: selected == c.id,
                onSelected: (_) => _pick(context, ref, c),
              ),
            ),
        ],
      ),
      // Description of the chosen class.
      if (selected != null)
        Card(
          margin: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClassInfo(
                rules: rules, classRules: rules.classes.classById(selected)),
          ),
        ),
    ]);
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, ClassRules c) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(characterDraftProvider.notifier);
    if (background.classes.contains(c.id) ||
        await confirm(
          context,
          title: l10n.classNotAllowedTitle,
          body: l10n.classNotAllowedBody(background.name, c.name),
          confirmLabel: l10n.proceedAnyway,
        )) {
      notifier.setClass(c.id);
    }
  }
}
