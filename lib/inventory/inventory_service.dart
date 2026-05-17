// inventory/inventory_service.dart
import 'package:flutter/foundation.dart';
import 'item_model.dart';

class InventoryService {
  static const int totalSlots = 8;
  static const int unlockedSlots = 4;

  final List<ItemModel?> _slots = List.filled(totalSlots, null);

  final ValueNotifier<List<ItemModel?>> inventoryNotifier = ValueNotifier(
    List.filled(totalSlots, null),
  );

  List<ItemModel?> get slots => List.unmodifiable(_slots);

  /// Gibt true zurück wenn Item erfolgreich hinzugefügt wurde
  bool addItem(ItemModel item) {
    for (int i = 0; i < unlockedSlots; i++) {
      if (_slots[i] == null) {
        _slots[i] = item;
        _notify();
        return true;
      }
    }
    // Inventar voll → Item geht verloren
    return false;
  }

  void removeItem(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= totalSlots) return;
    _slots[slotIndex] = null;
    _notify();
  }

  bool get isFull => _slots.sublist(0, unlockedSlots).every((s) => s != null);

  void _notify() {
    inventoryNotifier.value = List.from(_slots);
  }
}
