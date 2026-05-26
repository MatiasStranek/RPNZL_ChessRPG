// game/mixins/game_board_mixin.dart
import 'package:flame/components.dart';
import 'package:collection/collection.dart';
import '../../board/board_loader.dart';
import '../../board/board_model.dart';
import '../../board/board_state.dart';
import '../../piece/piece_model.dart';
import '../../beat/beat_world_session.dart';
import '../../beat/beat_map_loader.dart';
import '../../beat/beat_enemy_state.dart';
import '../../portal/portal_service.dart';
import '../cell_component.dart';
import '../piece_component.dart';
import '../../enemy/types/level1/level1_enemy_component.dart';
import '../../enemy/base/enemy_component.dart';
import '../../animations/dust_animation_component.dart';
import 'game_state_mixin.dart';

mixin GameBoardMixin on GameStateMixin {
  // ── Board initialisieren ──────────────────────────────────────────────────
  Future<void> initBoard(BoardModel newBoard, {String? beatMapName}) async {
    board = newBoard;
    portalService = PortalService(portals: newBoard.portals);
    state = BoardState(board: newBoard);
    state.activeSkillService = activeSkillService;

    setupStateCallbacks();

    for (int y = 0; y < newBoard.height; y++) {
      for (int x = 0; x < newBoard.width; x++) {
        world.add(
          CellComponent(
            cellType: newBoard.cells[y][x],
            gridX: x,
            gridY: y,
            state: state,
          ),
        );
      }
    }

    final piece = newBoard.pieces.firstWhere((p) => p.team == PieceTeam.player);
    pieceComponent = PieceComponent(piece: piece);
    setupPieceCallbacks();
    world.add(pieceComponent);

    final session = beatSession;
    if (beatMapName != null && session != null) {
      await spawnEnemiesFromSession(newBoard, session, beatMapName);
    } else {
      for (final enemy in newBoard.pieces.where(
        (p) => p.team == PieceTeam.enemy,
      )) {
        addEnemy(enemy);
      }
    }
  }

  // ── Gegner aus Session-Zustand spawnen ────────────────────────────────────
  Future<void> spawnEnemiesFromSession(
    BoardModel newBoard,
    BeatWorldSession session,
    String mapName,
  ) async {
    var savedStates = session.getEnemyStates(mapName);

    if (savedStates == null) {
      savedStates = beatLevelService.loadEnemyStates(
        session.beatWorldId,
        mapName,
      );
    }

    if (savedStates != null) {
      session.saveEnemyStates(mapName, savedStates);

      final defeatedIds = savedStates
          .where((e) => e.defeated)
          .map((e) => e.enemyId)
          .toSet();

      newBoard.pieces.removeWhere(
        (p) =>
            p.team == PieceTeam.enemy &&
            defeatedIds.contains('${p.enemyLevel}_${p.x}_${p.y}'),
      );

      for (final enemyState in savedStates.where((e) => !e.defeated)) {
        final piece = newBoard.pieces.firstWhereOrNull(
          (p) =>
              p.team == PieceTeam.enemy &&
              '${p.enemyLevel}_${p.x}_${p.y}' == enemyState.enemyId,
        );
        if (piece != null) {
          piece.beatEnemyId = enemyState.enemyId;
          piece.x = enemyState.x;
          piece.y = enemyState.y;
          addEnemy(piece);
        }
      }
    } else {
      final enemies = newBoard.pieces
          .where((p) => p.team == PieceTeam.enemy)
          .toList();

      final initialStates = enemies
          .map(
            (p) => BeatEnemyState(
              enemyId: '${p.enemyLevel}_${p.x}_${p.y}',
              defeated: false,
              x: p.x,
              y: p.y,
            ),
          )
          .toList();

      session.saveEnemyStates(mapName, initialStates);
      await beatLevelService.saveEnemyStates(
        session.beatWorldId,
        mapName,
        initialStates,
      );

      for (final p in enemies) {
        p.beatEnemyId = '${p.enemyLevel}_${p.x}_${p.y}';
        addEnemy(p);
      }
    }
  }

  // ── Gegner hinzufügen ─────────────────────────────────────────────────────
  void addEnemy(PieceModel piece) {
    final EnemyComponent comp = switch (piece.enemyLevel) {
      1 => Level1EnemyComponent(piece: piece),
      _ => Level1EnemyComponent(piece: piece),
    };

    comp.onPlayDeathEffect = (pos) {
      world.add(DustAnimationComponent(cellPosition: pos));
    };

    enemyComponents[piece] = comp;
    world.add(comp);
  }

  // ── Map laden anhand Referenz-String ─────────────────────────────────────
  Future<BoardModel> loadBoardByRef(String ref) {
    final beatRef = BeatMapLoader.parseRef(ref);
    if (beatRef != null) {
      return BeatMapLoader.load(level: beatRef.level, map: beatRef.map);
    }
    return BoardLoader.loadMap(ref);
  }
}
