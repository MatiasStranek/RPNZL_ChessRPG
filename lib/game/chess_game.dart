// game/chess_game.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:collection/collection.dart';
import '../board/board_model.dart';
import '../board/board_loader.dart';
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
import '../portal/portal_service.dart';
import '../portal/portal_types/world_portal.dart';
import '../portal/portal_types/beat_portal.dart';
import '../portal/portal_types/level_exit_portal.dart';
import '../beat/beat_level_service.dart';
import '../beat/beat_popup.dart';
import '../beat/beat_world_session.dart';
import '../beat/beat_map_loader.dart';
import 'cell_component.dart';
import 'piece_component.dart';
import '../enemy/base/enemy_component.dart';
import '../enemy/types/level1/level1_enemy_component.dart';
import 'dart:math';

class ChessGame extends FlameGame with TapCallbacks, DragCallbacks {
  BoardModel board;
  final EnergyService energyService;
  final InventoryService inventoryService;
  final PlayerService playerService;
  final ActiveSkillService activeSkillService;
  final SkillService skillService;
  final BeatLevelService beatLevelService;

  late BoardState state;
  late PieceComponent pieceComponent;
  late PortalService portalService;

  String _currentMapName = 'map_board_1';

  BeatWorldSession? _beatSession;

  void Function(bool active)? onBeatSessionChanged;

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
    required this.beatLevelService,
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

  // ── onLoad ────────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    _lastKnownLevel = playerService.level;
    _lastKnownCrazyLevel = playerService.crazyLevel;
    energyService.energyNotifier.addListener(_onEnergyChanged);

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
      _currentMapName = savedMap;
      await _initBoard(savedBoard);
    } catch (_) {
      playerService.resetPosition();
      _currentMapName = 'map_board_1';
      await _initBoard(board);
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

  // ── Board initialisieren ──────────────────────────────────────────────────
  Future<void> _initBoard(BoardModel newBoard) async {
    board = newBoard;
    portalService = PortalService(portals: newBoard.portals);
    state = BoardState(board: newBoard);
    state.activeSkillService = activeSkillService;

    _setupStateCallbacks();

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
    _setupPieceCallbacks();
    world.add(pieceComponent);

    for (final enemy in newBoard.pieces.where(
      (p) => p.team == PieceTeam.enemy,
    )) {
      _addEnemy(enemy);
    }
  }

  // ── State-Callbacks ───────────────────────────────────────────────────────
  void _setupStateCallbacks() {
    state.onSpawnChanged = (spawned, removed) {
      for (final piece in removed) {
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

    state.onEnemyKilled = _handleEnemyKilled;

    state.onPlayerDefeated = (killer) {
      _gameOver = true;
      _inputLocked = false;
      energyService.drainEnergy();
    };
  }

  // ── Enemy-Kill Handler ────────────────────────────────────────────────────
  void _handleEnemyKilled(PieceModel enemy) {
    if (_random.nextDouble() < 0.20) {
      final item = ItemFactory.energyDrop();
      if (inventoryService.addItem(item)) {
        RewardOverlayController.instance.fireItem(item.name);
      }
    }

    final reward = rewardFor(enemy.enemyLevel);
    final levelBefore = playerService.level;
    playerService.rewardForKill(enemy.enemyLevel);
    final levelAfter = playerService.level;

    final enemyPos = _enemyScreenPosition(enemy.x, enemy.y);
    RewardOverlayController.instance.fireGold(reward.gold, position: enemyPos);

    if (activeSkillService.isActive) {
      final crazyLeveledUp = playerService.addCrazyExp(
        crazyExpFor(enemy.enemyLevel),
      );
      if (crazyLeveledUp) {
        _lastKnownCrazyLevel = playerService.crazyLevel;
        RewardOverlayController.instance.fireLevelUp(playerService.crazyLevel);
        skillService.checkAndUnlockAll();
      }
    }

    if (levelAfter > levelBefore) {
      _lastKnownLevel = levelAfter;
      RewardOverlayController.instance.fireLevelUp(levelAfter);
      skillService.checkAndUnlockAll();
    }
  }

  // ── Piece-Callbacks ───────────────────────────────────────────────────────
  void _setupPieceCallbacks() {
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

      _savePositionIfOutside(player.x, player.y);
      _checkPortal(player.x, player.y);

      Future.delayed(const Duration(milliseconds: 16), () {
        _shakeCamera(oldX, oldY, player.x, player.y);
      });

      _inputLocked = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        state.moveEnemiesNow();
      });
    };
  }

  // ── Position nur auf Außen-Maps speichern ─────────────────────────────────
  void _savePositionIfOutside(int x, int y) {
    if (_beatSession == null) {
      playerService.savePosition(x, y, _currentMapName);
    }
  }

  // ── Portal-Logik ──────────────────────────────────────────────────────────
  void _checkPortal(int x, int y) {
    // Level Exit zuerst prüfen
    final exitPortal = portalService.levelExitPortalAt(x, y);
    if (exitPortal != null) {
      _completeBeatLevel();
      return;
    }

    final worldPortal = portalService.worldPortalAt(x, y);
    if (worldPortal != null) {
      _travelToMap(worldPortal);
      return;
    }

    if (_beatSession == null) {
      final beatPortal = portalService.beatPortalAt(x, y);
      if (beatPortal != null) {
        _showBeatPortalPopup(beatPortal);
      }
    }
  }

  // ── Level abschließen ─────────────────────────────────────────────────────
  Future<void> _completeBeatLevel() async {
    final session = _beatSession;
    if (session == null) return;

    _inputLocked = true;

    // ── VOR markCompleted prüfen ob bereits abgeschlossen ────────────────
    final wasAlreadyCompleted = beatLevelService.isCompleted(
      session.beatWorldId,
    );

    await beatLevelService.markCompleted(session.beatWorldId);

    // ── Beat-Complete Animation feuern ───────────────────────────────────
    RewardOverlayController.instance.fireBeatComplete(
      session.beatWorldId,
      repeated: wasAlreadyCompleted, // ← "Erneut Abgeschlossen" wenn true
    );

    _beatSession = null;
    onBeatSessionChanged?.call(false);

    try {
      final newBoard = await BoardLoader.loadMap(session.returnMapName);
      final playerPiece = newBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );
      playerPiece.x = session.returnX;
      playerPiece.y = session.returnY;

      _currentMapName = session.returnMapName;
      playerService.savePosition(
        session.returnX,
        session.returnY,
        _currentMapName,
      );

      world.removeAll(world.children.toList());
      _enemyComponents.clear();

      await _initBoard(newBoard);
    } catch (_) {
      _currentMapName = 'map_board_1';
      final fallback = await BoardLoader.loadMap('map_board_1');
      world.removeAll(world.children.toList());
      _enemyComponents.clear();
      await _initBoard(fallback);
    } finally {
      _inputLocked = false;
    }
  }

  // ── World Portal: Map-Wechsel ─────────────────────────────────────────────
  Future<void> _travelToMap(WorldPortal portal) async {
    _inputLocked = true;

    final newBoard = await _loadBoardByRef(portal.targetMap);
    final targetPortalService = PortalService(portals: newBoard.portals);
    final linkedPortal = targetPortalService.portalById(portal.linkedPortalId);

    final spawnX = linkedPortal?.x ?? 1;
    final spawnY = linkedPortal?.y ?? 1;

    final playerPiece = newBoard.pieces.firstWhere(
      (p) => p.team == PieceTeam.player,
    );
    playerPiece.x = spawnX;
    playerPiece.y = spawnY;

    _currentMapName = portal.targetMap;

    if (_beatSession == null) {
      playerService.savePosition(spawnX, spawnY, _currentMapName);
    }

    world.removeAll(world.children.toList());
    _enemyComponents.clear();

    await _initBoard(newBoard);
    _inputLocked = false;
  }

  // ── Map laden anhand Referenz-String ──────────────────────────────────────
  Future<BoardModel> _loadBoardByRef(String ref) {
    final beatRef = BeatMapLoader.parseRef(ref);
    if (beatRef != null) {
      return BeatMapLoader.load(level: beatRef.level, map: beatRef.map);
    }
    return BoardLoader.loadMap(ref);
  }

  // ── Beat Portal PopUp ─────────────────────────────────────────────────────
  Future<void> _showBeatPortalPopup(BeatPortal portal) async {
    _inputLocked = true;

    final context = buildContext;
    if (context == null) {
      _inputLocked = false;
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
      _inputLocked = false;
      return;
    }

    // ── BeatWorld betreten ────────────────────────────────────────────────
    final player = board.pieces.firstWhere((p) => p.team == PieceTeam.player);

    _beatSession = BeatWorldSession(
      beatWorldId: portal.beatMapName,
      returnMapName: _currentMapName,
      returnX: player.x,
      returnY: player.y,
    );

    onBeatSessionChanged?.call(true);

    final entryBoard = await BeatMapLoader.load(
      level: _beatSession!.beatWorldId,
      map: portal.spawnMap,
    );

    final playerPiece = entryBoard.pieces.firstWhere(
      (p) => p.team == PieceTeam.player,
    );
    playerPiece.x = portal.spawnX;
    playerPiece.y = portal.spawnY;

    _currentMapName = BeatMapLoader.mapRef(
      _beatSession!.beatWorldId,
      portal.spawnMap,
    );

    world.removeAll(world.children.toList());
    _enemyComponents.clear();

    await _initBoard(entryBoard);
    _inputLocked = false;
  }

  // ── BeatWorld verlassen (ohne Erfolg) ────────────────────────────────────
  Future<void> exitBeatWorld() async {
    final session = _beatSession;
    if (session == null) return;

    _inputLocked = true;
    _beatSession = null;
    onBeatSessionChanged?.call(false);

    try {
      final newBoard = await BoardLoader.loadMap(session.returnMapName);
      final playerPiece = newBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );

      playerPiece.x = session.returnX;
      playerPiece.y = session.returnY;

      _currentMapName = session.returnMapName;
      playerService.savePosition(
        session.returnX,
        session.returnY,
        _currentMapName,
      );

      world.removeAll(world.children.toList());
      _enemyComponents.clear();

      await _initBoard(newBoard);
    } catch (_) {
      _currentMapName = 'map_board_1';
      final fallback = await BoardLoader.loadMap('map_board_1');
      world.removeAll(world.children.toList());
      _enemyComponents.clear();
      await _initBoard(fallback);
    } finally {
      _inputLocked = false;
    }
  }

  // ── Teleport zur gespeicherten Position (Cheat-Reset) ────────────────────
  Future<void> teleportToSavedPosition() async {
    if (_beatSession != null) {
      _beatSession = null;
      onBeatSessionChanged?.call(false);
    }

    _inputLocked = true;
    final mapName = playerService.savedMap;

    try {
      final newBoard = await BoardLoader.loadMap(mapName);
      final playerPiece = newBoard.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );

      _currentMapName = mapName;
      playerService.savePosition(playerPiece.x, playerPiece.y, mapName);

      world.removeAll(world.children.toList());
      _enemyComponents.clear();

      await _initBoard(newBoard);
    } catch (_) {
      _currentMapName = 'map_board_1';
      final fallback = await BoardLoader.loadMap('map_board_1');
      final playerPiece = fallback.pieces.firstWhere(
        (p) => p.team == PieceTeam.player,
      );
      playerService.savePosition(playerPiece.x, playerPiece.y, 'map_board_1');
      world.removeAll(world.children.toList());
      _enemyComponents.clear();
      await _initBoard(fallback);
    } finally {
      _inputLocked = false;
      _gameOver = false;
    }
  }

  // ── update ────────────────────────────────────────────────────────────────
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

  // ── onTapDown ─────────────────────────────────────────────────────────────
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

    _savePositionIfOutside(player.x, player.y);
    _checkPortal(player.x, player.y);

    Future.delayed(const Duration(milliseconds: 16), () {
      _shakeCamera(oldX, oldY, player.x, player.y);
    });

    _inputLocked = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      state.moveEnemiesNow();
    });
  }

  // ── Hilfsmethoden ─────────────────────────────────────────────────────────
  void _addEnemy(PieceModel piece) {
    final EnemyComponent comp = switch (piece.enemyLevel) {
      1 => Level1EnemyComponent(piece: piece),
      _ => Level1EnemyComponent(piece: piece),
    };

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
    final screenX = screenSize.x / 2 + (worldX - camPos.x);
    final screenY = screenSize.y / 2 + (worldY - camPos.y);
    return Offset(screenX, screenY);
  }
}
