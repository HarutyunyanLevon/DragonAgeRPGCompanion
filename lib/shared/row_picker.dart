import 'package:flutter/material.dart';

import 'info_row.dart';

/// A list of rows to pick from. The leading control picks the row; tapping
/// the rest of the row opens its description (several can be open).
///
/// With [limit] 1 the controls are radio buttons: picking a row replaces the
/// old pick. Otherwise they are checkboxes, disabled once [limit] is reached
/// (picked rows can still be unpicked).
class RowPicker extends StatelessWidget {
  const RowPicker({
    super.key,
    required this.options,
    required this.picked,
    required this.limit,
    required this.onChange,
    required this.describe,
  });

  /// (id, label) of every choice.
  final List<(String, String)> options;
  final List<String> picked;
  final int limit;

  /// Called with the new list of picked ids.
  final ValueChanged<List<String>> onChange;

  /// The description of the choice with this id.
  final Widget Function(String id) describe;

  void _pick(String id) {
    if (limit == 1) {
      onChange([id]);
    } else if (picked.contains(id)) {
      onChange([for (final other in picked) if (other != id) other]);
    } else {
      onChange([...picked, id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPicked = picked.contains;

    return Column(children: [
      for (final (id, label) in options)
        InfoRow(
          leading: limit == 1
              ? Radio<String>(
                  value: id,
                  groupValue: picked.isEmpty ? null : picked.first,
                  onChanged: (_) => _pick(id),
                )
              : Checkbox(
                  value: isPicked(id),
                  onChanged: isPicked(id) || picked.length < limit
                      ? (_) => _pick(id)
                      : null,
                ),
          title: label,
          child: describe(id),
        ),
    ]);
  }
}
