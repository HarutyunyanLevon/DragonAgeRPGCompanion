/// Where the Glossary has been, like the history of a web browser. A position
/// is an entry key, or null for the list. Opening something new drops
/// everything that was "forward".
class GlossaryHistory {
  const GlossaryHistory([this.stack = const [null], this.position = 0]);

  final List<String?> stack;
  final int position;

  String? get current => stack[position];
  bool get canGoBack => position > 0;
  bool get canGoForward => position < stack.length - 1;

  GlossaryHistory open(String? key) {
    if (key == current) return this;
    return GlossaryHistory([...stack.sublist(0, position + 1), key], position + 1);
  }

  GlossaryHistory back() =>
      canGoBack ? GlossaryHistory(stack, position - 1) : this;

  GlossaryHistory forward() =>
      canGoForward ? GlossaryHistory(stack, position + 1) : this;
}
