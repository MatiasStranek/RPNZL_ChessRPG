// board/spawn_zone.dart
class SpawnZone {
  final int x1, y1, x2, y2;
  final int maxEnemies;
  final int respawnAfterTurns;
  final int enemyLevel; // ← neu

  SpawnZone({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.maxEnemies,
    required this.respawnAfterTurns,
    this.enemyLevel = 1, // ← default Level 1
  });

  int get left => x1 < x2 ? x1 : x2;
  int get top => y1 < y2 ? y1 : y2;
  int get right => x1 < x2 ? x2 : x1;
  int get bottom => y1 < y2 ? y2 : y1;
}
