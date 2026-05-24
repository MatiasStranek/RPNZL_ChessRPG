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

    // Nur horizontal und vertikal, genau 2 Felder (überspringt das erste)
    const directions = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];

    for (final dir in directions) {
      // Zwischenfeld (dist=1) wird übersprungen – nur Zielfeld (dist=2)
      final midX = fromX + dir[0];
      final midY = fromY + dir[1];
      final nx = fromX + dir[0] * 2;
      final ny = fromY + dir[1] * 2;

      // Zielfeld muss auf dem Board und kein Loch sein
      if (nx < 0 || nx >= state.board.width) continue;
      if (ny < 0 || ny >= state.board.height) continue;
      if (state.board.cells[ny][nx] == CellType.hole) continue;

      // Zwischenfeld muss auf dem Board sein (kann aber betreten werden)
      if (midX < 0 || midX >= state.board.width) continue;
      if (midY < 0 || midY >= state.board.height) continue;

      moves.add([nx, ny]);
    }

    return moves;
  }
}
