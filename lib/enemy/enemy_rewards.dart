// enemy/enemy_rewards.dart

/// Belohnung die der Spieler erhält, wenn er einen Gegner besiegt.
class EnemyReward {
  final int exp;
  final int gold;
  const EnemyReward({required this.exp, required this.gold});
}

/// Belohnungen nach Gegner-Level.
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

// ─── CrazyExp-Tabelle ─────────────────────────────────────────────────────────

/// Feste CrazyExp-Belohnung pro Gegner-Level.
/// Hier kannst du jeden Wert individuell anpassen.
const Map<int, int> crazyExpByEnemyLevel = {
  1: 5,
  2: 12,
  3: 20,
  4: 30,
  5: 45,
  6: 60,
  7: 80,
  8: 100,
  9: 125,
  10: 150,
};

/// Fallback wenn Gegner-Level nicht in der Tabelle steht.
int crazyExpFor(int enemyLevel) =>
    crazyExpByEnemyLevel[enemyLevel] ?? (enemyLevel * 8);
