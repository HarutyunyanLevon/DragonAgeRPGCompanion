# Lore tab (session 12, graph redesign session 13) - design and decisions

Written without a Dart compiler. Needs `python build.py` (the **full** run once: `pub get` for the new `file_picker` package, then build_runner for `lore.g.dart`, `lore_data.g.dart`, `character.g.dart`, and gen-l10n for ~35 new ARB keys), then `python build.py -t -win`.

**This file replaces the "Lore design (decided session 2)" lines in STATUS.md where they differ** (the graph no longer holds every entry; see below).

## Decisions (grill-me)
- **One tab, two modes**, switched at the top (SegmentedButton): **Codex** and **Graph**. Both stay alive (`IndexedStack`), so the Codex keeps its search and the graph keeps its zoom.
- **Codex** = the list of all lore entries (217 book entries from `lore.json` + the player's own). Search (name, text, section, note), **tag chips** (any-of; the six book tags + own tags), entries **grouped by section** ("My entries" first). Wide screens (900+ px): list left, open entry right. App bar: back / forward / list (same history class as the Glossary: `GlossaryHistory`), then the character button.
- **Entry page**: name, section, tag chips, text, **"See also" chips** (the entry's links) and **names inside the text are links too** (`NameLinker`, shared with the Glossary; name variants: without "(...)", without leading "The", the part before a comma). Links in the Codex always open another entry in the Codex. Buttons: Add to graph / Remove from graph, Edit, Delete (own entries only).
- **Graph** (redesigned in session 13: a **corkboard of tiles**) = only the entries the player pinned. One graph per character.
  - **Endless**: no limits, no clamping. `InteractiveViewer` over a 100000 px canvas with `boundaryMargin: infinity`, zoom 0.1x-2.5x; saved coordinates are relative to (0, 0) in the middle of the canvas (`_origin`, negative values are fine). The cork background is **painted in screen space** from the view matrix (`_CorkPainter`), so it never ends. A **"show everything" button** (bottom right) zooms to all tiles; the view also fits the tiles the first time.
  - **Tile** = the Play card (`PlayWidgetCard`) of the entry: title = entry name, **free items only** (text, checkbox, counter, resource, roll) stored per node (`GraphNode.items`, `style` list / tiles, `width`, `height`; old saves get defaults). Under the items: tag color dots and the **weak links as chips** (links to entries not on the graph; tap = card with Open in Codex / Add to graph). No more ring nodes or bubbles.
  - **Pin** (red) at the top middle of every tile; **strings** are red hanging curves from pin to pin (with a soft shadow). Tap a pin = start a string, tap another pin or tile title = ties it (optional label; the banner at the top shows what is going on). One string per pair; tap the dot / label in the middle of a string to edit or delete it.
  - **Tap a tile title** = the entry card (Open in Codex, Link to..., Remove from graph).
  - **Edit mode** = the **pencil in the app bar** (graph mode only), for all tiles at once, like Play: item menus, drag items (also between tiles), + Add item (free items only), list / tiles style, delete (= remove from graph), a **drag handle in the title row to move** the tile and a **corner handle to resize** it (minimum 140 x 100). Outside edit mode items are live (counters, checkboxes) and dragging pans the board.
  - **Organize** (app bar button, graph mode): `organizeNodes` puts all tiles in tidy rows, no overlaps. Tiles that belong together (a string between them, or a link between their entries) are kept together (breadth-first groups, biggest group first, each group starts a new row); sizes stay; the whole set stays around the same middle.
  - A new tile lands **next to an already pinned entry it is linked with**, else around the middle of the tiles, on the first free cell (`pinEntry`, spiral of tile-sized cells).
  - **A new entry made with "+" while in Graph mode is pinned automatically** (`showLoreEntryDialog(pin: true)`).
- **Entries of the player**: "+" in the toolbar: name, text, tags, links (picker with search; **suggested links** = names found in the typed text). Edit / delete from the entry page. Deleting removes its node, strings and links to it.
- **Book entries** stay read-only; Edit opens only what the player can add: **extra tags, extra links, a private note** (`LoreAddition`). Tags / links the book gives cannot be removed.
- **Tags**: six book tags + own. **"New tag" in three places**: a "+ New tag" chip in the entry form (the tag is kept only if the entry is saved, and is selected), a "+ New tag" chip at the end of the Codex filter chips, and "New tag" in the three-dot menu (`new_tag_dialog.dart`, `createTag` = next default palette color). Menu (three dots) -> "Tags and colors": tap a dot to change **any** tag's color (book tags too), add a tag, delete an own tag (removed from everything). **Color picker**: palette swatches (10 defaults + the player's own) and "+" = **hex field (#RRGGBB)** that adds the color to the palette (no package).
- **Storage**: inside the character (`Character.lore`, null = nothing yet), so the character export carries it. Nothing is stored in a shared file.
- **Export / import lore** (menu): saves / reads a JSON file with the character's `LoreData` (`file_picker`, used only in `lib/shared/file_dialogs.dart`). Import **merges**: what the file has and the character does not is added; same ids stay as they are; additions are united; tag colors of the character win.
- Not built (decided later / YAGNI): Lore items in Play widgets (next small step), header search "In my lore / In the rulebook", timeline, several graphs, search inside the graph, auto layout.

## Code map
- Data: `assets/rules/lore.json` (unchanged: `{tags, entries}`; entry `{id, name, tags, section, summary, links, source_page_pdf}`).
- `lib/rules/models/lore.dart`: `LoreTag`, `LoreEntry`, `LoreFile` (json_serializable). `RulesData.loreTags` / `loreEntries`, `RulesLoader.loadLore`.
- `lib/character/lore_data.dart`: the player's data, all immutable and JSON: `MyLoreEntry`, `LoreAddition`, `GraphNode`, `GraphString`, `LoreData` (`myEntries`, `additions`, `myTags`, `tagColors`, `palette`, `nodes`, `strings`; `LoreData.empty()`). `Character.lore` (optional, in `copyWith`).
- `lib/character/lore.dart` (**pure, tested**): `LoreItem` + `buildLoreItems`, `uniqueId`, tags and colors (`allTags`, `lorePalette`, `tagColorMap`, `parseHexColor`, `setTagColor`, `addTag`, `removeTag`, `addPaletteColor`), entries (`addMyEntry`, `replaceMyEntry`, `removeMyEntry`, `setAddition`), link names (`loreLinkNames`, `loreNameMap`, `suggestLinks`), graph (`pinEntry`, `moveNode`, `resizeNode`, `nodeWidgets` / `applyNodeWidgets` (tiles <-> Play widgets, so Play's `addItem` / `moveItem` edit them), `organizeNodes`, `unpinEntry`, `addString`, `setStringLabel`, `removeString`), `createTag`, `mergeLore`, `newLoreId`.
- `lib/shared/name_linker.dart`: `NameLinker` (the link-finding rules, moved out of the Glossary). `GlossaryLinker` is now a thin subclass (`features/glossary/glossary_links.dart`).
- `lib/shared/file_dialogs.dart`: `saveTextFile`, `pickTextFile` (the only file that knows `file_picker`).
- `lib/features/lore/`: `lore_page.dart` (app bar, mode switch, toolbar, menu), `lore_providers.dart` (`LoreMode`, `loreModeProvider`, `loreHistoryProvider`, `loreEditingProvider`, `LoreContext`, `loreProvider`, `saveLore`, `openInCodex`), `codex_view.dart`, `lore_entry_page.dart`, `lore_entry_dialog.dart`, `lore_item_picker.dart`, `tags_sheet.dart`, `color_dialog.dart`, `lore_widgets.dart` (`TagDot`, `TagChips`), `lore_graph_view.dart` (board, tiles, pins, strings, cork painter, cards), `new_tag_dialog.dart`, `lore_files.dart` (export / import).
- `app_shell.dart`: the Lore tab shows `LorePage`. `lib/shared/placeholder_page.dart` is now unused (delete by hand).
- ARB: `loreCodex` ... `loreImportFailed` (35 keys at the end of the file).
- **Changed in Play (session 13)**: `PlayWidgetCard` got `renamable`, `onTitleTap`, `freeOnly`, `footer`; `add_item_sheet.dart` got `pickFreeItem`. Play behaves as before.
- Test: `test/lore_test.dart` (lore.json is consistent, additions, tags / colors, hex, name links, tile placement, resize, tile items through Play widgets, organize, strings, deleting entries, createTag, JSON round trip, old nodes, import merge).

## Known simplifications / risks
- **Tile move / resize inside `InteractiveViewer`**: the handles' own pan gestures should win over the viewer's pan. If dragging a handle moves the whole board instead, the fix is in `lore_graph_view.dart` (`_tile`).
- Dragging on a tile body scrolls its items when they overflow instead of panning the board (pan on the cork or a title).
- Roll items open Play's bottom card (`playInfoProvider`, shared with the Play tab), shown in the Lore graph too; a card left open also shows in Play until closed.
- The cork speckles keep the same screen size at every zoom.
- `file_picker` API is from the package page (version 13: static `FilePicker.saveFile` / `pickFile`). If the compiler complains, fix only `lib/shared/file_dialogs.dart`. On Windows check that the saved file really has the text in it.
- Links between two pinned tiles are not drawn (no chip either); only the player's strings connect tiles.
- Link names: "King Maric" is not linked by "Maric" (only the name, the name without "The" / "(...)" and the part before a comma are). The See-also chips carry the curated links.
- Lore needs a selected character (like Play and Sheet); there is no lore without one.
- Not compiled: expect small compile errors.

## Open / next
1. **User**: `python build.py` (full run: new package), then `python build.py -t -win`. In the app: Lore tab -> Codex (search "orlais", tag chips, section groups, open Ferelden, tap a See-also chip and a link inside the text, back / forward), "+" new entry with a suggested link, Edit a book entry (extra tag, link, note), Tags and colors (change a color, new tag, hex color), Add to graph on several linked entries (they should land next to each other), switch to Graph: pencil -> add items to a tile, move and resize it, drag an item to another tile; tap a pin, then another pin -> label; tap a string; zoom far out and pan far away (the cork must never end) and use the "show everything" button; Organize; "+" in Graph mode (the new entry must appear as a tile); New tag in the entry form, the Codex chips and the menu; Export, Import into another character.
2. Next: Lore items in Play widgets, header search, Sheet edit mode, levels 11-20.
