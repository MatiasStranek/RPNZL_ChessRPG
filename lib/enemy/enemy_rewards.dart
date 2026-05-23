// enemy/enemy_rewards.dart

/// Belohnung die der Spieler erhält, wenn er einen Gegner besiegt.
class EnemyReward {
  final int exp;
  final int gold;
  const EnemyReward({required this.exp, required this.gold});
}

/// Belohnungen nach Gegner-Level.
/// Neue Level einfach hier ergänzen.
const Map<int, EnemyReward> enemyRewardByLevel = {
  1: EnemyReward(exp: 1, gold: 1),
  2: EnemyReward(exp: 2, gold: 2),
  3: EnemyReward(exp: 3, gold: 3),
  4: EnemyReward(exp: 4, gold: 4),
  5: EnemyReward(exp: 5, gold: 5),
};

/// Fallback für unbekannte Gegner-Level.
const EnemyReward defaultEnemyReward = EnemyReward(exp: 1, gold: 5);

/// Hilfsfunktion – gibt die Belohnung für ein gegebenes Gegner-Level zurück.
EnemyReward rewardFor(int enemyLevel) =>
    enemyRewardByLevel[enemyLevel] ?? defaultEnemyReward;
