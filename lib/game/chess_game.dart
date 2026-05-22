// game/chess_game.dart
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
import '../inventory/inventory_service.dart';
import '../inventory/item_factory.dart';
import '../player/player_service.dart';
import '../enemy/enemy_rewards.dart';
import 'cell_component.dart';
import 'piece_component.dart';
import '../enemy/base/enemy_component.dart';
import '../enemy/types/level1/level1_enemy_component.dart';

class ChessGame extends FlameGame with TapCallbacks, DragCallbacks {
  final BoardModel board;
  final EnergyService energyService;
  final InventoryService inventoryService;
  final PlayerService playerService;
  late BoardState state;
  late PieceComponent pieceComponent;
  Vector2 cameraShakeOffset = Vector2.zero();
  bool _gameOver = false;
  bool _inputLocked = false;

  final Map<PieceModel, EnemyComponent> _enemyComponents = {};

  ChessGame({
    required this.board,
    required this.energyService,
    required this.inventoryService,
    required this.playerService,
  });

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

    state.onEnemiesMoved = () {
      for (final entry in _enemyComponents.entries) {
        entry.value.syncPosition();
      }
    };

    state.onEnemyKilled = (enemy) {
      inventoryService.addItem(ItemFactory.energyDrop());
      final reward = playerService.rewardForKill(enemy.enemyLevel);
      debugPrint(
        'Enemy L${enemy.enemyLevel} besiegt → '
        '+${enemyRewardByLevel[enemy.enemyLevel]?.exp ?? 1} EXP, '
        '+${enemyRewardByLevel[enemy.enemyLevel]?.gold ?? 5} Gold | '
        '$reward',
      );
    };

    state.onPlayerDefeated = (killer) {
      _gameOver = true;
      _inputLocked = false;
      energyService.drainEnergy();
    };

    energyService.energyNotifier.addListener(_onEnergyChanged);

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

    pieceComponent.onDropped = (gridX, gridY, fallback) {
      debugPrint('=== onDropped: gridX=$gridX, gridY=$gridY ===');
      debugPrint('inputLocked: $_inputLocked');

      if (_inputLocked) {
        pieceComponent.position = fallback;
        return;
      }

      final player = board.pieces.firstWhere((p) => p.team == PieceTeam.player);
      state.selectedPiece = player;
      debugPrint('isReachable: ${state.isReachable(gridX, gridY)}');
      debugPrint('energy: ${energyService.energy}');

      if (!state.isReachable(gridX, gridY)) {
        pieceComponent.position = fallback;
        state.deselectPiece();
        cameraShakeOffset = Vector2(4, 0);
        return;
      }

      if (!energyService.spendEnergy()) {
        pieceComponent.position = fallback;
        state.deselectPiece();
        cameraShakeOffset = Vector2(4, 0);
        return;
      }

      debugPrint(
        'Move wird ausgeführt → player.x=${player.x}, player.y=${player.y}',
      );
      final oldX = player.x;
      final oldY = player.y;
      state.movePiece(gridX, gridY);
      pieceComponent.moveTo(player.x, player.y);
      debugPrint('Nach movePiece → player.x=${player.x}, player.y=${player.y}');

      Future.delayed(const Duration(milliseconds: 16), () {
        _shakeCamera(oldX, oldY, player.x, player.y);
      });

      _inputLocked = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        state.moveEnemiesNow();
      });
    };

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

    cameraShakeOffset *= 0.85;

    if (!pieceComponent.isDragging) {
      camera.viewfinder.position = pieceComponent.position + cameraShakeOffset;
    }

    if (_inputLocked && !_anyoneMoving()) {
      _inputLocked = false;
    }
  }

  bool _anyoneMoving() {
    return _enemyComponents.values.any((c) => c.isMoving);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_inputLocked) return;

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

    final player = board.pieces.firstWhere((p) => p.team == PieceTeam.player);
    final piece = board.pieces
        .where((p) => p.x == gridX && p.y == gridY)
        .firstOrNull;

    if (piece != null && piece.team == PieceTeam.player) {
      if (!pieceComponent.isDragging) state.selectPiece(piece);
      return;
    }

    if (state.selectedPiece == null) {
      cameraShakeOffset = Vector2(4, 0);
      return;
    }

    if (!state.isReachable(gridX, gridY)) {
      cameraShakeOffset = Vector2(4, 0);
      state.deselectPiece();
      return;
    }

    if (!energyService.spendEnergy()) {
      cameraShakeOffset = Vector2(4, 0);
      return;
    }

    final oldX = player.x;
    final oldY = player.y;

    state.movePiece(gridX, gridY);
    pieceComponent.moveTo(player.x, player.y);

    Future.delayed(const Duration(milliseconds: 16), () {
      _shakeCamera(oldX, oldY, player.x, player.y);
    });

    _inputLocked = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      state.moveEnemiesNow();
    });
  }

  void _addEnemy(PieceModel piece) {
    final EnemyComponent comp = switch (piece.enemyLevel) {
      1 => Level1EnemyComponent(piece: piece),
      _ => Level1EnemyComponent(piece: piece),
    };
    _enemyComponents[piece] = comp;
    world.add(comp);
  }

  void _shakeCamera(int fromX, int fromY, int toX, int toY) {
    final dir = Vector2((toX - fromX).toDouble(), (toY - fromY).toDouble());
    if (dir.length == 0) return;
    dir.normalize();
    cameraShakeOffset = -dir * 16.0;
  }
}
