import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../character/character.dart';
import '../../character/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../rules/rules_data.dart';
import '../../shared/amount_dialog.dart';
import '../sheet/money_dialog.dart';
import 'play_info_card.dart';
import 'shown_item.dart';

/// One item of a Play widget, as a row ("list" style) or a small box
/// ("tiles" style). Text that is too wide for its space is scaled down.
/// [onChanged] is told when the item itself changes (a counter, a checkbox).
class PlayItemView extends ConsumerWidget {
  const PlayItemView({
    super.key,
    required this.item,
    required this.character,
    required this.rules,
    required this.tiles,
    required this.tileWidth,
    required this.onChanged,
  });

  final PlayItem item;
  final Character character;
  final RulesData rules;
  final bool tiles;

  /// The width of a tile, already limited to the widget's width.
  final double tileWidth;
  final void Function(PlayItem item) onChanged;

  static const _stepper = {'health', 'mana'};

  void _saveCharacter(WidgetRef ref, Character changed) =>
      ref.read(charactersProvider.notifier).save(changed);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = character;
    final shown = showItem(context, ref, item, c, rules);

    // A tap opens the bottom card (description, Roll / Cast button).
    final openCard = shown.hasCard
        ? () => ref.read(playInfoProvider.notifier).state = PlayInfo(
              title: shown.title,
              details: shown.details,
              actionLabel: shown.actionLabel,
              onAction: shown.onAction,
            )
        : null;

    Widget box({String? value, Widget? control, VoidCallback? onTap}) => tiles
        ? _Tile(
            width: tileWidth,
            title: shown.title,
            value: value ?? shown.value,
            subtitle: shown.subtitle,
            control: control,
            onTap: onTap ?? openCard,
            dim: shown.missing,
          )
        : _Row(
            title: shown.title,
            value: value ?? shown.value,
            subtitle: shown.subtitle,
            control: control,
            onTap: onTap ?? openCard,
            dim: shown.missing,
          );

    switch (item.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: tiles ? double.infinity : null,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (item.name.isNotEmpty)
                Text(item.name, style: Theme.of(context).textTheme.titleSmall),
              if (item.text.isNotEmpty) Text(item.text),
            ]),
          ),
        );

      case 'checkbox':
        return box(
          control: Checkbox(
            value: item.checked,
            onChanged: (on) => onChanged(item.copyWith(checked: on ?? false)),
          ),
          onTap: () => onChanged(item.copyWith(checked: !item.checked)),
        );

      case 'counter':
        return box(
          value: '${item.value}',
          control: _Stepper(
            onMinus: () => onChanged(item.copyWith(value: item.value - 1)),
            onPlus: () => onChanged(item.copyWith(value: item.value + 1)),
          ),
        );

      case 'resource':
        void change(int amount) => onChanged(item.copyWith(
            value: max(0, min(item.max, item.value + amount))));

        return box(
          value: '${item.value} / ${item.max}',
          control: _Stepper(onMinus: () => change(-1), onPlus: () => change(1)),
          onTap: () async {
            final amount = await askAmount(context, shown.title);
            if (amount != null) change(amount);
          },
        );

      case 'stat' when _stepper.contains(item.ref):
        final isHealth = item.ref == 'health';
        final current = isHealth ? c.health : c.mana;
        final maxValue = isHealth ? c.maxHealth : c.maxMana;
        void change(int amount) {
          final next = max(0, min(maxValue, current + amount));
          _saveCharacter(ref,
              isHealth ? c.copyWith(health: next) : c.copyWith(mana: next));
        }

        return box(
          control: _Stepper(onMinus: () => change(-1), onPlus: () => change(1)),
          onTap: () async {
            final amount = await askAmount(context, shown.title);
            if (amount != null) change(amount);
          },
        );

      case 'stat' when item.ref == 'money':
        return box(onTap: () async {
          final copper = await showMoneyDialog(context, c.copper);
          if (copper != null) _saveCharacter(ref, c.copyWith(copper: copper));
        });

      default:
        return box();
    }
  }
}

/// A row: the title (scaled down if too wide), an optional line under it,
/// the value and an optional control at the right.
class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.value,
    this.subtitle,
    this.control,
    this.onTap,
    this.dim = false,
  });

  final String title;
  final String? value;
  final String? subtitle;
  final Widget? control;
  final VoidCallback? onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Scaled(alignment: Alignment.centerLeft, child: Text(title)),
                if (subtitle != null) Text(subtitle!, style: text.bodySmall),
              ]),
            ),
            if (value != null)
              Flexible(
                child: _Scaled(
                    alignment: Alignment.centerRight,
                    child: Text(value!, style: text.titleMedium)),
              ),
            if (control != null) control!,
          ]),
        ),
      ),
    );
  }
}

/// A small box: title on top, value below, an optional control at the bottom.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.width,
    required this.title,
    this.value,
    this.subtitle,
    this.control,
    this.onTap,
    this.dim = false,
  });

  final double width;
  final String title;
  final String? value;
  final String? subtitle;
  final Widget? control;
  final VoidCallback? onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: SizedBox(
        width: width,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              _Scaled(child: Text(title, style: text.labelSmall)),
              if (value != null) _Scaled(child: Text(value!, style: text.titleLarge)),
              if (subtitle != null) _Scaled(child: Text(subtitle!, style: text.bodySmall)),
              if (control != null) control!,
            ]),
          ),
        ),
      ),
    );
  }
}

/// Makes text smaller when it is wider than the space it has.
class _Scaled extends StatelessWidget {
  const _Scaled({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: child,
      );
}

/// - and + buttons.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.onMinus, required this.onPlus});

  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: onMinus,
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.add_circle_outline),
        onPressed: onPlus,
      ),
    ]);
  }
}
