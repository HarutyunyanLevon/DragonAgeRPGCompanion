import 'dart:io';

import 'package:dragon_age_companion/features/create/rule_info.dart';
import 'package:dragon_age_companion/l10n/app_localizations_en.dart';
import 'package:dragon_age_companion/rules/rules_data.dart';
import 'package:dragon_age_companion/rules/rules_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RulesData rules;

  setUpAll(() async {
    rules = await RulesLoader((path) => File(path).readAsString()).load();
  });

  test('every ability has a description and focuses', () {
    for (final ability in rules.backgrounds.abilities) {
      expect(rules.abilityDescriptions[ability], isNotEmpty, reason: ability);
      expect(rules.focuses.where((f) => f.ability == ability), isNotEmpty,
          reason: ability);
    }
  });

  test('every weapon group a class can have is known and has weapons', () {
    for (final group in rules.classes.allWeaponGroups) {
      expect(rules.weaponGroupById(group).attackAbility, isNotEmpty);
      expect(rules.weaponsIn(group), isNotEmpty, reason: group);
    }
  });

  test('every talent requirement can be written out', () {
    final l10n = AppLocalizationsEn();
    for (final talent in rules.talents.talents) {
      for (final requirement in talent.requirements) {
        expect(requirementText(l10n, rules, requirement), isNotEmpty,
            reason: talent.id);
      }
    }
  });

  test('requirement text reads naturally', () {
    final l10n = AppLocalizationsEn();
    final archery = rules.talents.talentById('archery-style').requirements.single;
    final chirurgy = rules.talents.talentById('chirurgy').requirements.single;

    expect(requirementText(l10n, rules, archery), 'Trained in Bows');
    expect(requirementText(l10n, rules, chirurgy), 'Focus: Cunning (Healing)');
  });
}
