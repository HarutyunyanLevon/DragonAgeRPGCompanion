import '../rules/models/spell.dart';
import '../rules/rules_data.dart';
import '../shared/display_name.dart';
import 'character.dart';
import 'play_layout.dart' show clampInt;

/// Operations on the Play widgets and their items, as pure functions: filling
/// the default widgets, the list of things that can be added, and the edits
/// (add, remove, move, rename). Nothing here knows about screens.

// Item types and the keys of the "stat" item.
const itemTypes = [
  'ability', 'focus', 'weapon', 'spell', 'stat', 'talent', 'specialization',
  'language', 'trait', 'gear', //
  'text', 'checkbox', 'counter', 'resource', 'roll',
];
const freeItemTypes = ['text', 'checkbox', 'counter', 'resource', 'roll'];

const statKeys = [
  'class', 'health', 'mana', 'defense', 'speed', 'armor', 'penalty', 'move', 'charge',
  'run', 'level', 'xp', 'money', //
];

/// The ref of a focus item.
String focusRef(String ability, String focus) => '$ability/$focus';

/// Splits the ref of a focus item into (ability, focus).
(String, String) splitFocusRef(String ref) {
  final parts = ref.split('/');
  return (parts.first, parts.length > 1 ? parts[1] : '');
}

// ---- Default widgets ----

/// The widgets of a character that has none yet: every template, with its
/// "*" items replaced by what the character has.
List<PlayWidgetData> materializeWidgets(Character character, RulesData rules) =>
    [
      for (final template in rules.widgetTemplates)
        template.copyWith(items: [
          for (final item in template.items)
            ..._expand(item, character, rules),
        ]),
    ];

/// One new widget made from a template (a fresh id, so a template can be
/// added more than once).
PlayWidgetData widgetFromTemplate(PlayWidgetData template, Character character,
        RulesData rules, String id) =>
    PlayWidgetData(
      id: id,
      title: template.title,
      style: template.style,
      items: [for (final item in template.items) ..._expand(item, character, rules)],
    );

List<PlayItem> _expand(PlayItem item, Character c, RulesData rules) {
  if (item.type == 'stat' && item.ref == 'mana' && c.maxMana == 0) return [];
  // "ability/*": every focus of that ability.
  if (item.type == 'focus' && item.ref.endsWith('/*')) {
    final ability = item.ref.substring(0, item.ref.length - 2);
    return [
      for (final f in c.focuses)
        if (f.ability == ability)
          PlayItem(type: 'focus', ref: focusRef(f.ability, f.focus)),
    ];
  }
  if (item.ref != '*') return [item];

  PlayItem make(String ref) => PlayItem(type: item.type, ref: ref);
  return switch (item.type) {
    'ability' => [for (final a in rules.backgrounds.abilities) make(a)],
    'focus' => [for (final f in c.focuses) make(focusRef(f.ability, f.focus))],
    'weapon' => [
        for (final i in c.inventory)
          if (i.equipped && rules.weaponById(i.itemId) != null) make(i.itemId!),
      ],
    'spell' => [for (final id in c.spellIds) make(id)],
    'talent' => [for (final t in c.talents) make(t.id)],
    'specialization' => [for (final s in c.specializations) make(s.id)],
    'language' => [for (final l in c.languages) make(l)],
    'trait' => [for (final t in c.traitIds) make(t)],
    _ => [],
  };
}

// ---- What can be added ----

/// The groups of the add-item list, in display order.
enum ItemGroup {
  abilities, focuses, weapons, spells, stats, talents, specializations,
  languages, traits, gear,
}

/// One thing the add-item list offers: a ready item with its names.
class ItemOption {
  const ItemOption(this.group, this.name, this.item);

  final ItemGroup group;
  final String name;
  final PlayItem item;
}

/// Everything on the character that can become an item. [spells] are all
/// spells (book and homebrew) so the known ones can be named.
List<ItemOption> itemOptions(
    Character c, RulesData rules, List<Spell> spells) {
  PlayItem of(String type, String ref) => PlayItem(type: type, ref: ref);

  return [
    for (final a in rules.backgrounds.abilities)
      ItemOption(ItemGroup.abilities, displayName(a), of('ability', a)),
    for (final f in c.focuses)
      ItemOption(
          ItemGroup.focuses,
          '${displayName(f.ability)} (${displayName(f.focus)})',
          of('focus', focusRef(f.ability, f.focus))),
    for (final i in c.inventory)
      if (rules.weaponById(i.itemId) != null)
        ItemOption(ItemGroup.weapons, i.name, of('weapon', i.itemId!)),
    for (final s in spells)
      if (c.spellIds.contains(s.id))
        ItemOption(ItemGroup.spells, s.name, of('spell', s.id)),
    for (final key in statKeys)
      if (key != 'mana' || c.maxMana > 0)
        ItemOption(ItemGroup.stats, displayName(key), of('stat', key)),
    for (final t in c.talents)
      ItemOption(ItemGroup.talents, rules.talents.talentById(t.id).name,
          of('talent', t.id)),
    for (final s in c.specializations)
      ItemOption(
          ItemGroup.specializations,
          rules.specializations.specializationById(s.id).name,
          of('specialization', s.id)),
    for (final l in c.languages)
      ItemOption(ItemGroup.languages, displayName(l), of('language', l)),
    for (final t in c.traitIds)
      ItemOption(ItemGroup.traits, displayName(t), of('trait', t)),
    for (final i in c.inventory)
      if (i.itemId != null)
        ItemOption(ItemGroup.gear, i.name, of('gear', i.itemId!)),
  ];
}

// ---- Edits ----

List<PlayWidgetData> _changeWidget(List<PlayWidgetData> widgets, String id,
        PlayWidgetData Function(PlayWidgetData) change) =>
    [for (final w in widgets) w.id == id ? change(w) : w];

List<PlayWidgetData> renameWidget(
        List<PlayWidgetData> widgets, String id, String title) =>
    _changeWidget(widgets, id, (w) => w.copyWith(title: title));

List<PlayWidgetData> setWidgetTitleShown(
        List<PlayWidgetData> widgets, String id, bool shown) =>
    _changeWidget(widgets, id, (w) => w.copyWith(showTitle: shown));

List<PlayWidgetData> setWidgetStyle(
        List<PlayWidgetData> widgets, String id, String style) =>
    _changeWidget(widgets, id, (w) => w.copyWith(style: style));

List<PlayWidgetData> addItem(
        List<PlayWidgetData> widgets, String id, PlayItem item) =>
    _changeWidget(widgets, id, (w) => w.copyWith(items: [...w.items, item]));

List<PlayWidgetData> replaceItem(
        List<PlayWidgetData> widgets, String id, int index, PlayItem item) =>
    _changeWidget(
        widgets,
        id,
        (w) => w.copyWith(items: [
              for (var i = 0; i < w.items.length; i++)
                i == index ? item : w.items[i],
            ]));

List<PlayWidgetData> removeItem(
        List<PlayWidgetData> widgets, String id, int index) =>
    _changeWidget(
        widgets,
        id,
        (w) => w.copyWith(items: [
              for (var i = 0; i < w.items.length; i++)
                if (i != index) w.items[i],
            ]));

/// Takes the item at [fromIndex] of one widget and puts it at [toIndex] of
/// another (or the same) widget. [toIndex] counts in the list as it is
/// before the move; use the length of the target to append.
List<PlayWidgetData> moveItem(List<PlayWidgetData> widgets, String fromId,
    int fromIndex, String toId, int toIndex) {
  final item = widgets.firstWhere((w) => w.id == fromId).items[fromIndex];
  final sameList = fromId == toId;
  // Removing an earlier item shifts the target of the same list up by one.
  final target = sameList && fromIndex < toIndex ? toIndex - 1 : toIndex;

  final removed = removeItem(widgets, fromId, fromIndex);
  return _changeWidget(removed, toId, (w) {
    final items = [...w.items];
    items.insert(clampInt(target, 0, items.length), item);
    return w.copyWith(items: items);
  });
}

// ---- Saved layouts ----

/// The presets with [name] saved (a preset with the same name is replaced),
/// holding the character's current widgets and places.
List<PlayPreset> savePreset(Character c, String name) {
  final preset = PlayPreset(
    name: name,
    widgets: c.playWidgets ?? const [],
    layouts: c.playLayouts,
  );
  return [
    for (final p in c.playPresets ?? const <PlayPreset>[])
      if (p.name != name) p,
    preset,
  ];
}

/// The character with the widgets and places of [preset].
Character loadPreset(Character c, PlayPreset preset) =>
    c.copyWith(playWidgets: preset.widgets, playLayouts: preset.layouts);

List<PlayPreset> removePreset(Character c, String name) => [
      for (final p in c.playPresets ?? const <PlayPreset>[])
        if (p.name != name) p,
    ];

List<PlayPreset> renamePreset(Character c, String name, String newName) => [
      for (final p in c.playPresets ?? const <PlayPreset>[])
        if (p.name == name) p.copyWith(name: newName) else p,
    ];
