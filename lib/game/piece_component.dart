import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../piece/piece_model.dart';

class PieceComponent extends PositionComponent {
  final PieceModel piece;
  static const double cellSize = 48;

  PieceComponent({required this.piece})
    : super(
        position: Vector2(piece.x * cellSize, piece.y * cellSize),
        size: Vector2.all(cellSize),
      );

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: piece.team == PieceTeam.player ? '♔' : '♚',
        style: const TextStyle(fontSize: 32),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (cellSize - textPainter.width) / 2,
        (cellSize - textPainter.height) / 2,
      ),
    );
  }

  void moveTo(int x, int y) {
    piece.x = x;
    piece.y = y;
    position = Vector2(x * cellSize, y * cellSize);
  }
}
