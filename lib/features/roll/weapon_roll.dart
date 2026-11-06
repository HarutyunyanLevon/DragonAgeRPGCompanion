import '../../character/equipment.dart';
import 'roll_request.dart';

/// Attack and damage of a weapon in one roll (the Roll button of a weapon on
/// the Play tab and on the Sheet).
RollRequest weaponRoll(String name, WeaponNumbers numbers) => RollRequest(
      title: name,
      bonus: numbers.attack,
      stunts: StuntSet.combat,
      damage: numbers.damage,
    );
