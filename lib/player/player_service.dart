// player/player_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../enemy/enemy_rewards.dart';

// ─── Freischaltungs-Konfiguration ──────────────────────────────────────────
const int _baseUnlockedSlots = 4;
const int _baseMaxEnergy = 4;
const int _slotsPerLevel = 1;
const int _energyPerLevel = 1;

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

  int get unlockedSlots => _baseUnlockedSlots + (level * _slotsPerLevel);
  int get maxEnergy => _baseMaxEnergy + (level * _energyPerLevel);

  int? get expToNextLevel {
    if (level >= _maxLevel) return null;
    final nextThreshold = (level + 1) * _expPerLevel;
    return nextThreshold - exp;
  }

  int get expCurrentLevelFloor => level * _expPerLevel;
  int get expNextLevelCeil => (level + 1) * _expPerLevel;

  double get levelProgress {
    if (level >= _maxLevel) return 1.0;
    final floor = expCurrentLevelFloor;
    final ceil = expNextLevelCeil;
    return ((exp - floor) / (ceil - floor)).clamp(0.0, 1.0);
  }

  int get expInCurrentLevel => exp - expCurrentLevelFloor;

  // ─── Aktionen ────────────────────────────────────────────────────────────

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

  // ─── Cheat-Methoden ──────────────────────────────────────────────────────

  /// Setzt Gold auf 0 und aktualisiert die Anzeige sofort.
  void resetGold() {
    _box.put(_goldKey, 0);
    _notify();
  }

  /// Gibt 999 Gold und aktualisiert die Anzeige sofort.
  void cheatAddGold() {
    _box.put(_goldKey, gold + 999);
    _notify();
  }

  /// Setzt EXP und Level auf 0 und aktualisiert die Anzeige sofort.
  void resetExp() {
    _box.put(_expKey, 0);
    _box.put(_levelKey, 0);
    _notify();
  }

  /// Gibt 50 EXP (mit Level-Up-Logik) und aktualisiert die Anzeige sofort.
  void cheatAddExp() {
    _addExp(50);
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
  final int? expToNextLevel;
  final int expInCurrentLevel;
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