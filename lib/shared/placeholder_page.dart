import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Stand-in for a tab that is not built yet. Delete once every tab has a page.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(AppLocalizations.of(context).comingSoon)),
    );
  }
}
