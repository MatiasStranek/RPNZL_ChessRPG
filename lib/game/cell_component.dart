import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../board/board_model.dart';
import '../board/board_state.dart';

class CellComponent extends PositionComponent {
  final CellType cellType;
  final int gridX;
  final int gridY;
  final BoardState state;
  static const double cellSize = 48;

  CellComponent({
    required this.cellType,
    required this.gridX,
    required this.gridY,
    required this.state,
  }) : super(
         position: Vector2(
           gridX.toDouble() * cellSize,
           gridY.toDouble() * cellSize,
         ),
         size: Vector2.all(cellSize),
       );

  @override
  void render(Canvas canvas) {
    // Hintergrundfarbe
    final bgPaint = Paint()..color = _cellColor();
    canvas.drawRect(size.toRect(), bgPaint);

    // Oranger Rahmen wenn ausgewählt
    final selected = state.selectedPiece;
    if (selected != null && selected.x == gridX && selected.y == gridY) {
      final borderPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(size.toRect(), borderPaint);
    }

    // Goldener Kreis wenn erreichbar
    if (state.isReachable(gridX, gridY)) {
      final circlePaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(cellSize / 2, cellSize / 2), 8, circlePaint);
    }
  }

  Color _cellColor() {
    if (cellType == CellType.hole) return Colors.black;
    return (gridX + gridY) % 2 == 0
        ? const Color(0xFFBBCC97)
        : const Color(0xFFA1B175);
  }
}
