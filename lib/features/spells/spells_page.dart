import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/magic.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/models/spell.dart';
import '../../rules/rules_data.dart';
import '../../shared/form_widgets.dart';
import '../../shared/info_row.dart';
import '../characters/character_button.dart';
import '../characters/character_view.dart';
import '../sheet/sheet_filter.dart';
import 'cast_spell.dart';
import 'custom_spell_page.dart';
import 'custom_spells.dart';
import 'spell_card.dart';

/// Spells tab. A mage sees the spells he knows (Cast button on each) or, with
/// the toggle, every spell of the book to learn from. Other classes can read
/// every spell and nothing more.
class SpellsPage extends StatelessWidget {
  const SpellsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSpells),
        actions: const [CharacterButton()],
      ),
      body: CharacterView(
        builder: (character, rules) =>
            _SpellsBody(character: character, rules: rules),
      ),
    );
  }
}

class _SpellsBody extends ConsumerStatefulWidget {
  const _SpellsBody({required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  @override
  ConsumerState<_SpellsBody> createState() => _SpellsBodyState();
}

class _SpellsBodyState extends ConsumerState<_SpellsBody> {
  static const _wideWidth = 900.0; // list left, open spell right

  bool _showAll = false;
  String _query = '';
  String? _school; // null: every school
  String? _selectedId; // wide layout: the spell shown on the right

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final character = widget.character;
    final rules = widget.rules;
    final mage = canCast(character, rules);
    final showAll = _showAll || !mage;
    final filter = SheetFilter(_query);

    final all = ref.watch(allSpellsProvider);
    final schools = {for (final s in all) s.school}.toList()..sort();
    final shown = [
      for (final spell in all)
        if ((showAll || character.spellIds.contains(spell.id)) &&
            (_school == null || spell.school == _school) &&
            filter.matches([spell.name, spell.description]))
          spell,
    ];

    Widget row(Spell spell, {required bool wide}) {
      final known = character.spellIds.contains(spell.id);
      final dimmed = showAll &&
          mage &&
          !known &&
          unmetRequirements(character, spell).isNotEmpty;
      final subtitle = '${spell.mana} · ${spell.castTime}';
      final cast = known && mage
          ? IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: l10n.cast,
              onPressed: () =>
                  castSpell(context, ref, character, rules, spell),
            )
          : null;

      final tile = wide
          ? ListTile(
              leading: cast,
              title: Text(spell.name),
              subtitle: Text(subtitle),
              trailing: known && showAll ? const Icon(Icons.check) : null,
              selected: spell.id == _selectedId,
              onTap: () => setState(() => _selectedId = spell.id),
            )
          : InfoRow(
              leading: cast,
              title: spell.name,
              subtitle: subtitle,
              value: known && showAll ? '✓' : null,
              child: SpellCard(character: character, rules: rules, spell: spell),
            );
      // Strict rules: a spell whose requirements are not met is dimmed.
      return dimmed ? Opacity(opacity: 0.5, child: tile) : tile;
    }

    List<Widget> rows({required bool wide}) => [
          for (final school in schools)
            if (shown.any((s) => s.school == school)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SectionTitle(school),
              ),
              for (final spell in shown.where((s) => s.school == school))
                row(spell, wide: wide),
            ],
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                showAll ? l10n.noSpellsFound : l10n.noSpellsYet,
                textAlign: TextAlign.center,
              ),
            ),
        ];

    final header = <Widget>[
      if (mage)
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.mySpells)),
                ButtonSegment(value: true, label: Text(l10n.allSpells)),
              ],
              selected: {_showAll},
              onSelectionChanged: (picked) =>
                  setState(() => _showAll = picked.first),
            ),
            Text('${l10n.mana}: ${character.mana} / ${character.maxMana}'),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.newSpell,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CustomSpellPage(rules: rules),
                ),
              ),
            ),
          ],
        )
      else
        Text(l10n.spellsReadOnly),
      const SizedBox(height: 8),
      TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.searchSpells,
        ),
        onChanged: (text) => setState(() => _query = text),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final school in schools)
          FilterChip(
            label: Text(school),
            selected: _school == school,
            onSelected: (on) => setState(() => _school = on ? school : null),
          ),
      ]),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _wideWidth;
      final list = ListView(
        padding: const EdgeInsets.all(16),
        children: [...header, ...rows(wide: wide)],
      );

      if (!wide) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: list,
          ),
        );
      }

      final selected = shown.where((s) => s.id == _selectedId).firstOrNull;
      return Row(children: [
        Expanded(flex: 3, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: selected == null
              ? Center(child: Text(l10n.selectSpell))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SpellCard(
                      character: character, rules: rules, spell: selected),
                ),
        ),
      ]);
    });
  }
}
