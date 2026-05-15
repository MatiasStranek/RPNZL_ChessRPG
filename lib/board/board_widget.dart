import 'package:flutter/material.dart';
import 'board_model.dart';
import 'board_state.dart';
import 'package:chessrpg/piece/piece_model.dart';

class BoardWidget extends StatelessWidget {
  final BoardState state;

  static Color _cellColor(int x, int y, CellType cell) {
    if (cell == CellType.hole) return Colors.black;
    return (x + y) % 2 == 0 ? const Color(0xFFBBCC97) : const Color(0xFFa1B175);
  }

  const BoardWidget({super.key, required this.state});

  static PieceModel? _pieceAt(List<PieceModel> pieces, int x, int y) {
    try {
      return pieces.firstWhere((p) => p.x == x && p.y == y);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => state.deselectPiece(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(state.board.height, (y) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(state.board.width, (x) {
                  final cell = state.board.cells[y][x];
                  final piece = _pieceAt(state.board.pieces, x, y);
                  final isSelected =
                      state.selectedPiece == piece && piece != null;
                  final isReachable = state.isReachable(x, y);

                  return GestureDetector(
                    onTap: () {
                      if (piece != null && piece.team == PieceTeam.player) {
                        state.selectPiece(piece);
                      } else {
                        state.movePiece(x, y);
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _cellColor(x, y, cell),
                        border: isSelected
                            ? Border.all(color: Colors.orange, width: 3)
                            : null,
                      ),

                      child: piece != null
                          ? Text(
                              piece.team == PieceTeam.player ? '♔' : '♚',
                              style: const TextStyle(fontSize: 32),
                            )
                          : isReachable
                          ? Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }
}
