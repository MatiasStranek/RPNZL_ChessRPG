import '../board/spawn_zone.dart';

enum PieceTeam { player, enemy, pet, partner }

class PieceModel {
  final PieceTeam team;
  int x;
  int y;
  SpawnZone? spawnZone;

  PieceModel({
    required this.team,
    required this.x,
    required this.y,
    this.spawnZone,
  });
}
