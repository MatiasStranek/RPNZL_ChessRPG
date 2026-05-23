// animations/reward_overlay_controller.dart
import 'package:flutter/material.dart';

/// Event-Typen die animiert werden können
enum RewardEventType { gold, item, levelUp }

class RewardEvent {
  final RewardEventType type;
  final int? goldAmount;
  final String? itemName;
  final int? newLevel;
  final Offset? worldPosition; // optionale Startposition

  const RewardEvent({
    required this.type,
    this.goldAmount,
    this.itemName,
    this.newLevel,
    this.worldPosition,
  });
}

/// Globaler Controller – ChessGame feuert Events, RewardOverlay lauscht
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

  void consume(RewardEvent event) {
    _queue.remove(event);
  }
}
