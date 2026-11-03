/// Turns a rules id into text for the screen: "trade-tongue" -> "Trade Tongue".
/// Used where the rules JSON has no separate display name.
String displayName(String id) => id
    .split('-')
    .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
    .join(' ');
