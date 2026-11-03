# Dragon Age Companion

Companion app for the Dragon Age RPG (Green Ronin core rulebook). Flutter.

## Building

Everything goes through one script (needs Python and Flutter on your PATH):

    python build.py              pub get + build_runner + gen-l10n
    python build.py -g           only gen-l10n (after editing lib/l10n/app_en.arb)
    python build.py -b           only build_runner (after editing a model with @JsonSerializable)
    python build.py -t           prepare, then run the tests
    python build.py -win         prepare, then run the app on Windows
    python build.py -t -win      prepare, tests, then run the app
    python build.py -a           prepare, then run the app on an Android device

Steps run in that order and the script stops at the first failure.

## Folders

- `lib/rules/` loads the rules JSON from `assets/rules/` (all rulebook data lives there, not in code).
- `lib/character/` the character model, saving, and rule calculations (pure functions).
- `lib/features/<name>/` one folder per screen area (create, characters, play, sheet).
- `lib/shared/` theme, app shell, small widgets used everywhere.
- `lib/l10n/app_en.arb` every text shown on screen.
