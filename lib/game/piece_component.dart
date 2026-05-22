// game/piece_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../piece/piece_model.dart';

class PieceComponent extends PositionComponent with DragCallbacks {
  final PieceModel piece;
  static const double cellSize = 48;

  bool get isMoving => false;
  bool isDragging = false;

  Vector2 _dragStartPosition = Vector2.zero();

  PieceComponent({required this.piece})
    : super(
        position: Vector2(piece.x * cellSize, piece.y * cellSize),
        size: Vector2.all(cellSize),
      );

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    priority = 10;
    _dragStartPosition = position.clone();
    position = position = position =
        position +
        event.localPosition -
        Vector2(size.x / 2, size.y * 0.6); // Drag position
    event.continuePropagation = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    priority = 0;
    final snappedX = (position.x / cellSize).round();
    final snappedY = (position.y / cellSize).round();
    onDropped?.call(snappedX, snappedY, _dragStartPosition.clone());
  }

  void Function(int x, int y, Vector2 fallbackPosition)? onDropped;

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
