// game/mixins/game_callbacks_mixin.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../piece/piece_model.dart';
import '../../enemy/enemy_rewards.dart';
import '../../inventory/item_factory.dart';
import '../../animations/reward_overlay_controller.dart';
import '../cell_component.dart';
import 'game_state_mixin.dart';

mixin GameCallbacksMixin on GameStateMixin {
  // ── State-Callbacks ───────────────────────────────────────────────────────
  void setupStateCallbacks() {
    state.onSpawnChanged = (spawned, removed) {
      for (final piece in removed) {
        final comp = enemyComponents.remove(piece);
        comp?.playDeathAnimation();
      }
      for (final piece in spawned) {
        addEnemy(piece);
      }
    };

    state.onEnemiesMoved = () {
      for (final entry in enemyComponents.entries) {
        entry.value.syncPosition();
      }
      persistEnemyPositions();
    };

    state.onEnemyKilled = handleEnemyKilled;

    state.onPlayerDefeated = (killer) {
      gameOver = true;
      inputLocked = false;
    };
  }

  // ── Piece-Callbacks ───────────────────────────────────────────────────────
  void setupPieceCallbacks() {
    pieceComponent.onDropped = (gridX, gridY, fallback) {
      if (inputLocked) {
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
    };
  }

  // ── Enemy-Kill Handler ────────────────────────────────────────────────────
  void handleEnemyKilled(PieceModel enemy) {
    final session = beatSession;
    if (session != null && currentBeatMapName.isNotEmpty) {
      final enemyId =
          enemy.beatEnemyId ?? '${enemy.enemyLevel}_${enemy.x}_${enemy.y}';
      session.markDefeated(currentBeatMapName, enemyId);

      final states = session.getEnemyStates(currentBeatMapName);
      if (states != null) {
        beatLevelService.saveEnemyStates(
          session.beatWorldId,
          currentBeatMapName,
          states,
        );
      }
    }

    if (random.nextDouble() < 0.20) {
      final item = ItemFactory.energyDrop();
      if (inventoryService.addItem(item)) {
        RewardOverlayController.instance.fireItem(item.name);
      }
    }

    final reward = rewardFor(enemy.enemyLevel);
    final levelBefore = playerService.level;
    playerService.rewardForKill(enemy.enemyLevel);
    final levelAfter = playerService.level;

    final enemyPos = enemyScreenPosition(enemy.x, enemy.y);
    RewardOverlayController.instance.fireGold(reward.gold, position: enemyPos);

    if (activeSkillService.isActive) {
      final crazyLeveledUp = playerService.addCrazyExp(
        crazyExpFor(enemy.enemyLevel),
      );
      if (crazyLeveledUp) {
        lastKnownCrazyLevel = playerService.crazyLevel;
        RewardOverlayController.instance.fireLevelUp(playerService.crazyLevel);
        skillService.checkAndUnlockAll();
      }
    }

    if (levelAfter > levelBefore) {
      lastKnownLevel = levelAfter;
      RewardOverlayController.instance.fireLevelUp(levelAfter);
      skillService.checkAndUnlockAll();
    }
  }

  // ── Gegner-Positionen persistieren ───────────────────────────────────────
  void persistEnemyPositions() {
    final session = beatSession;
    if (session == null || currentBeatMapName.isEmpty) return;

    final states = session.getEnemyStates(currentBeatMapName);
    if (states == null) return;

    for (final piece in enemyComponents.keys) {
      final id = piece.beatEnemyId;
      if (id == null) continue;
      final idx = states.indexWhere((s) => s.enemyId == id);
      if (idx == -1) continue;
      states[idx] = states[idx].copyWith(x: piece.x, y: piece.y);
    }

    beatLevelService.saveEnemyStates(
      session.beatWorldId,
      currentBeatMapName,
      states,
    );
  }
}
