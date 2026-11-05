import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A piece of a text ([start] to [end]) that links to another entry [target].
class LinkMatch {
  const LinkMatch(this.start, this.end, this.target);

  final int start;
  final int end;
  final String target;
}

/// Tells every [LinkedText] below it which parts of a text are links and what
/// to do when one is tapped. Without a [TextLinks] above, [LinkedText] is
/// plain text, so the Sheet and the wizard are not affected.
class TextLinks extends InheritedWidget {
  const TextLinks({
    super.key,
    required this.find,
    required this.onOpen,
    required super.child,
  });

  /// The links in a text, in order and without overlaps.
  final List<LinkMatch> Function(String text) find;
  final void Function(String target) onOpen;

  static TextLinks? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextLinks>();

  @override
  bool updateShouldNotify(TextLinks oldWidget) =>
      find != oldWidget.find || onOpen != oldWidget.onOpen;
}

/// Text with tappable links (see [TextLinks]). An optional bold [label] comes
/// first, as "Label: text".
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {super.key, this.label, this.style});

  final String text;
  final String? label;
  final TextStyle? style;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  // One tap recognizer per link; they must be disposed.
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final links = TextLinks.maybeOf(context);
    final matches = links?.find(widget.text) ?? const <LinkMatch>[];
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    final spans = <InlineSpan>[];
    if (widget.label != null) {
      spans.add(TextSpan(
          text: '${widget.label}: ',
          style: const TextStyle(fontWeight: FontWeight.bold)));
    }

    var position = 0;
    for (final match in matches) {
      if (match.start > position) {
        spans.add(TextSpan(text: widget.text.substring(position, match.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => links!.onOpen(match.target);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: widget.text.substring(match.start, match.end),
        style: linkStyle,
        recognizer: recognizer,
      ));
      position = match.end;
    }
    if (position < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(position)));
    }

    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
