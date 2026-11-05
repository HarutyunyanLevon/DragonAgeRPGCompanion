# Glossary tab (session 11) - design and decisions

Written without a Dart compiler. Needs `python build.py -b -g -t -win` (build_runner for `glossary.g.dart`, gen-l10n for the new ARB keys).

## Decisions (grill-me)
- **Entries come from two sources**: a new hand-written `assets/rules/glossary.json` (78 paraphrased terms: dice and tests, stunt points, time and actions, combat, health and healing, magic and mishaps, characters, money) **and** the data already loaded (stunts, talents, specializations, focuses, gear catalog, spells incl. homebrew).
- **Notes** (title + text, editable, deletable) are stored in the **shared library** file `glossary_notes.json` (documents folder), same for every character. No categories on notes, no links between entries (YAGNI).
- **Layout like the Spells tab**: search field (matches title and description text), one filter chip per category (Terms, Stunts, Talents, Specializations, Focuses, Gear, Spells, My notes), expandable rows. 900+ px: list left, open entry right. A heading per category, a small heading per group (term topic, ability, gear category, school, class). **Works without a character.** `+` note button in the app bar.

## Code map
- Data: `assets/rules/glossary.json` = plain list `{topic, name, text}`. Edit or add terms there; ids come from the name (`slug`).
- `lib/rules/models/glossary.dart`: `GlossaryTerm` (+ `id`), `GlossaryNote {id, title, text}` (id = creation time in ms, so the title can change).
- `lib/rules/glossary_note_storage.dart` (`JsonListStorage`), `RulesData.glossaryTerms`, `RulesLoader.loadGlossary`.
- `lib/features/glossary/`: `glossary_entries.dart` (pure: `GlossaryCategory`, `GlossaryEntry`, `buildGlossary`), `glossary_notes.dart` (provider, add / update / remove), `glossary_entry_view.dart` (detail by category: reuses `TalentInfo`, `SpecializationInfo`, `FocusInfo`, `ItemInfo`, `SpellInfo`), `note_dialog.dart` (add / edit), `glossary_page.dart`.
- `app_shell.dart`: the Glossary tab shows `GlossaryPage` (only Lore is still a placeholder).
- ARB: `searchGlossary`, `glossaryTerms`, `glossaryStunts`, `glossaryGear`, `glossaryNotes`, `noGlossaryMatches`, `selectEntry`, `stuntCost`, `newNote`, `noteTitle`, `noteText`, `deleteNoteTitle` (`editItem`, `delete`, `save`, `cancel` reused).
- Test: `test/glossary_test.dart` (terms complete and unique, entries of every category, search by name / text, notes storage round trip).

## Known simplifications
- The list is a `ListView.builder` (about 650 rows with everything shown); rows in the phone layout are `InfoRow`s.
- The open entry in the wide layout is remembered by `GlossaryEntry.key` (category / group / title); two gear items with the same name in one category would share a selection.
- Spell stunts (magic.json) are not listed under Stunts yet; the standard ones are described by the term "Spell stunt".
- Term texts are paraphrased from the rules files; spot-check against the book like the other data (e.g. "Free action", "Outnumbering" values).
- `GlossaryTerm` topics are free text in the JSON; groups follow the order of the file.

## Open / next
1. **User**: `python build.py -b -g -t -win`, paste errors. In the app: Glossary tab, search "dragon", chips, open a talent / spell / gear row, add / edit / delete a note, homebrew spell shows under Spells, resize the window for the two-column layout.
2. Next: header search (Play, Sheet) or Lore tab.

---

# Round 2 (session 11, later): links, history, tables

Written without a Dart compiler. Needs `python build.py -b -g -t -win` (new ARB keys).

## Decisions (grill-me)
- **Links are automatic, with opt-outs.** `GlossaryLinker` (`glossary_links.dart`) finds names in any text: whole words, any case, optional plural "s", longest name first, **only the first mention of an entry per text**, never a link to the entry itself.
- **Link targets**: terms (and their `aliases`), stunts, classes, weapon groups, abilities, talents, specializations, spells. **Not** focuses, gear and notes (everyday words). Opt-outs in `glossary.json`: `"autoLink": false` (done for Move, Run, Ready, Aim, Activate, Charge, Defend, Cover, Turn, Round, Higher ground, Free action, Heal (action)); `"aliases": [...]` for other words ("TN", "XP", "classes"). A name with brackets is only reachable through its aliases.
- **Links appear everywhere in the Glossary tab**: term texts, stunt effects, notes, and inside the shared info widgets (talent, specialization, spell, gear, class, weapon group, ability). Mechanism: `shared/linked_text.dart` (`LinkedText`, `TextLinks`); the `_Line` of `rule_info.dart` is a `LinkedText`. Without a `TextLinks` above (Sheet, wizard) it is plain text, so those screens are unchanged.
- **Navigation = entry page + browser-like history.** Tapping a list row or a link opens that entry (`glossary_history.dart`, `glossaryHistoryProvider`). App bar: back, forward, list, new note. The list is history position 0; opening something new drops the forward entries. Phone: the list or the open entry fills the tab. Wide (900+ px): list left, open entry right. History lives as long as the app runs; no Android system-back or mouse-button handling yet.
- **Extra info blocks, built from game data** (`glossary_extras.dart`; a term names one in `"extra"`): classes, abilities, weapon-groups (all groups with attack / damage ability), xp-table (levels 1-20), advancement-cost, difficulties (TN), thresholds (advanced tests), attack-modifiers, healing, major-actions, minor-actions, mishaps (by Dragon Die), armor-strain, spell-stunts, schools. Names inside the tables link too. A class entry also has **Powers by level** (all 20 levels).
- **New categories (chips)**: Classes, Weapon groups, Abilities (entries from game data, shown with the existing `ClassInfo` / `WeaponGroupInfo` / `AbilityInfo`).

## Code map (new / changed)
- New: `shared/linked_text.dart`, `rules/models/rule_tables.dart` (+ `RulesData.ruleTables`, `RulesLoader.loadRuleTables`), `features/glossary/glossary_links.dart`, `glossary_history.dart`, `glossary_providers.dart` (entries, linker, history), `glossary_extras.dart`.
- Changed: `GlossaryTerm` (`aliases`, `autoLink`, `extra`), `GlossaryEntry` (`linkNames`, `key`), `glossary_entry_view.dart`, `glossary_page.dart` (rewritten), `rule_info.dart` (`_Line`), `glossary.json` (79 terms, 15 with a table), ARB (`glossaryBack` ... `levelN`, `col*`).
- Tests (`glossary_test.dart`): every `extra` is buildable, 3 classes and all weapon groups present, linker rules (aliases, plurals, first mention, self, opt-out, longest name), history, notes storage.

## Known simplifications
- Page titles repeat inside some info widgets (they print their own title).
- Common words that are also entry names (spell "Heal", ability "Magic", term "Health") become links on their first mention in a text; add `autoLink: false` to a term to stop that. Spell and ability names have no opt-out yet.
- Links from the Sheet, Spells tab and wizard into the Glossary are not built (the Glossary is its own island).

## Open / next
1. **User**: `python build.py -b -g -t -win`, paste errors. In the app: open "Class", tap Warrior, back / forward, "Level and XP" table, "Magical mishap" table, "Weapon group" list, a spell with linked words, a note that mentions a term.
2. Next: header search or Sheet edit mode or Lore tab.
