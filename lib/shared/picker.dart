import 'package:flutter/material.dart';

/// A dropdown with type-to-filter, full width. [initial] is shown before the
/// player picks anything.
class Picker<T> extends StatelessWidget {
  const Picker({
    super.key,
    required this.label,
    required this.entries,
    required this.onSelected,
    this.initial,
    this.errorText,
  });

  final String label;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onSelected;
  final T? initial;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownMenu<T>(
        label: Text(label),
        errorText: errorText,
        initialSelection: initial,
        expandedInsets: EdgeInsets.zero,
        enableFilter: true,
        dropdownMenuEntries: entries,
        onSelected: onSelected,
      ),
    );
  }
}
