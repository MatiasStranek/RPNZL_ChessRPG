// game/mixins/game_helpers_mixin.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../cell_component.dart';
import 'game_state_mixin.dart';

mixin GameHelpersMixin on GameStateMixin {
  // ── Zoom ──────────────────────────────────────────────────────────────────
  void applyZoom(Vector2 size) {
    final zoom = size.y / (visibleFieldsTotal * CellComponent.cellSize);
    camera.viewfinder.zoom = zoom;
  }

  void setZoomNear() {
    visibleFieldsTotal = 8;
    applyZoom(camera.viewport.size);
  }

  void setZoomDefault() {
    visibleFieldsTotal = 16;
    applyZoom(camera.viewport.size);
  }

  void setZoomFar() {
    visibleFieldsTotal = 22;
    applyZoom(camera.viewport.size);
  }

  // ── Kamera ────────────────────────────────────────────────────────────────
  void shakeCamera(int fromX, int fromY, int toX, int toY) {
    final dir = Vector2((toX - fromX).toDouble(), (toY - fromY).toDouble());
    if (dir.length == 0) return;
    dir.normalize();
    cameraShakeOffset = -dir * 16.0;
  }

  // ── Screen-Position eines Gegners berechnen ───────────────────────────────
  Offset enemyScreenPosition(int gridX, int gridY) {
    final screenSize = camera.viewport.size;
    final cellSize = CellComponent.cellSize;
    final worldX = gridX * cellSize + cellSize / 2;
    final worldY = gridY * cellSize + cellSize / 2;
    final camPos = camera.viewfinder.position;
    final screenX = screenSize.x / 2 + (worldX - camPos.x);
    final screenY = screenSize.y / 2 + (worldY - camPos.y);
    return Offset(screenX, screenY);
  }

  // ── Position nur auf Außen-Maps speichern ────────────────────────────────
  void savePositionIfOutside(int x, int y) {
    if (beatSession == null) {
      playerService.savePosition(x, y, currentMapName);
    }
  }

  // ── Bewegungs-Check ───────────────────────────────────────────────────────
  bool anyoneMoving() {
    return enemyComponents.values.any((c) => c.isMoving);
  }
}
