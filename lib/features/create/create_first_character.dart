import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'new_character_page.dart';

/// Shown on a tab when there is no character yet.
class CreateFirstCharacter extends StatelessWidget {
  const CreateFirstCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.createFirstCharacter,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.createCharacter),
            style: FilledButton.styleFrom(
              minimumSize: const Size(240, 64),
              textStyle: theme.textTheme.titleMedium,
            ),
            onPressed: () => Navigator.of(context).push(newCharacterRoute()),
          ),
        ],
      ),
    );
  }
}
