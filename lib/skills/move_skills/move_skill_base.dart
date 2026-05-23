import '../base_moves/base_move.dart';
import '../../board/board_state.dart';

abstract class MoveSkillBase extends BaseMove {
  String get skillId;
  String get skillName;
  String get skillIcon;

  @override
  int get energyCost;

  @override
  List<List<int>> getLegalMoves(int fromX, int fromY, BoardState state);
}
