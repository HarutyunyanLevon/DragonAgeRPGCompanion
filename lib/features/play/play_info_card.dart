import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// What the bottom card shows: the description of the tapped item and, for
/// things that can be rolled or cast, a button.
class PlayInfo {
  const PlayInfo({
    required this.title,
    this.details,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget? details;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// The item whose card is open, or null. Tapping an item sets it.
final playInfoProvider = StateProvider<PlayInfo?>((ref) => null);

/// A card that floats at the bottom of the Play tab. The grid stays usable
/// behind it; tapping another item replaces it.
class PlayInfoCard extends ConsumerWidget {
  const PlayInfoCard({super.key, required this.info});

  final PlayInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.4;

    void close() => ref.read(playInfoProvider.notifier).state = null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Card(
          margin: const EdgeInsets.all(8),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text(info.title, style: text.titleMedium)),
                IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close),
                  onPressed: close,
                ),
              ]),
              if (info.details != null)
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SingleChildScrollView(
                      child: Align(
                          alignment: Alignment.centerLeft, child: info.details),
                    ),
                  ),
                ),
              if (info.onAction != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () {
                        close();
                        info.onAction!();
                      },
                      child: Text(info.actionLabel ?? ''),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
