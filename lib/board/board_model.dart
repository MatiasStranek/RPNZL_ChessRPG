import 'package:chessrpg/piece/piece_model.dart';

enum CellType { solid, hole }

class BoardModel {
  final int width;
  final int height;
  final List<List<CellType>> cells;
  final List<PieceModel> pieces;

  BoardModel({
    required this.width,
    required this.height,
    required this.cells,
    required this.pieces,
  });

  factory BoardModel.generate({required int width, required int height}) {
    final cells = List.generate(
      height,
      (_) => List.generate(width, (_) => CellType.solid),
    );

    return BoardModel(width: width, height: height, cells: cells, pieces: []);
  }
}
