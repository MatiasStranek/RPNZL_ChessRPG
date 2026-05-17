// enemy/types/level1/level1_enemy_component.dart
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../../piece/piece_model.dart';
import '../../base/enemy_component.dart';

class Level1EnemyComponent extends EnemyComponent {
  Level1EnemyComponent({required PieceModel piece}) : super(piece: piece);

  @override
  bool canAttack() => false; // Level-1-Gegner können nicht angreifen

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(EnemyComponent.cellSize / 2, EnemyComponent.cellSize / 2),
      EnemyComponent.cellSize / 2 - 4,
      Paint()
        ..color = const Color(0x44FF3333)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(EnemyComponent.cellSize / 2, EnemyComponent.cellSize / 2),
      EnemyComponent.cellSize / 2 - 4,
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
        (EnemyComponent.cellSize - textPainter.width) / 2,
        (EnemyComponent.cellSize - textPainter.height) / 2,
      ),
    );
  }
}
