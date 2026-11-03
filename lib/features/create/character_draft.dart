import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rules/models/backgrounds.dart';

/// The character being built by the creation wizard. Nothing is saved until
/// the last step. The draft is thrown away when the wizard closes.
class CharacterDraft {
  const CharacterDraft({
    this.name = '',
    this.background,
    this.customBackground,
    this.race,
    this.caste,
    this.classId,
  });

  final String name;

  /// The chosen background: from the book, or [customBackground].
  final Background? background;

  /// The background the player made up in this wizard, if any.
  final Background? customBackground;

  /// Fixed by the background, or picked when the background allows a choice.
  final String? race;
  final String? caste;
  final String? classId;

  /// Everything step 1 asks for has an answer.
  bool get isComplete =>
      name.trim().isNotEmpty &&
      background != null &&
      race != null &&
      (background!.casteChoices.isEmpty || caste != null) &&
      classId != null;

  /// Changes the given fields. (Cannot clear a field: see selectBackground.)
  CharacterDraft copyWith({
    String? name,
    String? race,
    String? caste,
    String? classId,
  }) =>
      CharacterDraft(
        name: name ?? this.name,
        background: background,
        customBackground: customBackground,
        race: race ?? this.race,
        caste: caste ?? this.caste,
        classId: classId ?? this.classId,
      );
}

class CharacterDraftNotifier extends AutoDisposeNotifier<CharacterDraft> {
  @override
  CharacterDraft build() => const CharacterDraft();

  void setName(String name) => state = state.copyWith(name: name);
  void setRace(String race) => state = state.copyWith(race: race);
  void setCaste(String caste) => state = state.copyWith(caste: caste);
  void setClass(String classId) => state = state.copyWith(classId: classId);

  /// Choosing a background clears what depended on the previous one.
  /// Pass [custom] when the player has just made a new custom background.
  void selectBackground(Background background, {Background? custom}) {
    state = CharacterDraft(
      name: state.name,
      background: background,
      customBackground: custom ?? state.customBackground,
      race: background.raceChoice ? null : background.races.first,
      classId: background.classes.contains(state.classId) ? state.classId : null,
    );
  }
}

final characterDraftProvider =
    NotifierProvider.autoDispose<CharacterDraftNotifier, CharacterDraft>(
  CharacterDraftNotifier.new,
);
