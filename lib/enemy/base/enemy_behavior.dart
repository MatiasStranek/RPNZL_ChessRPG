// enemy/base/enemy_behavior.dart

abstract class EnemyBehavior {
  /// Gibt an ob dieser Gegnertyp den Spieler angreifen kann
  bool canAttack();
}
