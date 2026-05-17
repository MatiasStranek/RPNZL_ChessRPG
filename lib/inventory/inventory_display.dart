// inventory/inventory_display.dart
import 'package:flutter/material.dart';
import 'inventory_service.dart';
import 'item_model.dart';

class InventoryDisplay extends StatelessWidget {
  final InventoryService inventoryService;

  const InventoryDisplay({super.key, required this.inventoryService});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ValueListenableBuilder<List<ItemModel?>>(
          valueListenable: inventoryService.inventoryNotifier,
          builder: (context, slots, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(InventoryService.totalSlots, (i) {
                final unlocked = i < InventoryService.unlockedSlots;
                final item = slots[i];
                return _SlotWidget(
                  item: item,
                  unlocked: unlocked,
                  onTap: unlocked && item != null
                      ? () => inventoryService.removeItem(i)
                      : null,
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _SlotWidget extends StatelessWidget {
  final ItemModel? item;
  final bool unlocked;
  final VoidCallback? onTap;

  const _SlotWidget({required this.item, required this.unlocked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFF3A3A3A) : const Color(0xFF222222),
          border: Border.all(
            color: unlocked ? const Color(0xFF888888) : const Color(0xFF444444),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: unlocked
            ? item != null
                  ? Center(
                      child: Text(
                        '⚔️', // ← Icon für den Drop, später anpassbar
                        style: const TextStyle(fontSize: 24),
                      ),
                    )
                  : null
            : const Center(
                child: Icon(Icons.lock, color: Color(0xFF555555), size: 20),
              ),
      ),
    );
  }
}
