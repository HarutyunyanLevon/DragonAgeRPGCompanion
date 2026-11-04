import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/level_up.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/backgrounds.dart' show FocusRef;
import '../../rules/rules_data.dart';
import '../../shared/form_widgets.dart';
import 'gain_pickers.dart';

/// Buttons for the gains skipped at level-up, one per owed gain. Each opens
/// [OwedGainPage]. Shows nothing when nothing is owed.
class OwedGains extends StatelessWidget {
  const OwedGains({super.key, required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  static String label(AppLocalizations l10n, String owedId) {
    if (isOwedClassFocus(owedId)) return l10n.owedClassFocus;
    if (isOwedSpecialization(owedId)) return l10n.owedSpecialization;
    return switch (owedId) {
      owedTalent => l10n.owedTalent,
      owedWeaponGroup => l10n.owedWeaponGroup,
      _ => l10n.owedFocus, // focus:primary, focus:secondary
    };
  }

  @override
  Widget build(BuildContext context) {
    if (character.owedGains.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final owedId in character.owedGains.toSet())
          ActionChip(
            avatar: const Icon(Icons.add),
            label: Text(label(l10n, owedId)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) =>
                  OwedGainPage(character: character, rules: rules, owedId: owedId),
            )),
          ),
      ]),
    );
  }
}

/// Takes one owed gain: pick it, press Add.
class OwedGainPage extends ConsumerStatefulWidget {
  const OwedGainPage({
    super.key,
    required this.character,
    required this.rules,
    required this.owedId,
  });

  final Character character;
  final RulesData rules;
  final String owedId;

  @override
  ConsumerState<OwedGainPage> createState() => _OwedGainPageState();
}

class _OwedGainPageState extends ConsumerState<OwedGainPage> {
  // Only the one that matches the owed gain is used.
  String? _id; // talent, weapon group or specialization id
  FocusRef? _focus;

  Character get _character => widget.character;
  RulesData get _rules => widget.rules;
  String get _owedId => widget.owedId;

  bool get _isFocus =>
      _owedId == owedFocusPrimary ||
      _owedId == owedFocusSecondary ||
      isOwedClassFocus(_owedId);

  bool get _picked => _isFocus ? _focus != null : _id != null;

  /// The focuses this owed gain offers.
  List<FocusRef> get _focusOptions {
    final classRules = _rules.classes.classById(_character.classId);
    if (isOwedClassFocus(_owedId)) {
      final level = classRules.levelData(owedNumber(_owedId));
      return notOwned(_character, level.focusChoices);
    }
    final abilities = _owedId == owedFocusPrimary
        ? classRules.primaryAbilities
        : classRules.secondaryAbilities;
    return focusChoices(_character, _rules, abilities);
  }

  Character _apply() {
    final changed = _isFocus
        ? addFocus(_character, _focus!)
        : isOwedSpecialization(_owedId)
            ? addSpecialization(_character, _id!, owedNumber(_owedId))
            : _owedId == owedTalent
                ? addTalent(_character, _id!)
                : addWeaponGroup(_character, _id!);
    return withoutOwed(changed, _owedId);
  }

  Future<void> _add() async {
    await ref.read(charactersProvider.notifier).save(_apply());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _picker() {
    if (_isFocus) {
      return FocusPicker(
        rules: _rules,
        options: _focusOptions,
        picked: _focus,
        onPick: (f) => setState(() => _focus = f),
      );
    }
    void pick(String id) => setState(() => _id = id);
    if (isOwedSpecialization(_owedId)) {
      return SpecializationPicker(
          character: _character, rules: _rules, picked: _id, onPick: pick);
    }
    if (_owedId == owedTalent) {
      return TalentPicker(
          character: _character, rules: _rules, picked: _id, onPick: pick);
    }
    return WeaponGroupPicker(
        character: _character, rules: _rules, picked: _id, onPick: pick);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = OwedGains.label(l10n, _owedId);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FormBody(children: [
        _picker(),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _picked ? _add : null,
          child: Text(l10n.addGain),
        ),
      ]),
    );
  }
}
