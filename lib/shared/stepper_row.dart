import 'package:flutter/material.dart';

/// A label with -1 / +1 buttons around a [value] text. [onChanged] gets -1 or +1.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final void Function(int change) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(label)),
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () => onChanged(-1),
      ),
      SizedBox(
        width: 40,
        child: Text(value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => onChanged(1),
      ),
    ]);
  }
}
