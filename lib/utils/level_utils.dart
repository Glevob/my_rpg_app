import 'dart:math';

class LevelUtils {
  static const int baseXP = 100;

  static int _roundTo50(int value) => ((value / 50).ceil() * 50);

  static int getRequiredXP(int level) {
    int rawXP = (baseXP * pow(1.5, level - 1)).round();
    return _roundTo50(rawXP);
  }

  /// Возвращает пару значений: текущий уровень и оставшийся опыт
  static Map<String, int> _getLevelState(int totalXp) {
    int level = 1;
    int remainingXp = totalXp;
    
    while (remainingXp >= getRequiredXP(level)) {
      remainingXp -= getRequiredXP(level);
      level++;
    }
    return {'level': level, 'xp': remainingXp};
  }

  static int getLevelFromXP(int totalXp) => _getLevelState(totalXp)['level']!;

  static int getXpInCurrentLevel(int totalXp) => _getLevelState(totalXp)['xp']!;

  static int getTotalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += getRequiredXP(i);
    }
    return total;
  }
}