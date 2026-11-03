import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../characters/character_button.dart';
import '../characters/character_view.dart';
import 'character_summary.dart';

/// Play tab. For now: a summary of the selected character. The widget grid
/// replaces it later.
class PlayPage extends StatelessWidget {
  const PlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPlay),
        actions: const [CharacterButton()],
      ),
      body: CharacterView(
        builder: (character, rules) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CharacterSummary(character: character, rules: rules),
            ),
          ),
        ),
      ),
    );
  }
}
