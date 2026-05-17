// enemy/base/enemy_component.dart
import 'package:flame/components.dart';
import '../../piece/piece_model.dart';
import 'enemy_behavior.dart';

abstract class EnemyComponent extends PositionComponent
    implements EnemyBehavior {
  final PieceModel piece;
  static const double cellSize = 48;
  static const double slideSpeed = 400; // gleiche Geschwindigkeit wie Spieler

  Vector2? _targetPosition;
  bool get isMoving => _targetPosition != null;

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

  /// Löst die Slide-Animation zur aktuellen PieceModel-Position aus
  void syncPosition() {
    final target = Vector2(
      piece.x * cellSize.toDouble(),
      piece.y * cellSize.toDouble(),
    );
    if (target != position) {
      _targetPosition = target;
    }
  }
}
