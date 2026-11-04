import 'package:flutter/material.dart';

import '../../character/character.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/form_widgets.dart';
import '../characters/character_button.dart';
import '../characters/character_view.dart';
import 'abilities_section.dart';
import 'combat_section.dart';
import 'gear_section.dart';
import 'header_block.dart';
import 'sheet_filter.dart';
import 'talents_section.dart';

/// Sheet tab: one scrolling page laid out like the paper character sheet
/// (two columns on wide screens). The search box on top hides everything that
/// does not match; the buttons on the right edge jump to a section (the one
/// you are in is highlighted) or back to the top.
class SheetPage extends StatelessWidget {
  const SheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSheet),
        actions: const [CharacterButton()],
      ),
      body: CharacterView(
        builder: (character, rules) =>
            _SheetBody(character: character, rules: rules),
      ),
    );
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  static const _sectionCount = 4;
  static const _scrollTime = Duration(milliseconds: 300);
  static const _wideWidth = 900.0; // two columns from this width

  // One key per section, to find where it is on screen and scroll to it.
  final _keys = List.generate(_sectionCount, (_) => GlobalKey());
  final _stackKey = GlobalKey();
  final _scroll = ScrollController();
  int _current = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateCurrent);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The current section is the last one whose top has reached the top of
  /// the page. At the very bottom it is the last section.
  void _updateCurrent() {
    final pageBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (pageBox == null) return;
    final pageTop = pageBox.localToGlobal(Offset.zero).dy;

    // The section with the lowest top that has reached the top of the page
    // (the first one when two columns start at the same height).
    var current = 0;
    var currentTop = double.negativeInfinity;
    for (var i = 0; i < _sectionCount; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= pageTop + 48 && top > currentTop) {
        current = i;
        currentTop = top;
      }
    }
    final atBottom = _scroll.position.pixels >= _scroll.position.maxScrollExtent - 1;
    if (atBottom) current = _sectionCount - 1;

    if (current != _current) setState(() => _current = current);
  }

  void _scrollToSection(int index) {
    final context = _keys[index].currentContext;
    if (context != null) Scrollable.ensureVisible(context, duration: _scrollTime);
  }

  void _scrollToTop() =>
      _scroll.animateTo(0, duration: _scrollTime, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final character = widget.character;
    final rules = widget.rules;
    final filter = SheetFilter(_query);

    // Section widgets by index: 0 combat, 1 abilities, 2 talents, 3 gear.
    Widget section(int index, Widget child) =>
        KeyedSubtree(key: _keys[index], child: child);
    final combat = section(0,
        CombatSection(character: character, rules: rules, filter: filter));
    final abilities = section(1,
        AbilitiesSection(character: character, rules: rules, filter: filter));
    final talents = section(2,
        TalentsSection(character: character, rules: rules, filter: filter));
    final gear = section(3,
        GearSection(character: character, rules: rules, filter: filter));

    final nothingFound = filter.isActive &&
        !CombatSection.hasMatches(l10n, character, rules, filter) &&
        !AbilitiesSection.hasMatches(character, rules, filter) &&
        !TalentsSection.hasMatches(character, rules, filter) &&
        !GearSection.hasMatches(l10n, character, rules, filter);

    return Column(children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 88, 0),
            child: TextField(
              decoration: InputDecoration(
                labelText: l10n.searchSheet,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (text) => setState(() => _query = text),
            ),
          ),
        ),
      ),
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideWidth;

          return Stack(
            key: _stackKey,
            fit: StackFit.expand,
            children: [
              FormBody(
                controller: _scroll,
                maxWidth: wide ? 1100 : 640,
                // Room on the right so the buttons never cover the text.
                padding: const EdgeInsets.fromLTRB(16, 16, 88, 16),
                children: [
                  HeaderBlock(character: character, rules: rules),
                  if (nothingFound)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.searchNoMatches,
                          textAlign: TextAlign.center),
                    )
                  else if (wide)
                    // Like the paper sheet: abilities left, the rest right.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: abilities),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: Column(children: [combat, talents]),
                        ),
                      ],
                    )
                  else ...[combat, abilities, talents],
                  if (!nothingFound) gear,
                ],
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _SectionNav(
                    labels: [
                      l10n.sectionCombat,
                      l10n.abilities,
                      l10n.sectionTalents,
                      l10n.navGear,
                    ],
                    current: _current,
                    onSelect: _scrollToSection,
                    onTop: _scrollToTop,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    ]);
  }
}

/// A narrow column of buttons: back to the top, then one per section.
class _SectionNav extends StatelessWidget {
  const _SectionNav({
    required this.labels,
    required this.current,
    required this.onSelect,
    required this.onTop,
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int> onSelect;
  final VoidCallback onTop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainer.withValues(alpha: 0.9),
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 72,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.vertical_align_top),
            tooltip: l10n.navTop,
            onPressed: onTop,
          ),
          for (var i = 0; i < labels.length; i++)
            InkWell(
              onTap: () => onSelect(i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: i == current
                    ? colors.primary.withValues(alpha: 0.25)
                    : null,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
