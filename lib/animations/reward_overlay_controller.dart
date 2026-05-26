// animations/reward_overlay_controller.dart
import 'package:flutter/material.dart';

enum RewardEventType { gold, item, levelUp, beatComplete, chestEarned }

class RewardEvent {
  final RewardEventType type;
  final int? goldAmount;
  final String? itemName;
  final int? newLevel;
  final String? beatLevelName;
  final Offset? worldPosition;
  final bool repeated;

  const RewardEvent({
    required this.type,
    this.goldAmount,
    this.itemName,
    this.newLevel,
    this.beatLevelName,
    this.worldPosition,
    this.repeated = false,
  });
}

class RewardOverlayController extends ChangeNotifier {
  static final RewardOverlayController instance = RewardOverlayController._();
  RewardOverlayController._();

  final List<RewardEvent> _queue = [];
  List<RewardEvent> get queue => List.unmodifiable(_queue);

  void fireGold(int amount, {Offset? position}) {
    _queue.add(
      RewardEvent(
        type: RewardEventType.gold,
        goldAmount: amount,
        worldPosition: position,
      ),
    );
    notifyListeners();
  }

  void fireItem(String itemName) {
    _queue.add(RewardEvent(type: RewardEventType.item, itemName: itemName));
    notifyListeners();
  }

  void fireLevelUp(int newLevel) {
    _queue.add(RewardEvent(type: RewardEventType.levelUp, newLevel: newLevel));
    notifyListeners();
  }

  void fireBeatComplete(String levelName, {bool repeated = false}) {
    _queue.add(
      RewardEvent(
        type: RewardEventType.beatComplete,
        beatLevelName: levelName,
        repeated: repeated,
      ),
    );
    notifyListeners();
  }

  /// Feuert die Kisten-Belohnungsanimation – nur beim ersten Abschluss aufrufen.
  void fireChestEarned(String levelName) {
    _queue.add(
      RewardEvent(type: RewardEventType.chestEarned, beatLevelName: levelName),
    );
    notifyListeners();
  }

  void consume(RewardEvent event) {
    _queue.remove(event);
  }
}
