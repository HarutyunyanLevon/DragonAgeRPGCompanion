import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';

/// Temporary Play tab: proves the rules load. Becomes the real Play screen later.
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
            data: (data) => Text(l10n.rulesLoaded(
              data.classes.classes.length,
              data.backgrounds.backgrounds.length,
              data.talents.talents.length,
              data.spells.length,
            )),
          ),
        ),
      ),
    );
  }
}
