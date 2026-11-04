import '../l10n/app_localizations.dart';

/// Small text helpers for the screen.

/// Turns a rules id into text: "trade-tongue" -> "Trade Tongue".
/// Used where the rules JSON has no separate display name.
String displayName(String id) => id
    .split('-')
    .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// "traveler's garb" -> "Traveler's garb".
String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// A bonus with its sign: 3 -> "+3", -1 -> "-1".
String signed(int value) => value >= 0 ? '+$value' : '$value';

/// 1 -> "Novice", 2 -> "Journeyman", 3 -> "Master".
String degreeName(AppLocalizations l10n, int degree) => [
      l10n.degreeNameNovice,
      l10n.degreeNameJourneyman,
      l10n.degreeNameMaster,
    ][degree - 1];
