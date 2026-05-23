import '../../board/board_state.dart';
import '../../board/board_model.dart';
import 'move_skill_base.dart';

class DashSkill extends MoveSkillBase {
  @override
  String get skillId => 'move_dash';

  @override
  String get skillName => 'Dash';

  @override
  String get skillIcon => '💨';

  @override
  int get energyCost => 10;

  @override
  List<List<int>> getLegalMoves(int fromX, int fromY, BoardState state) {
    final moves = <List<int>>[];

    const directions = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];

    for (final dir in directions) {
      for (int dist = 1; dist <= 2; dist++) {
        final nx = fromX + dir[0] * dist;
        final ny = fromY + dir[1] * dist;

        if (nx < 0 || nx >= state.board.width) continue;
        if (ny < 0 || ny >= state.board.height) continue;
        if (state.board.cells[ny][nx] == CellType.hole) continue;

        moves.add([nx, ny]);
      }
    }

    return moves;
  }
}
