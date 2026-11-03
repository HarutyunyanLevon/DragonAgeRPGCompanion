import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rules/models/backgrounds.dart';
import 'ability_generation.dart';

/// The character being built by the creation wizard. Nothing is saved until
/// the last step. The draft is thrown away when the wizard closes.
class CharacterDraft {
  const CharacterDraft({
    this.name = '',
    this.background,
    this.race,
    this.caste,
    this.classId,
    this.abilities = const AbilityGeneration(),
  });

  final String name;

  /// The chosen background: from the book or a saved custom one.
  final Background? background;

  /// Fixed by the background, or picked when the background allows a choice.
  final String? race;
  final String? caste;
  final String? classId;

  /// Step 2: the abilities made so far.
  final AbilityGeneration abilities;

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
    AbilityGeneration? abilities,
  }) =>
      CharacterDraft(
        name: name ?? this.name,
        background: background,
        race: race ?? this.race,
        caste: caste ?? this.caste,
        classId: classId ?? this.classId,
        abilities: abilities ?? this.abilities,
      );
}

class CharacterDraftNotifier extends AutoDisposeNotifier<CharacterDraft> {
  @override
  CharacterDraft build() => const CharacterDraft();

  void setName(String name) => state = state.copyWith(name: name);
  void setRace(String race) => state = state.copyWith(race: race);
  void setCaste(String caste) => state = state.copyWith(caste: caste);
  void setClass(String classId) => state = state.copyWith(classId: classId);
  void setAbilities(AbilityGeneration abilities) =>
      state = state.copyWith(abilities: abilities);

  /// Choosing a background clears what depended on the previous one.
  void selectBackground(Background background) {
    state = CharacterDraft(
      name: state.name,
      background: background,
      race: background.raceChoice ? null : background.races.first,
      classId: background.classes.contains(state.classId) ? state.classId : null,
      abilities: state.abilities,
    );
  }

  /// Back to "no background chosen" (used when the chosen one is deleted).
  void clearBackground() =>
      state = CharacterDraft(name: state.name, abilities: state.abilities);
}

final characterDraftProvider =
    NotifierProvider.autoDispose<CharacterDraftNotifier, CharacterDraft>(
  CharacterDraftNotifier.new,
);
