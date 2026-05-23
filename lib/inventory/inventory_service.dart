// inventory/inventory_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../player/player_service.dart';
import 'item_model.dart';
import 'item_effect.dart';
import 'item_factory.dart';
import 'upgrades/energy_upgrades.dart';

class InventoryService {
  static const int totalSlots = 32;
  static const String _boxName = 'inventory';

  final PlayerService playerService;

  InventoryService({required this.playerService});

  late Box<String> _box;

  final List<ItemModel?> _slots = List.filled(totalSlots, null);

  final ValueNotifier<List<ItemModel?>> inventoryNotifier = ValueNotifier(
    List.filled(totalSlots, null),
  );

  // ── Kategorie-Freischaltung ───────────────────────────────────────────────
  final ValueNotifier<Set<ItemCategory>> unlockedCategoriesNotifier =
      ValueNotifier({ItemCategory.energy});

  bool isCategoryUnlocked(ItemCategory cat) =>
      unlockedCategoriesNotifier.value.contains(cat);

  void unlockCategory(ItemCategory cat) {
    final current = Set<ItemCategory>.from(unlockedCategoriesNotifier.value);
    if (current.add(cat)) {
      unlockedCategoriesNotifier.value = current;
    }
  }

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _loadFromHive();
    playerService.playerNotifier.addListener(_onPlayerLevelChanged);
  }

  void dispose() {
    playerService.playerNotifier.removeListener(_onPlayerLevelChanged);
  }

  int get unlockedSlots => playerService.unlockedSlots.clamp(0, totalSlots);

  List<ItemModel?> get slots => List.unmodifiable(_slots);

  bool addItem(ItemModel item) {
    for (int i = 0; i < unlockedSlots; i++) {
      if (_slots[i] == null) {
        _slots[i] = item;
        _save();
        _notify();
        return true;
      }
    }
    return false;
  }

  void removeItem(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= totalSlots) return;
    _slots[slotIndex] = null;
    _save();
    _notify();
  }

  ItemEffect? useItem(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= totalSlots) return null;
    final item = _slots[slotIndex];
    if (item == null) return null;
    _slots[slotIndex] = null;
    _save();
    _notify();
    return item.effect;
  }

  void moveItem(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (fromIndex < 0 ||
        fromIndex >= totalSlots ||
        toIndex < 0 ||
        toIndex >= totalSlots)
      return;
    if (toIndex >= unlockedSlots) return;

    final from = _slots[fromIndex];
    if (from == null) return;

    final to = _slots[toIndex];
    if (to != null && from.category != to.category) return;

    if (to != null && from.id == to.id && from.upgradesTo != null) {
      _slots[toIndex] = from.upgradesTo!();
      _slots[fromIndex] = null;
      _save();
      _notify();
      return;
    }

    _slots[toIndex] = from;
    _slots[fromIndex] = to;
    _save();
    _notify();
  }

  bool get isFull => _slots.sublist(0, unlockedSlots).every((s) => s != null);

  // ─── Cheat-Methoden ───────────────────────────────────────────────────────

  /// Entfernt alle Items aus allen Slots und aktualisiert sofort.
  void clearAll() {
    for (int i = 0; i < totalSlots; i++) {
      _slots[i] = null;
    }
    _box.clear();
    _notify();
  }

  /// Entfernt Items die in gesperrten Slots liegen (z.B. nach Level-Reset).
  /// Wird automatisch aufgerufen wenn sich unlockedSlots verringert.
  void removeItemsInLockedSlots() {
    final unlocked = unlockedSlots;
    bool changed = false;
    for (int i = unlocked; i < totalSlots; i++) {
      if (_slots[i] != null) {
        _slots[i] = null;
        changed = true;
      }
    }
    if (changed) {
      _save();
      _notify();
    }
  }

  // ─── Interne Helfer ───────────────────────────────────────────────────────

  void _onPlayerLevelChanged() {
    // Bei jedem Level-Wechsel prüfen ob Items in gesperrten Slots liegen
    removeItemsInLockedSlots();
    _notify();
  }

  void _save() {
    for (int i = 0; i < totalSlots; i++) {
      final item = _slots[i];
      if (item == null) {
        _box.delete('slot_$i');
      } else {
        _box.put('slot_$i', item.id);
      }
    }
  }

  void _loadFromHive() {
    for (int i = 0; i < totalSlots; i++) {
      final id = _box.get('slot_$i');
      if (id != null) _slots[i] = _itemFromId(id);
    }
    _notify();
  }

  ItemModel? _itemFromId(String id) {
    switch (id) {
      case 'energy_drop':
        return ItemFactory.energyDrop();
      case 'energy_upgrade_1':
        return energyUpgrade1();
      case 'energy_upgrade_2':
        return energyUpgrade2();
      case 'energy_upgrade_3':
        return energyUpgrade3();
      case 'energy_upgrade_4':
        return energyUpgrade4();
      case 'energy_upgrade_5':
        return energyUpgrade5();
      case 'energy_upgrade_6':
        return energyUpgrade6();
      default:
        return null;
    }
  }

  void _notify() => inventoryNotifier.value = List.from(_slots);
}
