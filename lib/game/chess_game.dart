// game/chess_game.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:collection/collection.dart';
import '../board/board_loader.dart';
import '../board/board_model.dart';
import '../energy/energy_service.dart';
import '../inventory/inventory_service.dart';
import '../player/player_service.dart';
import '../piece/piece_model.dart';
import '../skills/active_skill_service.dart';
import '../skills/skill_service.dart';
import '../beat/beat_level_service.dart';
import '../beat/beat_timer/beat_timer_controller.dart';
import '../chest/chest_service.dart';
import 'cell_component.dart';
import 'mixins/game_state_mixin.dart';
import 'mixins/game_helpers_mixin.dart';
import 'mixins/game_board_mixin.dart';
import 'mixins/game_callbacks_mixin.dart';
import 'mixins/game_portal_mixin.dart';
import 'mixins/game_beat_mixin.dart';

class ChessGame extends FlameGame
    with
        TapCallbacks,
        DragCallbacks,
        GameStateMixin,
        GameHelpersMixin,
        GameCallbacksMixin,
        GameBoardMixin,
        GamePortalMixin,
        GameBeatMixin {
  ChessGame({
    required EnergyService energyService,
    required InventoryService inventoryService,
    required PlayerService playerService,
    required ActiveSkillService activeSkillService,
    required SkillService skillService,
    required BeatLevelService beatLevelService,
    required ChestService chestService,
    required BoardModel board,
  }) {
    this.energyService = energyService;
    this.inventoryService = inventoryService;
    this.playerService = playerService;
    this.activeSkillService = activeSkillService;
    this.skillService = skillService;
    this.beatLevelService = beatLevelService;
    this.chestService = chestService;
    this.board = board;
    beatTimerController = BeatTimerController();
  }

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    applyZoom(size);
  }

  // ── onLoad ────────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    lastKnownLevel = playerService.level;
    lastKnownCrazyLevel = playerService.crazyLevel;
    energyService.energyNotifier.addListener(onEnergyChanged);

    final savedMap = playerService.savedMap;
    final savedX = playerService.savedPosX;
    final savedY = playerService.savedPosY;

    try {
      final savedBoard = await BoardLoader.loadMap(savedMap);
      final playerPiece = savedBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );
      playerPiece.x = savedX;
      playerPiece.y = savedY;
      currentMapName = savedMap;
      await initBoard(savedBoard);
    } catch (_) {
      playerService.resetPosition();
      currentMapName = 'map_board_1';
      await initBoard(board);
    }
  }

  @override
  void onRemove() {
    energyService.energyNotifier.removeListener(onEnergyChanged);
    super.onRemove();
  }

  void onEnergyChanged() {
    if (gameOver && energyService.energy > 0) {
      gameOver = false;
    }
  }

  void selectPlayerPiece() {
    final player = board.pieces.firstWhereOrNull(
      (p) => p.team == PieceTeam.player,
    );
    if (player != null) state.selectPiece(player);
  }

  // ── update ────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);

    tickAutoMove(dt);

    cameraShakeOffset *= 0.85;

    if (!pieceComponent.isDragging) {
      camera.viewfinder.position =
          pieceComponent.position +
          Vector2(CellComponent.cellSize / 2, CellComponent.cellSize / 2) +
          cameraShakeOffset;
    }

    if (inputLocked && !anyoneMoving()) {
      inputLocked = false;
    }
  }

  // ── onTapDown ─────────────────────────────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (inputLocked) return;

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

    autoMoveTimer = 0.0;
    beatTimerController.reset();

    savePositionIfOutside(player.x, player.y);
    checkPortal(player.x, player.y);

    Future.delayed(const Duration(milliseconds: 16), () {
      shakeCamera(oldX, oldY, player.x, player.y);
    });

    inputLocked = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      state.moveEnemiesNow();
    });
  }
}
