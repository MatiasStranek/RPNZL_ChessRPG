import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:collection/collection.dart';
import '../board/board_model.dart';
import '../board/board_state.dart';
import '../piece/piece_model.dart';
import 'cell_component.dart';
import 'piece_component.dart';

class ChessGame extends FlameGame with TapCallbacks {
  final BoardModel board;
  late BoardState state;
  late PieceComponent pieceComponent;
  Vector2 cameraShakeOffset = Vector2.zero();

  ChessGame({required this.board});

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  Future<void> onLoad() async {
    print('Board size: ${board.width} x ${board.height}');
    state = BoardState(board: board);
    camera.viewfinder.anchor = Anchor.center;

    // Felder hinzufügen
    for (int y = 0; y < board.height; y++) {
      for (int x = 0; x < board.width; x++) {
        world.add(
          CellComponent(
            cellType: board.cells[y][x],
            gridX: x,
            gridY: y,
            state: state,
          ),
        );
      }
    }

    // Figur hinzufügen
    final piece = board.pieces.first;
    pieceComponent = PieceComponent(piece: piece);
    world.add(pieceComponent);

    // Kamera auf Figur zentrieren
    //camera.follow(pieceComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    camera.viewfinder.position = pieceComponent.position + cameraShakeOffset;

    cameraShakeOffset *= 0.85;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final worldPos = camera.globalToLocal(event.canvasPosition);
    final gridX = (worldPos.x / CellComponent.cellSize).floor();
    final gridY = (worldPos.y / CellComponent.cellSize).floor();

    // Außerhalb des Boards
    if (gridX < 0 ||
        gridX >= board.width ||
        gridY < 0 ||
        gridY >= board.height) {
      state.deselectPiece();
      return;
    }

    // Prüfe ob eine Figzr auf dem Feld steht
    final piece = board.pieces
        .where((p) => p.x == gridX && p.y == gridY)
        .firstOrNull;

    if (piece != null && piece.team == PieceTeam.player) {
      state.selectPiece(piece);
    } else {
      final oldX = board.pieces.first.x;
      final oldY = board.pieces.first.y;

      state.movePiece(gridX, gridY);

      _shakeCamera(oldX, oldY, gridX, gridY);

      if (state.selectedPiece == null) {
        pieceComponent.moveTo(board.pieces.first.x, board.pieces.first.y);
      }
    }
  }

  void _shakeCamera(int fromX, int fromY, int toX, int toY) {
    final dir = Vector2((toX - fromX).toDouble(), (toY - fromY).toDouble());

    if (dir.length == 0) return;

    dir.normalize();

    const strength = 6.0;
    cameraShakeOffset = dir * strength;
  }
}
