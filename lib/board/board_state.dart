import 'dart:math';
import 'package:flutter/material.dart';
import 'board_model.dart';
import 'spawn_zone.dart';
import 'package:chessrpg/piece/piece_model.dart';

class _DeadEnemy {
  final SpawnZone zone;
  int turnsLeft;
  _DeadEnemy({required this.zone, required this.turnsLeft});
}

class BoardState extends ChangeNotifier {
  BoardModel board;
  PieceModel? selectedPiece;

  final Map<PieceModel, _DeadEnemy> _dead = {};

  void Function(List<PieceModel> spawned, List<PieceModel> removed)?
  onSpawnChanged;
  void Function(PieceModel killer)? onPlayerDefeated;

  final Random _rng = Random();

  BoardState({required this.board}) {
    _initialSpawn();
  }

  void selectPiece(PieceModel piece) {
    selectedPiece = (selectedPiece == piece) ? null : piece;
    notifyListeners();
  }

  void deselectPiece() {
    if (selectedPiece == null) return;
    selectedPiece = null;
    notifyListeners();
  }

  void movePiece(int x, int y) {
    if (selectedPiece == null) return;
    if (board.cells[y][x] == CellType.hole) return;

    final dx = (x - selectedPiece!.x).abs();
    final dy = (y - selectedPiece!.y).abs();
    if (dx > 1 || dy > 1) {
      selectedPiece = null;
      notifyListeners();
      return;
    }

    final killed = _enemyAt(x, y);
    final List<PieceModel> removed = [];
    if (killed != null) {
      removed.add(killed);
      _killEnemy(killed);
    }

    selectedPiece!.x = x;
    selectedPiece!.y = y;
    final player = selectedPiece!;
    selectedPiece = null;

    _moveEnemies(player);

    final killer = _enemies()
        .where((e) => e.x == player.x && e.y == player.y)
        .firstOrNull;
    if (killer != null) {
      removed.add(killer);
      _killEnemy(killer);
      final spawned = _tickRespawns();
      notifyListeners();
      onSpawnChanged?.call(spawned, removed);
      onPlayerDefeated?.call(killer);
      return;
    }

    final spawned = _tickRespawns();
    notifyListeners();
    if (spawned.isNotEmpty || removed.isNotEmpty) {
      onSpawnChanged?.call(spawned, removed);
    }
  }

  void tickOnly() {
    final spawned = _tickRespawns();
    if (spawned.isNotEmpty) {
      notifyListeners();
      onSpawnChanged?.call(spawned, []);
    }
  }

  bool isReachable(int x, int y) {
    if (selectedPiece == null) return false;
    if (board.cells[y][x] == CellType.hole) return false;
    final dx = (x - selectedPiece!.x).abs();
    final dy = (y - selectedPiece!.y).abs();
    return dx <= 1 && dy <= 1 && !(dx == 0 && dy == 0);
  }

  // ─── Interna ───────────────────────────────────────────────────────────────

  void _killEnemy(PieceModel enemy) {
    board.pieces.remove(enemy);
    final zone = enemy.spawnZone;
    if (zone != null) {
      _dead[enemy] = _DeadEnemy(zone: zone, turnsLeft: zone.respawnAfterTurns);
    }
  }

  void _initialSpawn() {
    for (final zone in board.spawnZones) {
      _fillZone(zone);
    }
  }

  void _fillZone(SpawnZone zone) {
    final alive = _enemies().where((e) => e.spawnZone == zone).length;
    final slots = zone.maxEnemies - alive;
    for (int i = 0; i < slots; i++) {
      final pos = _randomFreeCell(zone);
      if (pos == null) break;
      board.pieces.add(
        PieceModel(
          team: PieceTeam.enemy,
          x: pos[0],
          y: pos[1],
          spawnZone: zone,
        ),
      );
    }
  }

  List<PieceModel> _tickRespawns() {
    final spawned = <PieceModel>[];
    final toRespawn = <PieceModel>[];

    for (final entry in _dead.entries) {
      entry.value.turnsLeft--;
      if (entry.value.turnsLeft <= 0) {
        toRespawn.add(entry.key);
      }
    }

    for (final dead in toRespawn) {
      final zone = _dead[dead]!.zone;
      final pos = _randomFreeCell(zone);
      if (pos == null) {
        _dead[dead]!.turnsLeft = 1;
        continue;
      }
      _dead.remove(dead);
      final piece = PieceModel(
        team: PieceTeam.enemy,
        x: pos[0],
        y: pos[1],
        spawnZone: zone,
      );
      board.pieces.add(piece);
      spawned.add(piece);
    }

    return spawned;
  }

  void _moveEnemies(PieceModel player) {
    for (final enemy in _enemies()) {
      final stepX = (player.x - enemy.x).clamp(-1, 1);
      final stepY = (player.y - enemy.y).clamp(-1, 1);
      final nx = enemy.x + stepX;
      final ny = enemy.y + stepY;

      if (nx < 0 || nx >= board.width || ny < 0 || ny >= board.height) continue;
      if (board.cells[ny][nx] == CellType.hole) continue;
      if (_enemies().any((e) => e != enemy && e.x == nx && e.y == ny)) continue;

      enemy.x = nx;
      enemy.y = ny;
    }
  }

  List<PieceModel> _enemies() =>
      board.pieces.where((p) => p.team == PieceTeam.enemy).toList();

  PieceModel? _enemyAt(int x, int y) =>
      _enemies().where((e) => e.x == x && e.y == y).firstOrNull;

  List<int>? _randomFreeCell(SpawnZone zone) {
    final candidates = <List<int>>[];
    for (int y = zone.top; y <= zone.bottom; y++) {
      for (int x = zone.left; x <= zone.right; x++) {
        if (board.cells[y][x] == CellType.hole) continue;
        if (board.pieces.any((p) => p.x == x && p.y == y)) continue;
        candidates.add([x, y]);
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[_rng.nextInt(candidates.length)];
  }
}
