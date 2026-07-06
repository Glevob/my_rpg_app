// lib/utils/level_utils.dart
import 'dart:math';

class LevelUtils {
  static const int baseXP = 100;

  static int _roundTo50(int value) => ((value / 50).ceil() * 50);

  static int getRequiredXP(int level) {
    int rawXP = (baseXP * pow(1.5, level - 1)).round();
    return _roundTo50(rawXP);
  }

  // Считает уровень, "срезая" уровни по мере накопления опыта
  static int getLevelFromXP(int totalXp) {
    int level = 1;
    int remainingXp = totalXp;
    while (remainingXp >= getRequiredXP(level)) {
      remainingXp -= getRequiredXP(level);
      level++;
    }
    return level;
  }

  // Считает опыт, который остался на текущем уровне
  static int getXpInCurrentLevel(int totalXp) {
    int level = 1;
    int remainingXp = totalXp;
    while (remainingXp >= getRequiredXP(level)) {
      remainingXp -= getRequiredXP(level);
      level++;
    }
    return remainingXp;
  }
}