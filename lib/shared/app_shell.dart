import 'package:flutter/material.dart';

import '../features/glossary/glossary_page.dart';
import '../features/lore/lore_page.dart';
import '../features/play/play_page.dart';
import '../features/sheet/sheet_page.dart';
import '../features/spells/spells_page.dart';
import '../l10n/app_localizations.dart';
import 'device_class.dart';

/// One tab: its icon, its name and the page it shows.
class _AppTab {
  const _AppTab(this.icon, this.label, this.page);

  final IconData icon;
  final String label;
  final Widget page;
}

/// The five tabs. Phone: bottom bar. Tablet: icon rail. Desktop: labeled sidebar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      _AppTab(Icons.shield_outlined, l10n.tabPlay, const PlayPage()),
      _AppTab(Icons.assignment_ind_outlined, l10n.tabSheet, const SheetPage()),
      _AppTab(Icons.auto_awesome, l10n.tabSpells, const SpellsPage()),
      _AppTab(Icons.menu_book_outlined, l10n.tabGlossary, const GlossaryPage()),
      _AppTab(Icons.hub_outlined, l10n.tabLore, const LorePage()),
    ];

    // IndexedStack keeps every tab alive, so switching tabs keeps scroll positions.
    final pages = IndexedStack(
      index: _selected,
      children: [for (final tab in tabs) tab.page],
    );

    final device = deviceClassFor(MediaQuery.sizeOf(context).width);

    if (device == DeviceClass.phone) {
      return Scaffold(
        body: pages,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in tabs)
              NavigationDestination(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selected,
            onDestinationSelected: _select,
            extended: device == DeviceClass.desktop,
            destinations: [
              for (final tab in tabs)
                NavigationRailDestination(
                  icon: Icon(tab.icon),
                  label: Text(tab.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages),
        ],
      ),
    );
  }
}
