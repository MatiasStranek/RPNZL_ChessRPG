// piece_model.dart
enum PieceTeam { player, enemy, pet, partner }

class PieceModel {
  final PieceTeam team;
  int x;
  int y;

  PieceModel({required this.team, required this.x, required this.y});
}
