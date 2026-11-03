/// Turns a display name into the id style used in the rules JSON files.
/// "Winter’s Grasp" -> "winters-grasp", "Light Blades" -> "light-blades".
String slug(String name) {
  final lower = name.toLowerCase().replaceAll('’', '').replaceAll("'", '');
  return lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
