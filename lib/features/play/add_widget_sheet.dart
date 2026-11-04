import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/play_items.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';

/// Asks which widget to add (blank first, then the default ones) and adds it
/// below the others.
Future<void> addWidget(BuildContext context, WidgetRef ref,
    Character character, RulesData rules) async {
  final added = await showModalBottomSheet<PlayWidgetData>(
    context: context,
    builder: (_) => _AddWidgetSheet(character: character, rules: rules),
  );
  if (added == null) return;
  await ref.read(charactersProvider.notifier).save(character.copyWith(
      playWidgets: [...(character.playWidgets ?? const []), added]));
}

/// Choose a ready-made widget or a blank one. Returns the new widget.
class _AddWidgetSheet extends StatelessWidget {
  const _AddWidgetSheet({required this.character, required this.rules});

  final Character character;
  final RulesData rules;

  String _newId() => 'w${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ListView(shrinkWrap: true, children: [
        ListTile(
          leading: const Icon(Icons.crop_square),
          title: Text(l10n.blankWidget),
          onTap: () => Navigator.pop(context,
              PlayWidgetData(id: _newId(), title: l10n.newWidgetTitle, items: const [])),
        ),
        const Divider(height: 1),
        for (final template in rules.widgetTemplates)
          ListTile(
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: Text(template.title),
            onTap: () => Navigator.pop(
                context, widgetFromTemplate(template, character, rules, _newId())),
          ),
      ]),
    );
  }
}
