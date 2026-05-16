// enemy_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../piece/piece_model.dart';

class EnemyComponent extends PositionComponent {
  final PieceModel piece;
  static const double cellSize = 48;

  EnemyComponent({required this.piece})
    : super(
        position: Vector2(
          piece.x * cellSize.toDouble(),
          piece.y * cellSize.toDouble(),
        ),
        size: Vector2.all(cellSize),
      );

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(cellSize / 2, cellSize / 2),
      cellSize / 2 - 4,
      Paint()
        ..color = const Color(0x44FF3333)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cellSize / 2, cellSize / 2),
      cellSize / 2 - 4,
      Paint()
        ..color = const Color(0xAAFF3333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '♚',
        style: TextStyle(fontSize: 28, color: Color(0xFFFF6666)),
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

  /// Synchronisiert die visuelle Position mit dem PieceModel.
  void syncPosition() {
    position.setValues(
      piece.x * cellSize.toDouble(),
      piece.y * cellSize.toDouble(),
    );
  }
}
