import 'dart:math';

import 'package:flutter/material.dart';

import '../../character/damage_roll.dart';
import '../../character/test_roll.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/stunt.dart';
import '../../rules/rules_data.dart';
import '../../shared/device_class.dart';
import '../../shared/display_name.dart';
import '../../shared/stepper_row.dart';
import 'dice_row.dart';
import 'roll_request.dart';
import 'stunt_picker.dart';

/// Rolls [request] and shows the result: on a phone as a bottom sheet, on a
/// tablet or desktop as a panel at the right edge.
Future<void> showRoll(
    BuildContext context, RulesData rules, RollRequest request) {
  final sheet = RollSheet(request: request, rules: rules);

  if (deviceClassFor(MediaQuery.sizeOf(context).width) == DeviceClass.phone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => sheet,
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).close,
    pageBuilder: (dialogContext, _, __) => Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 420,
        height: double.infinity,
        child: Material(
          color: Theme.of(dialogContext).colorScheme.surfaceContainer,
          child: SafeArea(child: sheet),
        ),
      ),
    ),
  );
}

enum _StuntCategory { combat, exploration, roleplaying }

/// The roll sheet: dice (tap to type your own), target number and modifier,
/// the result, damage for weapons, and the stunts doubles pay for.
class RollSheet extends StatefulWidget {
  const RollSheet({super.key, required this.request, required this.rules});

  final RollRequest request;
  final RulesData rules;

  @override
  State<RollSheet> createState() => _RollSheetState();
}

class _RollSheetState extends State<RollSheet> {
  final _random = Random();
  late TestRoll _roll = TestRoll.roll(_random);
  late DamageRoll? _damage = _rollDamage();
  late int _tn = widget.request.tn;
  int _modifier = 0;
  int _rollNumber = 0; // changes with every new roll; restarts the extras
  final _picked = <String>{};
  _StuntCategory _category = _StuntCategory.exploration;

  RollRequest get _request => widget.request;

  DamageRoll? _rollDamage() {
    final formula = widget.request.damage;
    return formula == null ? null : DamageRoll.tryRoll(formula, _random);
  }

  /// The dice changed: stunts picked for the old roll no longer count.
  void _changeRoll(void Function() change) => setState(() {
        change();
        _picked.clear();
        _rollNumber++;
      });

  List<Stunt> get _stunts {
    final rules = widget.rules;
    return switch (_request.stunts) {
      StuntSet.combat => rules.combatStunts,
      StuntSet.magic => rules.magic.standardStunts,
      StuntSet.test => switch (_category) {
          _StuntCategory.combat => rules.combatStunts,
          _StuntCategory.exploration => rules.explorationStunts,
          _StuntCategory.roleplaying => rules.roleplayingStunts,
        },
    };
  }

  void _toggleStunt(String id) =>
      setState(() => _picked.contains(id) ? _picked.remove(id) : _picked.add(id));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    final bonus = _request.bonus + _modifier;
    final total = _roll.total(bonus);
    final success = total >= _tn;
    final stuntPoints = success && _roll.hasDoubles ? _roll.dragonDie : 0;
    final damage = _damage;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_request.title, style: text.titleLarge),
        for (final line in _request.info) Text(line),
        const SizedBox(height: 12),
        DiceRow(
          dice: _roll.dice,
          dragonLast: true,
          onChanged: (i, value) => _changeRoll(() => _roll = _roll.withDie(i, value)),
        ),
        Text(l10n.tapDieHint, style: text.bodySmall),
        const SizedBox(height: 8),
        StepperRow(
          label: l10n.targetNumber,
          value: '$_tn',
          onChanged: (change) => setState(() => _tn += change),
        ),
        StepperRow(
          label: l10n.modifier,
          value: signed(_modifier),
          onChanged: (change) => setState(() => _modifier += change),
        ),
        const SizedBox(height: 8),
        Text(l10n.rollTotal(_roll.sum, bonus, total), style: text.titleMedium),
        Text(
          success ? l10n.rollSuccess(_tn) : l10n.rollFail(_tn),
          style: text.titleMedium?.copyWith(
            color: success ? null : Theme.of(context).colorScheme.error,
          ),
        ),
        if (damage != null) ...[
          const SizedBox(height: 12),
          Text(l10n.damageLine(damage.total, _request.damage!), style: text.titleMedium),
          const SizedBox(height: 4),
          DiceRow(
            dice: damage.dice,
            onChanged: (i, value) => setState(() => _damage = damage.withDie(i, value)),
          ),
        ],
        if (stuntPoints > 0) ...[
          const SizedBox(height: 12),
          if (_request.stunts == StuntSet.test) _categoryChooser(l10n),
          StuntPicker(
            stunts: _stunts,
            points: stuntPoints,
            picked: _picked,
            onToggle: _toggleStunt,
          ),
        ],
        if (_request.extras != null)
          KeyedSubtree(
            key: ValueKey(_rollNumber),
            child: _request.extras!(
                context, RollOutcome(roll: _roll, success: success)),
          ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (_request.onUndo != null)
            TextButton(
              onPressed: () async {
                await _request.onUndo!();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.undo),
            ),
          TextButton(
            onPressed: () => _changeRoll(() {
              _roll = TestRoll.roll(_random);
              _damage = _rollDamage();
            }),
            child: Text(l10n.reroll),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ]),
      ]),
    );
  }

  Widget _categoryChooser(AppLocalizations l10n) {
    final names = {
      _StuntCategory.combat: l10n.stuntsCombat,
      _StuntCategory.exploration: l10n.stuntsExploration,
      _StuntCategory.roleplaying: l10n.stuntsRoleplaying,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SegmentedButton<_StuntCategory>(
        segments: [
          for (final e in names.entries)
            ButtonSegment(value: e.key, label: Text(e.value)),
        ],
        selected: {_category},
        onSelectionChanged: (picked) => setState(() {
          _category = picked.first;
          _picked.clear();
        }),
      ),
    );
  }
}
