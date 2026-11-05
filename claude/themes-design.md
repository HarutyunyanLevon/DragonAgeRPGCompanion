# Themes (session 14: Part 1 written; Part 2 planned)

The app has six selectable themes. Part 1 (colors, fonts, picker, saving) is written. Part 2 (the signature shapes from the sketches) is not started.

## Sketches
Design artifact "Dragon Age Companion: 10 Fantasy Themes" (15 boards, the Play tab at phone size, a note under each board). The user chose these five, plus the old look:

| Theme id | Sketch | Look |
|---|---|---|
| `classic` | (the old look) | dark slate, gold, system serif headings |
| `chantry` | 01 Ashen Chantry | soot black, ember orange, crimson; Cinzel + Crimson Pro; arched tiles, stained-glass fill bars |
| `manuscript` | 02 Illuminated Manuscript | **light** parchment, ink, lapis, rubric red; IM Fell English + Cormorant Garamond; drop cap, ribbon bars, gold-leaf number roundels, bookmark tabs |
| `tavern` | 06 Storybook Tavern | dark wood, brass, heart red; Fondamento + Alegreya; taped cream paper cards, heart / star pips, brass tab tags |
| `antivan` | 10 Antivan Masquerade | burgundy black, gold, ivory; Italiana + Playfair Display; double gold frame, medallion gauges, mask motif, centered layout |
| `warrior` | 11 Class: Warrior | charcoal, steel, crimson; Oswald + Source Serif 4; shield-shaped Defense / Armor / Speed plates, Attack and Damage buttons, stunt counter |

Not chosen (kept in the artifact for later): 03 Silverwood, 04 Dwarven Forge, 05 The Fade, 07 The Blight, 08 Warden Heraldry, 09 Frostback Ice, 12 Rogue, 13 Mage, 14 / 15 stained glass.

## Decisions (grill-me, session 14)
- **Warrior is a normal theme** anyone can pick, not tied to the character's class. (Switching automatically by class is easy to add later.)
- **The old look stays** as the `classic` theme and is the default.
- **Fonts: `google_fonts` package** (runtime download, cached; offline on the very first run falls back to the default font). Bundling the font files for fully offline use is a Part 2 task.
- **The picker** is the palette button next to "New character" in the characters window (every tab except the Glossary has the character button). A proper Settings page can come later.
- Tavern in Part 1 is dark wood only. The cream paper cards need per-card text colors, so they wait for Part 2. Keep the tilt out of the Play grid (it fights dragging and resizing); use it on the Sheet only.
- Warrior's crimson is lighter than in the sketch (`0xFFD7363C`) so white text on it and the red itself stay readable.

## Code (Part 1)
- `lib/shared/theme_specs.dart`: `AppThemeId` (the saved name; do not rename values), `ThemeSpec` (plain data: colors, fonts, `fontScale`), `themeSpecs` (**edit a theme's numbers here**), `colorSchemeFor` (pure, tested).
- `lib/shared/theme.dart`: `buildTheme(AppThemeId)`: color scheme, Google Fonts (body font everywhere, heading font on headlineMedium / headlineSmall / titleLarge), app bar, tab bar and rail. A wrong font name is caught and the plain font is used.
- `lib/shared/theme_provider.dart`: `themeIdProvider` (AsyncNotifier, loads and saves the choice).
- `lib/character/settings_storage.dart`: `loadThemeId` / `saveThemeId`. **Saving one value now keeps the others** (it used to overwrite the file). `settingsStorageProvider` in `providers.dart` is now public.
- `lib/features/settings/theme_picker.dart`: bottom sheet with a swatch, name and one line per theme; the app changes at once.
- `lib/main.dart`: `CompanionApp` is a `ConsumerWidget` and watches the theme. Until the saved theme loads, the classic look shows for a moment.
- Strings: `app_en.arb` keys `themeButton`, `themeTitle`, `themeClassic` ... `themeWarriorAbout`.
- Tests: `test/theme_specs_test.dart` (every theme has a spec; contrast: text on page >= 7, text on buttons >= 4.5, accent and borders on page >= 3), `test/settings_storage_test.dart`.

## How to add a theme
1. Add a value to `AppThemeId` and a `ThemeSpec` to `themeSpecs`.
2. Add `themeX` and `themeXAbout` to `app_en.arb`, and the two cases in `theme_picker.dart` (`_name`, `_about`).
3. `python build.py -g -t`. The contrast test tells you if the colors are unreadable.

## Part 2 plan (not started)
The sketches get their character from shapes, not colors. Plan: a `ThemeExtension` (say `ThemeLook`) per theme with a few tokens, and themed versions of the few widgets that draw the Play tab:
- **Health / mana bar**: plain, ribbon (manuscript), heart and star pips (tavern), medallion circle (antivan), big number with plate (warrior), stained-glass vial (chantry).
- **Ability tile**: arch top (chantry), gold-leaf roundel (manuscript), pill (tavern), arch with gold border (antivan), flat with bottom line (warrior).
- **Play widget card frame**: corner radius / border / double frame / paper.
- Places to change: `features/play/play_widget_card.dart`, `shared/stat_tiles.dart`, `shared/sheet_box.dart`, `shared/app_shell.dart` (tab bar look), the Sheet header.
- Cormorant looks small: tune `fontScale` after seeing it on a phone.
- Bundle the fonts (google_fonts supports font files in an assets folder: no download, works offline).
- Maybe: a real Settings page; theme per character.
- Do one theme at a time, show it, then the next. Suggested order: warrior (flattest), chantry, antivan, manuscript, tavern.
