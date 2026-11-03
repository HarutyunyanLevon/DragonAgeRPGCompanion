import '../l10n/app_localizations.dart';

/// Money is stored in copper: 1 sp = 100 cp, 1 gp = 100 sp = 10,000 cp.
const copperPerSilver = 100;
const copperPerGold = 10000;

/// Splits copper into gold, silver and copper.
({int gold, int silver, int copper}) splitCopper(int total) => (
      gold: total ~/ copperPerGold,
      silver: total % copperPerGold ~/ copperPerSilver,
      copper: total % copperPerSilver,
    );

int toCopper({int gold = 0, int silver = 0, int copper = 0}) =>
    gold * copperPerGold + silver * copperPerSilver + copper;

/// "1 gp 5 sp", "40 cp", "0 cp". Zero parts are left out.
String moneyText(AppLocalizations l10n, int total) {
  final parts = splitCopper(total);
  final texts = [
    if (parts.gold > 0) l10n.goldAmount(parts.gold),
    if (parts.silver > 0) l10n.silverAmount(parts.silver),
    if (parts.copper > 0) l10n.copperAmount(parts.copper),
  ];
  return texts.isEmpty ? l10n.copperAmount(0) : texts.join(' ');
}
