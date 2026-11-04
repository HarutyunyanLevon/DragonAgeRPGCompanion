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

/// Under the Sheet's header: experience and the gains that are still owed.
/// The pencil opens a dialog with the experience field and the Level up and
/// Undo buttons.
class LevelUpBar extends ConsumerWidget {
  const LevelUpBar({super.key, required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  Future<void> _levelUp(BuildContext context, WidgetRef ref, Character character) async {
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

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_XpResult>(
      context: context,
      builder: (_) => _XpDialog(
        xp: character.xp,
        nextLevel: character.level >= maxLevel ? null : character.level + 1,
        enoughXp: hasXpForNextLevel(character, rules.classes),
        canUndo: character.levelUpUndo != null,
      ),
    );
    if (result == null || !context.mounted) return;

    final changed = character.copyWith(xp: result.xp);
    if (result.action == _XpAction.save || result.xp != character.xp) {
      await ref.read(charactersProvider.notifier).save(changed);
    }
    if (!context.mounted) return;
    switch (result.action) {
      case _XpAction.levelUp:
        await _levelUp(context, ref, changed);
      case _XpAction.undo:
        await _undo(context, ref);
      case _XpAction.save:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final atCap = character.level >= maxLevel;

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
            onPressed: () => _edit(context, ref),
          ),
        ]),
        OwedGains(character: character, rules: rules),
      ]),
    );
  }
}

enum _XpAction { save, levelUp, undo }

class _XpResult {
  const _XpResult(this.xp, this.action);

  final int xp;
  final _XpAction action;
}

/// Edit the total experience, level up, or undo the last level-up.
class _XpDialog extends StatefulWidget {
  const _XpDialog({
    required this.xp,
    required this.nextLevel,
    required this.enoughXp,
    required this.canUndo,
  });

  final int xp;

  /// Null at the level cap.
  final int? nextLevel;
  final bool enoughXp;
  final bool canUndo;

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
    final valid = xp != null && xp >= 0;
    final next = widget.nextLevel;

    void close(_XpAction action) => Navigator.pop(context, _XpResult(xp!, action));

    return AlertDialog(
      title: Text(l10n.editExperience),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.totalExperience),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (next == null)
          Text(l10n.levelCapNote)
        else
          SizedBox(
            width: double.infinity,
            child: widget.enoughXp
                ? FilledButton.icon(
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(l10n.levelUpTo(next)),
                    onPressed: valid ? () => close(_XpAction.levelUp) : null,
                  )
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(l10n.levelUpTo(next)),
                    onPressed: valid ? () => close(_XpAction.levelUp) : null,
                  ),
          ),
        if (widget.canUndo)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.undo),
              label: Text(l10n.undoLevelUp),
              onPressed: valid ? () => close(_XpAction.undo) : null,
            ),
          ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: valid ? () => close(_XpAction.save) : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
