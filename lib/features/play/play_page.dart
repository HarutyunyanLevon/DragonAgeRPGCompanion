import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../create/new_character_page.dart';

/// Play tab. Until characters can be saved, it only offers to create the first one.
class PlayPage extends ConsumerWidget {
  const PlayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabPlay)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: rules.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text(l10n.rulesFailed(error.toString())),
            data: (_) => const _CreateFirstCharacter(),
          ),
        ),
      ),
    );
  }
}

class _CreateFirstCharacter extends StatelessWidget {
  const _CreateFirstCharacter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
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
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewCharacterPage()),
          ),
        ),
      ],
    );
  }
}
