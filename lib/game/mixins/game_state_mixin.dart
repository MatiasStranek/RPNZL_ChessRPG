// game/mixins/game_state_mixin.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../board/board_model.dart';
import '../../board/board_state.dart';
import '../../piece/piece_model.dart';
import '../../energy/energy_service.dart';
import '../../inventory/inventory_service.dart';
import '../../player/player_service.dart';
import '../../skills/active_skill_service.dart';
import '../../skills/skill_service.dart';
import '../../beat/beat_level_service.dart';
import '../../beat/beat_level_config.dart';
import '../../beat/beat_world_session.dart';
import '../../beat/beat_timer/beat_timer_controller.dart';
import '../../portal/portal_service.dart';
import '../../enemy/base/enemy_component.dart';
import '../piece_component.dart';
import 'dart:math';

/// Hält alle gemeinsamen Felder UND abstrakte Methoden-Signaturen,
/// damit jedes Mixin die Methoden der anderen kennt – ohne zirkuläre
/// on-Constraints.
mixin GameStateMixin on FlameGame {
  // ── Externe Services ──────────────────────────────────────────────────────
  late EnergyService energyService;
  late InventoryService inventoryService;
  late PlayerService playerService;
  late ActiveSkillService activeSkillService;
  late SkillService skillService;
  late BeatLevelService beatLevelService;

  // ── Game-State ────────────────────────────────────────────────────────────
  late BoardModel board;
  late BoardState state;
  late PieceComponent pieceComponent;
  late PortalService portalService;

  String currentMapName = 'map_board_1';
  String currentBeatMapName = '';

  BeatWorldSession? beatSession;
  BeatLevelConfig? beatConfig;

  void Function(bool active)? onBeatSessionChanged;

  Vector2 cameraShakeOffset = Vector2.zero();
  bool gameOver = false;
  bool inputLocked = false;

  double visibleFieldsTotal = 8;
  int lastKnownLevel = 0;
  int lastKnownCrazyLevel = 0;

  final Map<PieceModel, EnemyComponent> enemyComponents = {};
  final Random random = Random();

  // ── Auto-Move Timer ───────────────────────────────────────────────────────
  double autoMoveTimer = 0.0;
  bool autoMovePending = false;

  // ── Beat Timer ────────────────────────────────────────────────────────────
  late BeatTimerController beatTimerController;

  // ── Abstrakte Methoden – werden in den jeweiligen Mixins implementiert ────
  // Jedes Mixin kann diese aufrufen ohne on-Abhängigkeit zum anderen Mixin.
  Future<void> initBoard(BoardModel newBoard, {String? beatMapName});
  Future<BoardModel> loadBoardByRef(String ref);
  void addEnemy(PieceModel piece);
  void checkPortal(int x, int y);
  void savePositionIfOutside(int x, int y);
  void shakeCamera(int fromX, int fromY, int toX, int toY);
  Offset enemyScreenPosition(int gridX, int gridY);
  void setupStateCallbacks();
  void setupPieceCallbacks();
  void handleEnemyKilled(PieceModel enemy);
  void persistEnemyPositions();
  bool anyoneMoving();
}
