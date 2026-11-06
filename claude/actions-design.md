# Roll / Cast buttons, spell dice, hideable widget titles (session 16; written, not yet compiled)

Works in **every theme**. Overrides older lines in `play-design.md` (Round 3: "tap an item = card with Roll / Cast"; weapon and spell rolls) and `spells-design.md` (cast result) where they differ. Replaces the Warrior-only Attack / Damage buttons of session 15.

## Decisions (grill-me, session 16)
- **One Roll button per weapon**: attack and damage in one roll (the roll sheet shows the attack test and, under it, "Damage 9 (2d6+3)"). The separate Attack / Damage buttons and the damage-only roll were removed again (`ThemeLook.weaponButtons`, `WeaponRolls`, `RollRequest.damageOnly`, `attackOnlyRoll`, `damageOnlyRoll`).
- **One Cast button per spell** (mages) on the Play tab, in list and tiles style. Tapping the rest of the item still opens the bottom card (description, same button).
- **Sheet**: equipped weapons get the same Roll button under their numbers (`InfoRow.actions`).
- **Spell dice**: a cast also rolls the spell's effect dice (damage, healing, drained mana, per-turn damage ...). Dice are **data**: `effects` in `assets/rules/spells.json` (36 of the 108 spells; filled by reading every description). On a **failed test** the dice are still rolled but shown dimmed with a note; they update live when the TN or a die changes.
- **Homebrew spells**: the "+ New spell" form has an optional effect name and dice (one effect, flat bonus typed by hand).
- **Widget titles**: a Play widget can hide its title (eye button in edit mode). A hidden or blank title means no header while playing: only the items show, and the items start close to the top edge. **Edit mode always shows the header** (its controls), so content shifts down a little while editing.

## Spell effect data
`SpellEffect {label, dice, perMana?, plus?}` in `lib/rules/models/spell.dart`:
- `label`: text shown ("Damage", "Healing each turn").
- `dice`: `"2d6"` or `"1d6+1"` (d6 only, like `DamageRoll`).
- `perMana`: the dice count again for every this many mana spent: Heal `1` (1d6 per MP, 3 MP = 3d6), Group Heal `3` (1d6 per 3 MP, 9 MP = 3d6). Armor strain is not counted. Missing = once.
- `plus`: an ability whose value is added: `"magic"` (most damage spells) or `"willpower"` (Lingering Mark, Spirit Mark).
- Not data: "+ the casting roll's Dragon Die" (Arcane Bolt: said in the label), "half your Magic" (Ensnare), dice that depend on a target's test result (written as separate lines, e.g. Hemorrhage "if the test fails / succeeds").
- Edit by hand in `spells.json`; `test/spell_effects_test.dart` checks every effect can be rolled.

## Code
- `lib/shared/action_button.dart` (`ActionButton`): the Roll / Cast button. Used by `play_item_view.dart` (items of type weapon / spell with an action) and `combat_section.dart`.
- `lib/character/magic.dart`: `effectFormula(effect, mana:, bonus:)` (pure, tested) and `spellDiceLines(character, spell, mana)`.
- `lib/character/damage_roll.dart`: `DiceLine(label, formula)`.
- `lib/features/roll/roll_request.dart`: `effects` (list of `DiceLine`) and `effectsNeedSuccess`. `roll_sheet.dart` rolls one `DamageRoll` per line (weapon damage first, then effects); tap a die to type it; Re-roll rolls everything. `cast_spell.dart` passes `spellDiceLines(...)` with the base mana (the cost you chose, without armor strain) and `effectsNeedSuccess: true`. `weapon_roll.dart`: `weaponRoll`.
- `lib/character/character.dart`: `PlayWidgetData.showTitle` (default true, old saves keep their titles) and `hasHeader` (shown and not blank); `play_items.dart`: `setWidgetTitleShown`. `play_widget_card.dart`: header only if `editing || hasHeader`; eye button (not on Lore tiles, whose title is the entry name); a blank title is now saved (hint "Title").
- Strings: `effectLine`, `effectsFailed`, `spellEffectName`, `spellEffectDice`, `diceFormatHelp`, `showWidgetTitle`, `hideWidgetTitle`, `widgetTitleHint`. Removed: `attackButton`, `damageRollTitle`.
- Tests: `spell_effects_test.dart`, `widget_title_test.dart`; `theme_look_test.dart` updated.

## Known simplifications
- Per-turn / conditional dice are all rolled once at the cast, as separate labelled lines; nothing tracks rounds.
- `Spell.effects` has both a constructor default and a `@JsonKey(defaultValue)`, so json_serializable prints a warning in `-b` (harmless; it keeps every `Spell(...)` call working).
- The project copies `rules/data/spells.json` and `spells.json` in the Claude Project do not have `effects` yet; the file in the app's `assets/rules/` is the source of truth.
- Files to delete by hand: `lib/shared/weapon_buttons.dart` (now a one-line stub).
