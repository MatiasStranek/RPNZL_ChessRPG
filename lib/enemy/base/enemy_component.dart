// enemy/base/enemy_component.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../piece/piece_model.dart';
import 'enemy_behavior.dart';

abstract class EnemyComponent extends PositionComponent
    implements EnemyBehavior {
  final PieceModel piece;
  static const double cellSize = 48;
  static const double slideSpeed = 400;

  Vector2? _targetPosition;
  bool get isMoving => _targetPosition != null;

  // Wird von ChessGame gesetzt, um die World-Referenz zu übergeben
  void Function(Vector2 position)? onPlayDeathEffect;

  EnemyComponent({required this.piece})
    : super(
        position: Vector2(
          piece.x * cellSize.toDouble(),
          piece.y * cellSize.toDouble(),
        ),
        size: Vector2.all(cellSize),
      );

  @override
  void update(double dt) {
    super.update(dt);
    if (_targetPosition == null) return;
    final diff = _targetPosition! - position;
    final step = slideSpeed * dt;
    if (diff.length <= step) {
      position = _targetPosition!.clone();
      _targetPosition = null;
    } else {
      position += diff.normalized() * step;
    }
  }

  void syncPosition() {
    final target = Vector2(
      piece.x * cellSize.toDouble(),
      piece.y * cellSize.toDouble(),
    );
    if (target != position) _targetPosition = target;
  }

  @override
  void playDeathAnimation({VoidCallback? onDone}) {
    // Staubeffekt über Callback in der World spawnen (parent könnte null sein)
    onPlayDeathEffect?.call(position.clone());
    removeFromParent();
    onDone?.call();
  }
}
