// game/mixins/game_portal_mixin.dart
import 'package:flutter/material.dart';
import '../../board/board_loader.dart';
import '../../board/board_model.dart';
import '../../piece/piece_model.dart';
import '../../beat/beat_map_loader.dart';
import '../../beat/beat_world_session.dart';
import '../../beat/beat_popup.dart';
import '../../beat/beat_level_config.dart';
import '../../portal/portal_service.dart';
import '../../portal/portal_types/world_portal.dart';
import '../../portal/portal_types/beat_portal.dart';
import '../../animations/reward_overlay_controller.dart';
import 'game_state_mixin.dart';

mixin GamePortalMixin on GameStateMixin {
  // ── Portal-Logik ─────────────────────────────────────────────────────────
  void checkPortal(int x, int y) {
    final exitPortal = portalService.levelExitPortalAt(x, y);
    if (exitPortal != null) {
      completeBeatLevel();
      return;
    }

    final worldPortal = portalService.worldPortalAt(x, y);
    if (worldPortal != null) {
      travelToMap(worldPortal);
      return;
    }

    if (beatSession == null) {
      final beatPortal = portalService.beatPortalAt(x, y);
      if (beatPortal != null) {
        showBeatPortalPopup(beatPortal);
      }
    }
  }

  // ── Level abschließen ────────────────────────────────────────────────────
  Future<void> completeBeatLevel() async {
    final session = beatSession;
    if (session == null) return;

    inputLocked = true;

    final wasAlreadyCompleted = beatLevelService.isCompleted(
      session.beatWorldId,
    );

    await beatLevelService.markCompleted(session.beatWorldId);
    await beatLevelService.resetEnemyStates(session.beatWorldId);

    RewardOverlayController.instance.fireBeatComplete(
      session.beatWorldId,
      repeated: wasAlreadyCompleted,
    );

    beatSession = null;
    currentBeatMapName = '';
    onBeatSessionChanged?.call(false);

    beatConfig = null;
    autoMoveTimer = 0.0;
    autoMovePending = false;
    beatTimerController.deactivate();

    try {
      final newBoard = await BoardLoader.loadMap(session.returnMapName);
      final playerPiece = newBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );
      playerPiece.x = session.returnX;
      playerPiece.y = session.returnY;

      currentMapName = session.returnMapName;
      playerService.savePosition(
        session.returnX,
        session.returnY,
        currentMapName,
      );

      world.removeAll(world.children.toList());
      enemyComponents.clear();

      await initBoard(newBoard);
    } catch (_) {
      currentMapName = 'map_board_1';
      final fallback = await BoardLoader.loadMap('map_board_1');
      world.removeAll(world.children.toList());
      enemyComponents.clear();
      await initBoard(fallback);
    } finally {
      inputLocked = false;
    }
  }

  // ── World Portal: Map-Wechsel ─────────────────────────────────────────────
  Future<void> travelToMap(WorldPortal portal) async {
    inputLocked = true;

    final newBoard = await loadBoardByRef(portal.targetMap);
    final targetPortalService = PortalService(portals: newBoard.portals);
    final linkedPortal = targetPortalService.portalById(portal.linkedPortalId);

    final spawnX = linkedPortal?.x ?? 1;
    final spawnY = linkedPortal?.y ?? 1;

    final playerPiece = newBoard.pieces.firstWhere(
      (p) => p.team == PieceTeam.player,
    );
    playerPiece.x = spawnX;
    playerPiece.y = spawnY;

    final beatRef = BeatMapLoader.parseRef(portal.targetMap);
    if (beatRef != null && beatSession != null) {
      currentBeatMapName = beatRef.map;
      currentMapName = portal.targetMap;

      world.removeAll(world.children.toList());
      enemyComponents.clear();

      await initBoard(newBoard, beatMapName: beatRef.map);
      inputLocked = false;
      return;
    }

    currentMapName = portal.targetMap;

    if (beatSession == null) {
      playerService.savePosition(spawnX, spawnY, currentMapName);
    }

    world.removeAll(world.children.toList());
    enemyComponents.clear();

    await initBoard(newBoard);
    inputLocked = false;
  }

  // ── Beat Portal PopUp ────────────────────────────────────────────────────
  Future<void> showBeatPortalPopup(BeatPortal portal) async {
    inputLocked = true;

    final context = buildContext;
    if (context == null) {
      inputLocked = false;
      return;
    }

    final level = beatLevelService.getLevel(
      id: portal.beatMapName,
      requiredLevel: portal.requiredLevel,
    );

    final entered = await BeatPopup.show(
      context: context,
      level: level,
      playerLevel: playerService.level,
    );

    if (!entered) {
      inputLocked = false;
      return;
    }

    final player = board.pieces.firstWhere((p) => p.team == PieceTeam.player);

    beatSession = BeatWorldSession(
      beatWorldId: portal.beatMapName,
      returnMapName: currentMapName,
      returnX: player.x,
      returnY: player.y,
    );
    currentBeatMapName = portal.spawnMap;

    onBeatSessionChanged?.call(true);

    final entryBoard = await BeatMapLoader.load(
      level: beatSession!.beatWorldId,
      map: portal.spawnMap,
    );

    final playerPiece = entryBoard.pieces.firstWhere(
      (p) => p.team == PieceTeam.player,
    );
    playerPiece.x = portal.spawnX;
    playerPiece.y = portal.spawnY;

    currentMapName = BeatMapLoader.mapRef(
      beatSession!.beatWorldId,
      portal.spawnMap,
    );

    world.removeAll(world.children.toList());
    enemyComponents.clear();

    await initBoard(entryBoard, beatMapName: portal.spawnMap);

    beatConfig = await BeatMapLoader.loadConfig(beatSession!.beatWorldId);
    autoMoveTimer = 0.0;
    autoMovePending = false;
    debugPrint(
      'BeatWorld: Auto-Move Interval = ${beatConfig!.autoMoveIntervalSeconds}s',
    );
    beatTimerController.activate(beatConfig!.autoMoveIntervalSeconds);

    inputLocked = false;
  }

  // ── BeatWorld verlassen (ohne Erfolg) ────────────────────────────────────
  Future<void> exitBeatWorld() async {
    final session = beatSession;
    if (session == null) return;

    inputLocked = true;

    final states = session.getEnemyStates(currentBeatMapName);
    if (states != null && currentBeatMapName.isNotEmpty) {
      await beatLevelService.saveEnemyStates(
        session.beatWorldId,
        currentBeatMapName,
        states,
      );
    }

    beatSession = null;
    currentBeatMapName = '';
    onBeatSessionChanged?.call(false);

    beatConfig = null;
    autoMoveTimer = 0.0;
    autoMovePending = false;
    beatTimerController.deactivate();

    try {
      final newBoard = await BoardLoader.loadMap(session.returnMapName);
      final playerPiece = newBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );

      playerPiece.x = session.returnX;
      playerPiece.y = session.returnY;

      currentMapName = session.returnMapName;
      playerService.savePosition(
        session.returnX,
        session.returnY,
        currentMapName,
      );

      world.removeAll(world.children.toList());
      enemyComponents.clear();

      await initBoard(newBoard);
    } catch (_) {
      currentMapName = 'map_board_1';
      final fallback = await BoardLoader.loadMap('map_board_1');
      world.removeAll(world.children.toList());
      enemyComponents.clear();
      await initBoard(fallback);
    } finally {
      inputLocked = false;
    }
  }
}
