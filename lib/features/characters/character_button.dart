import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import 'characters_window.dart';

/// The selected character's name, as a button for the header. Opens the
/// characters window. Put it in the `actions` of every tab's AppBar.
class CharacterButton extends ConsumerWidget {
  const CharacterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(selectedCharacterProvider).valueOrNull?.name ??
        l10n.noCharacter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        icon: const Icon(Icons.person_outline),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(name, overflow: TextOverflow.ellipsis),
        ),
        onPressed: () => showCharactersWindow(context),
      ),
    );
  }
}
