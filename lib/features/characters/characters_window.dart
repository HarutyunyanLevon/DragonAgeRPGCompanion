import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/display_name.dart';
import '../create/new_character_page.dart';

/// Opens the characters window: a bottom sheet (centered and narrow on wide
/// screens) with the list of saved characters.
void showCharactersWindow(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const CharactersWindow(),
  );
}

/// Saved characters: tap to select, trash icon to delete, button to create.
class CharactersWindow extends ConsumerWidget {
  const CharactersWindow({super.key});

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Character character) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirm(
      context,
      title: l10n.deleteCharacterTitle(character.name),
      body: l10n.deleteCharacterBody,
      confirmLabel: l10n.delete,
    );
    if (confirmed) {
      await ref.read(charactersProvider.notifier).delete(character.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(charactersProvider).valueOrNull;
    final characters = library?.characters ?? const <Character>[];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.charactersTitle,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final character in characters)
                  ListTile(
                    selected: character.id == library?.selectedId,
                    title: Text(character.name),
                    subtitle: Text(l10n.characterLine(
                      displayName(character.race),
                      displayName(character.classId),
                      character.level,
                      displayName(character.backgroundId),
                    )),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.delete,
                      onPressed: () => _delete(context, ref, character),
                    ),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await ref
                          .read(charactersProvider.notifier)
                          .select(character.id);
                      navigator.pop();
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.newCharacter),
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop(); // close this window, then open the wizard
                navigator.push(newCharacterRoute());
              },
            ),
          ),
        ],
      ),
    );
  }
}
