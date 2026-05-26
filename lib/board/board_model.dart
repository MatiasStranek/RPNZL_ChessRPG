// board/board_model.dart
import 'package:chessrpg/piece/piece_model.dart';
import 'spawn_zone.dart';
import '../portal/portal_model.dart';

enum CellType { solid, hole, portal, beat, levelExit }

class BoardModel {
  final int width;
  final int height;
  final List<List<CellType>> cells;
  final List<PieceModel> pieces;
  final List<SpawnZone> spawnZones;
  final List<PortalModel> portals;

  BoardModel({
    required this.width,
    required this.height,
    required this.cells,
    required this.pieces,
    required this.spawnZones,
    required this.portals,
  });

  factory BoardModel.generate({required int width, required int height}) {
    final cells = List.generate(
      height,
      (_) => List.generate(width, (_) => CellType.solid),
    );
    return BoardModel(
      width: width,
      height: height,
      cells: cells,
      pieces: [],
      spawnZones: [],
      portals: [],
    );
  }
}
