import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/die_row.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
import '../level_up/level_up_page.dart';
import '../play/character_summary.dart';
import 'character_builder.dart';
import 'character_draft.dart';

/// Wizard step 4b of 4: roll (or enter) the d6 for health and mana, see the
/// finished character, and save it.
class HealthManaPage extends ConsumerStatefulWidget {
  const HealthManaPage({super.key});

  @override
  ConsumerState<HealthManaPage> createState() => _HealthManaPageState();
}

class _HealthManaPageState extends ConsumerState<HealthManaPage> {
  /// The character file name: creation time, so the newest sorts last.
  final _id = DateTime.now().millisecondsSinceEpoch.toString();

  int? _healthDie;
  int? _manaDie;

  /// Level 1: save. Higher start level: the level-up pages come next.
  Future<void> _create() async {
    final draft = ref.read(characterDraftProvider);
    final rules = ref.read(rulesProvider).requireValue;
    final character = buildCharacter(
      draft: draft,
      rules: rules,
      id: _id,
      healthDie: _healthDie!,
      manaDie: _manaDie ?? 0,
    );

    await _nextLevel(character, draft.startLevel, rules);
  }

  /// Opens the level-up page for the level after [character]'s, or saves the
  /// character when [targetLevel] is reached. Each finished page calls this
  /// again with the leveled-up character.
  Future<void> _nextLevel(
      Character character, int targetLevel, RulesData rules) async {
    if (character.level >= targetLevel) {
      // Higher levels start with the XP of their level; the wizard's
      // level-ups cannot be undone.
      await ref.read(charactersProvider.notifier).add(character.copyWith(
            xp: rules.classes.xpForLevel(targetLevel),
            clearLevelUpUndo: true,
          ));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LevelUpPage(
        character: character,
        rules: rules,
        stepLabel: l10n.levelOf(character.level + 1, targetLevel),
        onFinish: (leveledUp) => _nextLevel(leveledUp, targetLevel, rules),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider).requireValue;
    final draft = ref.watch(characterDraftProvider);

    final classRules = rules.classes.classById(draft.classId!);
    final abilities = finalAbilities(draft, rules);
    final health = classRules.startingHealth;
    final mana = classRules.mana;
    final ready = _healthDie != null && (mana == null || _manaDie != null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCharacter)),
      body: FormBody(children: [
        Text(l10n.stepOf(4, 4), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(l10n.healthManaTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DieRow(
          label: l10n.health,
          base: health.base,
          ability: displayName(health.plus),
          score: abilities[health.plus] ?? 0,
          die: _healthDie,
          onChanged: (die) => setState(() => _healthDie = die),
        ),
        if (mana != null)
          DieRow(
            label: l10n.mana,
            base: mana.startBase,
            ability: displayName(mana.plus),
            score: abilities[mana.plus] ?? 0,
            die: _manaDie,
            onChanged: (die) => setState(() => _manaDie = die),
          ),
        const SizedBox(height: 16),
        if (ready) ...[
          CharacterSummary(
            character: buildCharacter(
              draft: draft,
              rules: rules,
              id: _id,
              healthDie: _healthDie!,
              manaDie: _manaDie ?? 0,
            ),
            rules: rules,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: ready ? _create : null,
          child: Text(draft.startLevel == 1 ? l10n.createCharacter : l10n.next),
        ),
      ]),
    );
  }
}
