import 'package:flutter/material.dart';

import '../features/characters/character_button.dart';
import '../l10n/app_localizations.dart';

/// Stand-in for a tab that is not built yet. Delete once every tab has a page.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [CharacterButton()]),
      body: Center(child: Text(AppLocalizations.of(context).comingSoon)),
    );
  }
}
