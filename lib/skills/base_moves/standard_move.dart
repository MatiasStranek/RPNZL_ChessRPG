import '../../board/board_state.dart';
import '../../board/board_model.dart';
import 'base_move.dart';

class StandardMove extends BaseMove {
  @override
  int get energyCost => 1;

  @override
  List<List<int>> getLegalMoves(int fromX, int fromY, BoardState state) {
    final moves = <List<int>>[];
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final nx = fromX + dx;
        final ny = fromY + dy;
        if (nx < 0 || nx >= state.board.width) continue;
        if (ny < 0 || ny >= state.board.height) continue;
        if (state.board.cells[ny][nx] == CellType.hole) continue;
        moves.add([nx, ny]);
      }
    }
    return moves;
  }
}
