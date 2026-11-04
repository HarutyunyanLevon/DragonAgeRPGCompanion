import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../characters/character_button.dart';
import '../characters/character_view.dart';
import 'play_grid.dart';
import 'play_info_card.dart';

/// Play tab: the character's widget grid. Edit mode is switched on by a long
/// press on a widget or by the pencil, and off by Done. Tapping an item opens
/// a card at the bottom.
class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  bool _editing = false;

  void _setEditing(bool editing) {
    ref.read(playInfoProvider.notifier).state = null;
    setState(() => _editing = editing);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(playInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPlay),
        actions: [
          IconButton(
            tooltip: l10n.editWidgets,
            icon: Icon(_editing ? Icons.check : Icons.edit),
            onPressed: () => _setEditing(!_editing),
          ),
          const CharacterButton(),
        ],
      ),
      body: Stack(children: [
        CharacterView(
          builder: (character, rules) => PlayGrid(
            key: ValueKey(character.id),
            character: character,
            rules: rules,
            editing: _editing,
            onEditingChanged: _setEditing,
          ),
        ),
        if (info != null) PlayInfoCard(info: info),
      ]),
    );
  }
}
