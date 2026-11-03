import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rules/models/backgrounds.dart';
import '../../rules/rules_data.dart';
import 'ability_generation.dart';
import 'background_benefits.dart';
import 'class_choices.dart';
import 'gear_choices.dart';

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
    this.classChoices = const ClassChoices(),
    this.gearChoices = const GearChoices(),
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

  /// Step 4: weapon groups, talents and spells the class lets you pick.
  /// Depends on the class and the table results, so changing step 1-3 clears it.
  final ClassChoices classChoices;

  /// Steps 4b and 4c: starting weapons, the silver roll and the shop. Depends
  /// on everything before it, so changing steps 1-4a clears it.
  final GearChoices gearChoices;

  /// What the benefit rules need to know. Steps 1 and 2 must be done.
  BenefitFacts benefitFacts(RulesData rules) => BenefitFacts(
        background: background!,
        race: race!,
        classRules: rules.classes.classById(classId!),
        startScores: abilities.scores,
        maxScore: rules.backgrounds.maxScore,
        buy: rules.backgrounds.buyMethod,
      );

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
    ClassChoices? classChoices,
    GearChoices? gearChoices,
  }) =>
      CharacterDraft(
        name: name ?? this.name,
        background: background,
        race: race ?? this.race,
        caste: caste ?? this.caste,
        classId: classId ?? this.classId,
        abilities: abilities ?? this.abilities,
        benefits: benefits ?? this.benefits,
        classChoices: classChoices ?? this.classChoices,
        gearChoices: gearChoices ?? this.gearChoices,
      );
}

class CharacterDraftNotifier extends AutoDisposeNotifier<CharacterDraft> {
  @override
  CharacterDraft build() => const CharacterDraft();

  void setName(String name) => state = state.copyWith(name: name);
  void setCaste(String caste) => state = state.copyWith(caste: caste);
  void setGearChoices(GearChoices choices) =>
      state = state.copyWith(gearChoices: choices);
  void setClassChoices(ClassChoices choices) => state = state.copyWith(
        classChoices: choices,
        gearChoices: const GearChoices(),
      );

  // Step 3 depends on the scores (highest start score), the race (which 2d6
  // table) and the class (weapon group fallback), so changing one of them
  // clears it. Race and class only when they really change. Step 4 depends
  // on the class and on step 3, so it is cleared by all of these.
  void setBenefits(BackgroundBenefits benefits) => state = state.copyWith(
        benefits: benefits,
        classChoices: const ClassChoices(),
        gearChoices: const GearChoices(),
      );

  void setAbilities(AbilityGeneration abilities) => state = state.copyWith(
        abilities: abilities,
        benefits: const BackgroundBenefits(),
        classChoices: const ClassChoices(),
        gearChoices: const GearChoices(),
      );

  void setRace(String race) {
    if (race == state.race) return;
    state = state.copyWith(
      race: race,
      benefits: const BackgroundBenefits(),
      classChoices: const ClassChoices(),
      gearChoices: const GearChoices(),
    );
  }

  void setClass(String classId) {
    if (classId == state.classId) return;
    state = state.copyWith(
      classId: classId,
      benefits: const BackgroundBenefits(),
      classChoices: const ClassChoices(),
      gearChoices: const GearChoices(),
    );
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
