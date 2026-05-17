// piece/piece_model.dart
import '../board/spawn_zone.dart';

enum PieceTeam { player, enemy, pet, partner }

class PieceModel {
  final PieceTeam team;
  final int enemyLevel;
  final bool canAttack; // ← neu
  int x;
  int y;
  SpawnZone? spawnZone;

  PieceModel({
    required this.team,
    this.enemyLevel = 1,
    this.canAttack = false, // ← default false
    required this.x,
    required this.y,
    this.spawnZone,
  });
}
