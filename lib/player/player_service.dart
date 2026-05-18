// player/player_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../enemy/enemy_rewards.dart';

// ─── Freischaltungs-Konfiguration ──────────────────────────────────────────
// Basis-Werte bei Level 0. Pro Level-Up kommt jeweils +1 dazu.
// Willst du die Progression ändern, nur hier anpassen.
const int _baseUnlockedSlots = 4;
const int _baseMaxEnergy = 4;
const int _slotsPerLevel = 1;
const int _energyPerLevel = 1;

// 10 Level à 10 EXP  →  Level 1 bei 10, Level 2 bei 20, …, Level 10 bei 100
const int _expPerLevel = 10;
const int _maxLevel = 10;

class PlayerService {
  static const String _boxName = 'player';
  static const String _goldKey = 'gold';
  static const String _expKey = 'exp';
  static const String _levelKey = 'level';

  late Box _box;
  late ValueNotifier<PlayerState> playerNotifier;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    playerNotifier = ValueNotifier(_currentState());
  }

  // ─── Getter ──────────────────────────────────────────────────────────────

  int get gold => _box.get(_goldKey, defaultValue: 0) as int;
  int get exp => _box.get(_expKey, defaultValue: 0) as int;
  int get level => _box.get(_levelKey, defaultValue: 0) as int;

  /// Freigeschaltete Inventar-Slots für das aktuelle Level.
  /// Ändert sich automatisch wenn sich das Level ändert.
  int get unlockedSlots => _baseUnlockedSlots + (level * _slotsPerLevel);

  /// Maximale Energie für das aktuelle Level.
  int get maxEnergy => _baseMaxEnergy + (level * _energyPerLevel);

  /// EXP die noch für den nächsten Level-Up fehlen (null = Max-Level).
  int? get expToNextLevel {
    if (level >= _maxLevel) return null;
    final nextThreshold = (level + 1) * _expPerLevel;
    return nextThreshold - exp;
  }

  /// EXP die für das aktuelle Level benötigt werden (untere Grenze).
  int get expCurrentLevelFloor => level * _expPerLevel;

  /// EXP die für den nächsten Level-Up benötigt werden (obere Grenze).
  int get expNextLevelCeil => (level + 1) * _expPerLevel;

  /// Fortschritt innerhalb des aktuellen Levels als 0.0–1.0.
  double get levelProgress {
    if (level >= _maxLevel) return 1.0;
    final floor = expCurrentLevelFloor;
    final ceil = expNextLevelCeil;
    return ((exp - floor) / (ceil - floor)).clamp(0.0, 1.0);
  }

  /// EXP im aktuellen Level (z.B. "7" bei 7/10).
  int get expInCurrentLevel => exp - expCurrentLevelFloor;

  // ─── Aktionen ────────────────────────────────────────────────────────────

  /// Belohnung für das Besiegen eines Gegners auszahlen.
  PlayerState rewardForKill(int enemyLevel) {
    final reward = rewardFor(enemyLevel);
    _addGold(reward.gold);
    _addExp(reward.exp);
    return _currentState();
  }

  void addGold(int amount) => _addGold(amount);

  bool spendGold(int amount) {
    if (gold < amount) return false;
    _box.put(_goldKey, gold - amount);
    _notify();
    return true;
  }

  // ─── Interne Helfer ──────────────────────────────────────────────────────

  void _addGold(int amount) {
    _box.put(_goldKey, gold + amount);
    _notify();
  }

  void _addExp(int amount) {
    var newExp = exp + amount;
    var newLevel = level;

    while (newLevel < _maxLevel && newExp >= (newLevel + 1) * _expPerLevel) {
      newLevel++;
    }

    _box.put(_expKey, newExp);
    _box.put(_levelKey, newLevel);
    _notify();
  }

  void _notify() => playerNotifier.value = _currentState();

  PlayerState _currentState() => PlayerState(
    gold: gold,
    exp: exp,
    level: level,
    levelProgress: levelProgress,
    expToNextLevel: expToNextLevel,
    expInCurrentLevel: expInCurrentLevel,
    unlockedSlots: unlockedSlots,
    maxEnergy: maxEnergy,
  );
}

// ─── Immutable Snapshot ──────────────────────────────────────────────────────

class PlayerState {
  final int gold;
  final int exp;
  final int level;
  final double levelProgress;
  final int? expToNextLevel; // null = Max-Level
  final int expInCurrentLevel; // z.B. 7 bei "7/10"
  final int unlockedSlots;
  final int maxEnergy;

  const PlayerState({
    required this.gold,
    required this.exp,
    required this.level,
    required this.levelProgress,
    required this.expToNextLevel,
    required this.expInCurrentLevel,
    required this.unlockedSlots,
    required this.maxEnergy,
  });

  @override
  String toString() =>
      'PlayerState(Lv.$level | $expInCurrentLevel EXP | $gold Gold)';
}
