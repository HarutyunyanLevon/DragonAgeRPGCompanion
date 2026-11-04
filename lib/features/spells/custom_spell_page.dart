import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/magic.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/spell.dart';
import '../../rules/rules_data.dart';
import '../../rules/slug.dart';
import '../../shared/form_widgets.dart';
import '../../shared/picker.dart';
import 'custom_spells.dart';

/// Form for a homebrew spell. School, type, casting time, test and
/// requirement are picked from the values the book uses; name, mana, TN and
/// description are typed. The new spell is added to the library and learned by
/// the selected character.
class CustomSpellPage extends ConsumerStatefulWidget {
  const CustomSpellPage({super.key, required this.rules});

  final RulesData rules;

  @override
  ConsumerState<CustomSpellPage> createState() => _CustomSpellPageState();
}

class _CustomSpellPageState extends ConsumerState<CustomSpellPage> {
  static const _none = 'None';

  final _name = TextEditingController();
  final _mana = TextEditingController();
  final _tn = TextEditingController();
  final _description = TextEditingController();

  late String _school;
  late String _type;
  late String _castTime;
  late String _test;
  String _requirement = _none;

  @override
  void initState() {
    super.initState();
    _school = _values((s) => s.school).first;
    _type = _values((s) => s.type).first;
    _castTime = _pick(_values((s) => s.castTime), 'Major Action');
    _test = _pick(_values((s) => s.test), _none);
  }

  @override
  void dispose() {
    _name.dispose();
    _mana.dispose();
    _tn.dispose();
    _description.dispose();
    super.dispose();
  }

  /// The different values the book's spells use for one field, sorted.
  List<String> _values(String Function(Spell) field) =>
      ({for (final s in widget.rules.spells) field(s).trim()}..remove(''))
          .toList()
        ..sort();

  /// [preferred] when the book uses it, otherwise the first value.
  String _pick(List<String> values, String preferred) =>
      values.contains(preferred) ? preferred : values.first;

  /// "5" is accepted as "5 MP".
  String get _manaText {
    final text = _mana.text.trim();
    return RegExp(r'^\d+$').hasMatch(text) ? '$text MP' : text;
  }

  bool get _nameTaken {
    final id = slug(_name.text);
    return id.isNotEmpty && ref.read(allSpellsProvider).any((s) => s.id == id);
  }

  bool get _valid =>
      slug(_name.text).isNotEmpty &&
      !_nameTaken &&
      parseManaCost(_manaText) != null &&
      int.tryParse(_tn.text.trim()) != null;

  /// The requirement as data: copied from a book spell with the same text.
  List<SpellRequirement> get _requires => _requirement == _none
      ? const []
      : widget.rules.spells
          .firstWhere((s) => s.requirement.trim() == _requirement)
          .requires;

  Future<void> _save() async {
    final spell = Spell(
      name: _name.text.trim(),
      school: _school,
      type: _type,
      mana: _manaText,
      castTime: _castTime,
      tn: _tn.text.trim(),
      test: _test,
      requirement: _requirement,
      requires: _requires,
      description: _description.text.trim(),
      homebrew: true,
    );
    await ref.read(customSpellsProvider.notifier).add(spell);

    final character = ref.read(selectedCharacterProvider).requireValue;
    if (character != null) {
      await ref.read(charactersProvider.notifier).save(
          character.copyWith(spellIds: [...character.spellIds, spell.id]));
    }
    if (mounted) Navigator.of(context).pop();
  }

  List<DropdownMenuEntry<String>> _entries(Iterable<String> values) =>
      [for (final v in values) DropdownMenuEntry(value: v, label: v)];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requirements = [
      _none,
      ..._values((s) => s.requirement).where((r) => r != _none),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newSpell)),
      body: FormBody(children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: l10n.spellName,
            errorText: _nameTaken ? l10n.spellNameTaken : null,
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Picker<String>(
          label: l10n.spellSchool,
          initial: _school,
          entries: _entries(_values((s) => s.school)),
          onSelected: (v) => setState(() => _school = v ?? _school),
        ),
        Picker<String>(
          label: l10n.spellKind,
          initial: _type,
          entries: _entries(_values((s) => s.type)),
          onSelected: (v) => setState(() => _type = v ?? _type),
        ),
        Picker<String>(
          label: l10n.castingTime,
          initial: _castTime,
          entries: _entries(_values((s) => s.castTime)),
          onSelected: (v) => setState(() => _castTime = v ?? _castTime),
        ),
        Picker<String>(
          label: l10n.spellTest,
          initial: _test,
          entries: _entries(_values((s) => s.test)),
          onSelected: (v) => setState(() => _test = v ?? _test),
        ),
        Picker<String>(
          label: l10n.requirements,
          initial: _requirement,
          entries: _entries(requirements),
          onSelected: (v) => setState(() => _requirement = v ?? _requirement),
        ),
        TextField(
          controller: _mana,
          decoration: InputDecoration(
            labelText: l10n.spellMana,
            helperText: l10n.spellManaHelp,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tn,
          decoration: InputDecoration(labelText: l10n.targetNumber),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _description,
          decoration: InputDecoration(labelText: l10n.spellDescription),
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _valid ? _save : null,
          child: Text(l10n.save),
        ),
      ]),
    );
  }
}
