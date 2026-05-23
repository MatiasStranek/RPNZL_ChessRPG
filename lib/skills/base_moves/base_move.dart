import '../../board/board_state.dart';

abstract class BaseMove {
  List<List<int>> getLegalMoves(int fromX, int fromY, BoardState state);

  int get energyCost => 1;
}
