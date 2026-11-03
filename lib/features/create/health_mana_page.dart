import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/display_name.dart';
import '../../shared/form_widgets.dart';
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

    await ref.read(charactersProvider.notifier).add(character);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
        _DieRow(
          label: l10n.health,
          base: health.base,
          ability: displayName(health.plus),
          score: abilities[health.plus] ?? 0,
          die: _healthDie,
          onChanged: (die) => setState(() => _healthDie = die),
        ),
        if (mana != null)
          _DieRow(
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
          child: Text(l10n.createCharacter),
        ),
      ]),
    );
  }
}

/// "25 + Constitution 2 + d6", a Roll button, and 1-6 chips to enter a d6
/// that was rolled at the table.
class _DieRow extends StatelessWidget {
  const _DieRow({
    required this.label,
    required this.base,
    required this.ability,
    required this.score,
    required this.die,
    required this.onChanged,
  });

  final String label;
  final int base;
  final String ability;
  final int score;
  final int? die;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formula = l10n.formula(base, ability, score, '${die ?? 'd6'}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(die == null
              ? formula
              : l10n.formulaTotal(formula, base + score + die!)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.casino_outlined),
                label: Text(l10n.rollDie),
                onPressed: () => onChanged(Random().nextInt(6) + 1),
              ),
              for (var value = 1; value <= 6; value++)
                ChoiceChip(
                  label: Text('$value'),
                  selected: die == value,
                  onSelected: (_) => onChanged(value),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}
