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
import '../animations/reward_overlay_controller.dart';
import '../animations/dust_animation_component.dart';
import '../skills/active_skill_service.dart';
import '../skills/skill_service.dart';
import 'cell_component.dart';
import 'piece_component.dart';
import '../enemy/base/enemy_component.dart';
import '../enemy/types/level1/level1_enemy_component.dart';
import 'dart:math';

class ChessGame extends FlameGame with TapCallbacks, DragCallbacks {
  final BoardModel board;
  final EnergyService energyService;
  final InventoryService inventoryService;
  final PlayerService playerService;
  final ActiveSkillService activeSkillService;
  final SkillService skillService;

  late BoardState state;
  late PieceComponent pieceComponent;
  Vector2 cameraShakeOffset = Vector2.zero();
  bool _gameOver = false;
  bool _inputLocked = false;

  double _visibleFieldsTotal = 8;
  int _lastKnownLevel = 0;
  int _lastKnownCrazyLevel = 0;

  final Map<PieceModel, EnemyComponent> _enemyComponents = {};
  final Random _random = Random();

  ChessGame({
    required this.board,
    required this.energyService,
    required this.inventoryService,
    required this.playerService,
    required this.activeSkillService,
    required this.skillService,
  });

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyZoom(size);
  }

  void _applyZoom(Vector2 size) {
    final zoom = size.y / (_visibleFieldsTotal * CellComponent.cellSize);
    camera.viewfinder.zoom = zoom;
  }

  void setZoomNear() {
    _visibleFieldsTotal = 8;
    _applyZoom(camera.viewport.size);
  }

  void setZoomDefault() {
    _visibleFieldsTotal = 16;
    _applyZoom(camera.viewport.size);
  }

  void setZoomFar() {
    _visibleFieldsTotal = 22;
    _applyZoom(camera.viewport.size);
  }

  void selectPlayerPiece() {
    final player = board.pieces.firstWhereOrNull(
      (p) => p.team == PieceTeam.player,
    );
    if (player != null) state.selectPiece(player);
  }

  @override
  Future<void> onLoad() async {
    state = BoardState(board: board);
    state.activeSkillService = activeSkillService;
    _lastKnownLevel = playerService.level;
    _lastKnownCrazyLevel = playerService.crazyLevel;

    state.onSpawnChanged = (spawned, removed) {
      for (final piece in removed) {
        // comp aus Map holen (einmal!) und Animation + Entfernen aufrufen
        final comp = _enemyComponents.remove(piece);
        comp?.playDeathAnimation();
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
      // ── Item Drop ────────────────────────────────────────────────────────
      if (_random.nextDouble() < 0.20) {
        final item = ItemFactory.energyDrop();
        final added = inventoryService.addItem(item);
        if (added) {
          RewardOverlayController.instance.fireItem(item.name);
        }
      }

      // ── Gold & Standard-EXP ──────────────────────────────────────────────
      final reward = rewardFor(enemy.enemyLevel);
      playerService.rewardForKill(enemy.enemyLevel);

      final enemyScreenPos = _enemyScreenPosition(enemy.x, enemy.y);
      RewardOverlayController.instance.fireGold(
        reward.gold,
        position: enemyScreenPos,
      );

      // ── CrazyExp vergeben (nur bei aktivem MoveSkill) ────────────────────
      if (activeSkillService.isActive) {
        final crazyExp = crazyExpFor(enemy.enemyLevel);
        final crazyLeveledUp = playerService.addCrazyExp(crazyExp);

        if (crazyLeveledUp) {
          final newCrazyLevel = playerService.crazyLevel;
          _lastKnownCrazyLevel = newCrazyLevel;
          RewardOverlayController.instance.fireLevelUp(newCrazyLevel);
          skillService.checkAndUnlockAll();
        }
      }

      // ── Player-Level-Up prüfen ───────────────────────────────────────────
      skillService.checkAndUnlockAll();

      final newLevel = playerService.level;
      if (newLevel > _lastKnownLevel) {
        _lastKnownLevel = newLevel;
        RewardOverlayController.instance.fireLevelUp(newLevel);
        skillService.checkAndUnlockAll();
      }
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
      if (_inputLocked) {
        pieceComponent.position = fallback;
        return;
      }

      final player = board.pieces.firstWhere((p) => p.team == PieceTeam.player);
      state.selectedPiece = player;

      if (!state.isReachable(gridX, gridY)) {
        pieceComponent.position = fallback;
        state.deselectPiece();
        cameraShakeOffset = Vector2(4, 0);
        return;
      }

      // ── Energie nur bei aktivem Skill abziehen ───────────────────────────
      if (activeSkillService.isActive) {
        final moveCost = activeSkillService.activeSkill!.energyCost;
        if (!energyService.spendEnergy(amount: moveCost)) {
          pieceComponent.position = fallback;
          state.deselectPiece();
          cameraShakeOffset = Vector2(4, 0);
          return;
        }
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
      camera.viewfinder.position =
          pieceComponent.position +
          Vector2(CellComponent.cellSize / 2, CellComponent.cellSize / 2) +
          cameraShakeOffset;
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

    // ── Energie nur bei aktivem Skill abziehen ───────────────────────────
    if (activeSkillService.isActive) {
      final moveCost = activeSkillService.activeSkill!.energyCost;
      if (!energyService.spendEnergy(amount: moveCost)) {
        cameraShakeOffset = Vector2(4, 0);
        return;
      }
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

    // Staubanimation direkt in der World spawnen,
    // unabhängig vom Lifecycle der Enemy-Komponente
    comp.onPlayDeathEffect = (pos) {
      world.add(DustAnimationComponent(cellPosition: pos));
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

  Offset _enemyScreenPosition(int gridX, int gridY) {
    final screenSize = camera.viewport.size;
    final cellSize = CellComponent.cellSize;
    final worldX = gridX * cellSize + cellSize / 2;
    final worldY = gridY * cellSize + cellSize / 2;
    final camPos = camera.viewfinder.position;
    final screenCenterX = screenSize.x / 2;
    final screenCenterY = screenSize.y / 2;
    final screenX = screenCenterX + (worldX - camPos.x);
    final screenY = screenCenterY + (worldY - camPos.y);
    return Offset(screenX, screenY);
  }
}
