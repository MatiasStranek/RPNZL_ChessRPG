// energy/energy_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../player/player_service.dart';

class EnergyService {
  static const String _boxName = 'energy';
  static const String _energyKey = 'current';
  static const String _lastRegenKey = 'lastRegen';
  static const Duration regenInterval = Duration(hours: 6);

  final PlayerService playerService;

  EnergyService({required this.playerService});

  late Box _box;
  late ValueNotifier<int> energyNotifier;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _applyOfflineRegen();
    energyNotifier = ValueNotifier(energy);

    // Wenn sich das Level ändert → Energie-Cap könnte sich erhöht haben
    playerService.playerNotifier.addListener(_onPlayerLevelChanged);
  }

  void dispose() {
    playerService.playerNotifier.removeListener(_onPlayerLevelChanged);
  }

  /// Aktuelles Maximum aus PlayerService – ändert sich mit dem Level.
  int get maxEnergy => playerService.maxEnergy;

  int get energy => (_box.get(_energyKey, defaultValue: maxEnergy) as int)
      .clamp(0, maxEnergy);

  DateTime get _lastRegen {
    final ms = _box.get(
      _lastRegenKey,
      defaultValue: DateTime.now().millisecondsSinceEpoch,
    );
    return DateTime.fromMillisecondsSinceEpoch(ms as int);
  }

  void _setLastRegen(DateTime dt) =>
      _box.put(_lastRegenKey, dt.millisecondsSinceEpoch);

  void _applyOfflineRegen() {
    if (energy >= maxEnergy) return;
    final elapsed = DateTime.now().difference(_lastRegen);
    final ticks = elapsed.inSeconds ~/ regenInterval.inSeconds;
    if (ticks > 0) {
      final newEnergy = (energy + ticks).clamp(0, maxEnergy);
      _box.put(_energyKey, newEnergy);
      _setLastRegen(
        _lastRegen.add(Duration(seconds: ticks * regenInterval.inSeconds)),
      );
    }
  }

  /// Wird aufgerufen wenn der Spieler ein Level aufsteigt → Notifier aktualisieren.
  void _onPlayerLevelChanged() {
    energyNotifier.value =
        energy; // clamp sorgt dafür dass Wert im neuen Cap liegt
  }

  bool spendEnergy() {
    if (energy <= 0) return false;
    final wasMax = energy == maxEnergy;
    _box.put(_energyKey, energy - 1);
    if (wasMax) _setLastRegen(DateTime.now());
    energyNotifier.value = energy;
    return true;
  }

  void restoreEnergy(int amount) {
    final newEnergy = (energy + amount).clamp(0, maxEnergy);
    _box.put(_energyKey, newEnergy);
    energyNotifier.value = newEnergy;
  }

  void drainEnergy() {
    _box.put(_energyKey, 0);
    energyNotifier.value = 0;
  }

  void fillEnergy() {
    _box.put(_energyKey, maxEnergy);
    energyNotifier.value = maxEnergy;
  }

  Duration get timeUntilNextRegen {
    if (energy >= maxEnergy) return Duration.zero;
    final next = _lastRegen.add(regenInterval);
    final diff = next.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
