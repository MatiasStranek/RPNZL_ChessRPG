// chess_game.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:collection/collection.dart';
import '../board/board_model.dart';
import '../board/board_state.dart';
import '../piece/piece_model.dart';
import '../energy/energy_service.dart';
import 'cell_component.dart';
import 'piece_component.dart';
import '../enemy/enemy_component.dart';

class ChessGame extends FlameGame with TapCallbacks {
  final BoardModel board;
  final EnergyService energyService;
  late BoardState state;
  late PieceComponent pieceComponent;
  Vector2 cameraShakeOffset = Vector2.zero();
  bool _gameOver = false;

  final Map<PieceModel, EnemyComponent> _enemyComponents = {};

  ChessGame({required this.board, required this.energyService});

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  Future<void> onLoad() async {
    state = BoardState(board: board);

    state.onSpawnChanged = (spawned, removed) {
      for (final piece in removed) {
        _enemyComponents.remove(piece)?.removeFromParent();
      }
      for (final piece in spawned) {
        _addEnemy(piece);
      }
    };

    state.onPlayerDefeated = (killer) {
      _gameOver = true;
      energyService.drainEnergy();
    };

    energyService.energyNotifier.addListener(_onEnergyChanged);

    camera.viewfinder.anchor = Anchor.center;

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

    final piece = board.pieces.firstWhere((p) => p.team == PieceTeam.player);
    pieceComponent = PieceComponent(piece: piece);
    world.add(pieceComponent);

    for (final enemy in board.pieces.where((p) => p.team == PieceTeam.enemy)) {
      _addEnemy(enemy);
    }
  }

  @override
  void onRemove() {
    energyService.energyNotifier.removeListener(_onEnergyChanged);
    super.onRemove();
  }

  void _onEnergyChanged() {
    if (_gameOver && energyService.energy > 0) {
      _gameOver = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    camera.viewfinder.position = pieceComponent.position + cameraShakeOffset;
    cameraShakeOffset *= 0.85;

    for (final entry in _enemyComponents.entries) {
      entry.value.syncPosition();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final worldPos = camera.globalToLocal(event.canvasPosition);
    final gridX = (worldPos.x / CellComponent.cellSize).floor();
    final gridY = (worldPos.y / CellComponent.cellSize).floor();

    if (gridX < 0 ||
        gridX >= board.width ||
        gridY < 0 ||
        gridY >= board.height) {
      state.deselectPiece();
      return;
    }

    final piece = board.pieces
        .where((p) => p.x == gridX && p.y == gridY)
        .firstOrNull;

    if (piece != null && piece.team == PieceTeam.player) {
      state.selectPiece(piece);
      return;
    }

    // Kein Stück ausgewählt → kein Zug möglich
    if (state.selectedPiece == null) {
      cameraShakeOffset = Vector2(4, 0); // ← neu
      return;
    }

    // Ziel nicht erreichbar
    if (!state.isReachable(gridX, gridY)) {
      cameraShakeOffset = Vector2(4, 0);
      state.deselectPiece();
      return;
    }

    // Keine Energie → Zug wäre gültig, aber kein Energie
    if (!energyService.spendEnergy()) {
      cameraShakeOffset = Vector2(4, 0);
      // state.tickOnly();
      return;
    }

    final player = board.pieces.firstWhere((p) => p.team == PieceTeam.player);
    final oldX = player.x;
    final oldY = player.y;

    state.movePiece(gridX, gridY);

    _shakeCamera(oldX, oldY, player.x, player.y);

    if (state.selectedPiece == null) {
      pieceComponent.moveTo(player.x, player.y);
    }
  }

  void _addEnemy(PieceModel piece) {
    final comp = EnemyComponent(piece: piece);
    _enemyComponents[piece] = comp;
    world.add(comp);
  }

  void _shakeCamera(int fromX, int fromY, int toX, int toY) {
    final dir = Vector2((toX - fromX).toDouble(), (toY - fromY).toDouble());
    if (dir.length == 0) return;
    dir.normalize();
    cameraShakeOffset = dir * 6.0;
  }
}
