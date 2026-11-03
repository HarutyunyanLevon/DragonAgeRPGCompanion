import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rules/models/backgrounds.dart';
import 'ability_generation.dart';
import 'background_benefits.dart';

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
    this.benefits = const BackgroundBenefits(),
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

  /// Step 3: the background's focus, language and table results. Depends on
  /// the background, race and class, so changing one of those clears it.
  final BackgroundBenefits benefits;

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
    BackgroundBenefits? benefits,
  }) =>
      CharacterDraft(
        name: name ?? this.name,
        background: background,
        race: race ?? this.race,
        caste: caste ?? this.caste,
        classId: classId ?? this.classId,
        abilities: abilities ?? this.abilities,
        benefits: benefits ?? this.benefits,
      );
}

class CharacterDraftNotifier extends AutoDisposeNotifier<CharacterDraft> {
  @override
  CharacterDraft build() => const CharacterDraft();

  void setName(String name) => state = state.copyWith(name: name);
  void setCaste(String caste) => state = state.copyWith(caste: caste);
  void setBenefits(BackgroundBenefits benefits) =>
      state = state.copyWith(benefits: benefits);

  // Step 3 depends on the scores (highest start score), the race (which 2d6
  // table) and the class (weapon group fallback), so changing one of them
  // clears it. Race and class only when they really change.
  void setAbilities(AbilityGeneration abilities) => state =
      state.copyWith(abilities: abilities, benefits: const BackgroundBenefits());

  void setRace(String race) {
    if (race == state.race) return;
    state = state.copyWith(race: race, benefits: const BackgroundBenefits());
  }

  void setClass(String classId) {
    if (classId == state.classId) return;
    state =
        state.copyWith(classId: classId, benefits: const BackgroundBenefits());
  }

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
