import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/level_up.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/confirm_dialog.dart';
import 'level_up_page.dart';
import 'owed_gains.dart';

/// Under the Sheet's header: experience (tap to edit), the Level up and Undo
/// buttons, and the gains that are still owed.
class LevelUpBar extends ConsumerWidget {
  const LevelUpBar({super.key, required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  Future<void> _levelUp(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final needed = rules.classes.xpForLevel(character.level + 1);

    // Strict rules: too little experience asks "Proceed anyway?".
    if (character.xp < needed) {
      final ok = await confirm(
        context,
        title: l10n.notEnoughXpTitle,
        body: l10n.notEnoughXpBody(character.xp, character.level + 1, needed),
        confirmLabel: l10n.proceedAnyway,
      );
      if (!ok || !context.mounted) return;
    }
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => LevelUpPage(
        character: character,
        rules: rules,
        onFinish: (leveledUp) async {
          await ref.read(charactersProvider.notifier).save(leveledUp);
          navigator.pop();
        },
      ),
    ));
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      title: l10n.undoLevelUpTitle(character.level),
      body: l10n.undoLevelUpBody,
      confirmLabel: l10n.undo,
    );
    if (!ok) return;
    await ref.read(charactersProvider.notifier).save(undoLevelUp(character));
  }

  Future<void> _editXp(BuildContext context, WidgetRef ref) async {
    final xp = await showDialog<int>(
      context: context,
      builder: (_) => _XpDialog(xp: character.xp),
    );
    if (xp == null) return;
    await ref.read(charactersProvider.notifier).save(character.copyWith(xp: xp));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final atCap = character.level >= maxLevel;
    final enoughXp = hasXpForNextLevel(character, rules.classes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(atCap
                ? l10n.experience(character.xp)
                : l10n.experienceNext(character.xp,
                    rules.classes.xpForLevel(character.level + 1), character.level + 1)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editExperience,
            onPressed: () => _editXp(context, ref),
          ),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (atCap)
            Text(l10n.levelCapNote)
          else if (enoughXp)
            FilledButton.icon(
              icon: const Icon(Icons.arrow_upward),
              label: Text(l10n.levelUpTo(character.level + 1)),
              onPressed: () => _levelUp(context, ref),
            )
          else
            FilledButton.tonalIcon(
              icon: const Icon(Icons.arrow_upward),
              label: Text(l10n.levelUpTo(character.level + 1)),
              onPressed: () => _levelUp(context, ref),
            ),
          if (character.levelUpUndo != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.undo),
              label: Text(l10n.undoLevelUp),
              onPressed: () => _undo(context, ref),
            ),
        ]),
        OwedGains(character: character, rules: rules),
      ]),
    );
  }
}

/// Edit the total experience.
class _XpDialog extends StatefulWidget {
  const _XpDialog({required this.xp});

  final int xp;

  @override
  State<_XpDialog> createState() => _XpDialogState();
}

class _XpDialogState extends State<_XpDialog> {
  late final _controller = TextEditingController(text: '${widget.xp}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final xp = int.tryParse(_controller.text.trim());

    return AlertDialog(
      title: Text(l10n.editExperience),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l10n.totalExperience),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: xp == null || xp < 0 ? null : () => Navigator.pop(context, xp),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
