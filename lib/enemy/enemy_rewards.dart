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
  1: EnemyReward(exp: 1, gold: 5),
  2: EnemyReward(exp: 3, gold: 12),
  3: EnemyReward(exp: 6, gold: 25),
  4: EnemyReward(exp: 10, gold: 40),
  5: EnemyReward(exp: 15, gold: 60),
};

/// Fallback für unbekannte Gegner-Level.
const EnemyReward defaultEnemyReward = EnemyReward(exp: 1, gold: 5);

/// Hilfsfunktion – gibt die Belohnung für ein gegebenes Gegner-Level zurück.
EnemyReward rewardFor(int enemyLevel) =>
    enemyRewardByLevel[enemyLevel] ?? defaultEnemyReward;
