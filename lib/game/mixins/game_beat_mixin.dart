// game/mixins/game_beat_mixin.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../board/board_loader.dart';
import '../../board/board_model.dart';
import '../../piece/piece_model.dart';
import '../cell_component.dart';
import 'game_state_mixin.dart';

mixin GameBeatMixin on GameStateMixin {
  // ── Auto-Move ─────────────────────────────────────────────────────────────
  void tickAutoMove(double dt) {
    final config = beatConfig;
    if (config == null) return;
    if (inputLocked) return;
    if (gameOver) return;
    if (autoMovePending) return;

    autoMoveTimer += dt;
    beatTimerController.tick(dt);

    if (autoMoveTimer >= config.autoMoveIntervalSeconds) {
      autoMoveTimer = 0.0;
      autoMovePending = true;
      beatTimerController.triggerAutoMove();

      final player = board.pieces.firstWhereOrNull(
        (p) => p.team == PieceTeam.player,
      );

      if (player != null && playerIsOnPortal(player.x, player.y)) {
        final pushTarget = findAdjacentFreeCell(player.x, player.y);
        if (pushTarget != null) {
          final oldX = player.x;
          final oldY = player.y;

          state.selectedPiece = player;
          state.movePiece(pushTarget[0], pushTarget[1]);
          pieceComponent.moveTo(player.x, player.y);
          checkPortal(player.x, player.y);

          Future.delayed(const Duration(milliseconds: 16), () {
            shakeCamera(oldX, oldY, player.x, player.y);
          });

          inputLocked = true;
          Future.delayed(const Duration(milliseconds: 150), () {
            state.moveEnemiesNow();
            autoMovePending = false;
          });
          return;
        }
      }

      inputLocked = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        state.moveEnemiesNow();
        autoMovePending = false;
      });
    }
  }

  bool playerIsOnPortal(int x, int y) {
    final cell = board.cells[y][x];
    return cell == CellType.portal ||
        cell == CellType.beat ||
        cell == CellType.levelExit;
  }

  List<int>? findAdjacentFreeCell(int fromX, int fromY) {
    const deltas = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];

    for (final d in deltas) {
      final nx = fromX + d[0];
      final ny = fromY + d[1];

      if (nx < 0 || nx >= board.width || ny < 0 || ny >= board.height) continue;
      if (board.cells[ny][nx] == CellType.hole) continue;
      if (playerIsOnPortal(nx, ny)) continue;

      return [nx, ny];
    }
    return null;
  }

  // ── Teleport zur gespeicherten Position ──────────────────────────────────
  Future<void> teleportToSavedPosition() async {
    // FIX: beatWorldId sichern BEVOR beatSession auf null gesetzt wird,
    // dann Gegner-Zustände zurücksetzen damit die nächste Runde frisch startet.
    if (beatSession != null) {
      final beatWorldId = beatSession!.beatWorldId;
      await beatLevelService.resetEnemyStates(beatWorldId);

      beatSession = null;
      currentBeatMapName = '';
      onBeatSessionChanged?.call(false);
    }

    beatConfig = null;
    autoMoveTimer = 0.0;
    autoMovePending = false;
    beatTimerController.deactivate();

    inputLocked = true;
    final mapName = playerService.savedMap;

    try {
      final newBoard = await BoardLoader.loadMap(mapName);
      final playerPiece = newBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );

      currentMapName = mapName;
      playerService.savePosition(playerPiece.x, playerPiece.y, mapName);

      world.removeAll(world.children.toList());
      enemyComponents.clear();

      await initBoard(newBoard);
    } catch (_) {
      currentMapName = 'map_board_1';
      final fallback = await BoardLoader.loadMap('map_board_1');
      final playerPiece = fallback.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );
      playerService.savePosition(playerPiece.x, playerPiece.y, 'map_board_1');
      world.removeAll(world.children.toList());
      enemyComponents.clear();
      await initBoard(fallback);
    } finally {
      inputLocked = false;
      gameOver = false;
    }
  }
}
