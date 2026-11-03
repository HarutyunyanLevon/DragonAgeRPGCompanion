import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../create/create_first_character.dart';

/// Waits for the rules and the selected character, then calls [builder].
/// Shows the "create your first character" prompt when there is no character.
/// The Play and Sheet tabs both use it.
class CharacterView extends ConsumerWidget {
  const CharacterView({super.key, required this.builder});

  final Widget Function(Character character, RulesData rules) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider);
    final character = ref.watch(selectedCharacterProvider);

    return rules.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(l10n.rulesFailed(error.toString()))),
      data: (rulesData) => character.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (selected) => selected == null
            ? const Center(child: CreateFirstCharacter())
            : builder(selected, rulesData),
      ),
    );
  }
}
