// inventory/inventory_display.dart
import 'package:flutter/material.dart';
import 'inventory_service.dart';
import 'item_effect_handler.dart';
import 'item_model.dart';

class InventoryDisplay extends StatelessWidget {
  final InventoryService inventoryService;
  final ItemEffectHandler effectHandler;

  const InventoryDisplay({
    super.key,
    required this.inventoryService,
    required this.effectHandler,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ValueListenableBuilder<List<ItemModel?>>(
          valueListenable: inventoryService.inventoryNotifier,
          builder: (context, slots, _) {
            // ← Instanz-Zugriff statt statischem Zugriff
            final unlockedSlots = inventoryService.unlockedSlots;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(InventoryService.totalSlots, (i) {
                final unlocked = i < unlockedSlots;
                final item = slots[i];
                return _SlotWidget(
                  index: i,
                  item: item,
                  unlocked: unlocked,
                  inventoryService: inventoryService,
                  effectHandler: effectHandler,
                  onDrop: (fromIndex) =>
                      inventoryService.moveItem(fromIndex, i),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SlotWidget extends StatefulWidget {
  final int index;
  final ItemModel? item;
  final bool unlocked;
  final InventoryService inventoryService;
  final ItemEffectHandler effectHandler;
  final ValueChanged<int> onDrop;

  const _SlotWidget({
    required this.index,
    required this.item,
    required this.unlocked,
    required this.inventoryService,
    required this.effectHandler,
    required this.onDrop,
  });

  @override
  State<_SlotWidget> createState() => _SlotWidgetState();
}

class _SlotWidgetState extends State<_SlotWidget> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showMenu() {
    _removeMenu();
    _overlayEntry = OverlayEntry(
      builder: (_) => _ItemMenuOverlay(
        layerLink: _layerLink,
        item: widget.item!,
        onUse: () {
          _removeMenu();
          final effect = widget.inventoryService.useItem(widget.index);
          if (effect != null) widget.effectHandler.apply(effect);
        },
        onDestroy: () {
          _removeMenu();
          _showDestroyConfirmation();
        },
        onDismiss: _removeMenu,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDestroyConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Item zerstören?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '„${widget.item!.name}" wird unwiderruflich gelöscht.',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.inventoryService.removeItem(widget.index);
            },
            child: const Text(
              'Zerstören',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  Widget _buildIconWithBadge(ItemModel item) {
    final tierColor = item.tierColor;
    final energyValue = item.effect?.restoreEnergy ?? 0;

    Widget iconWidget;
    if (item.icon is IconData) {
      iconWidget = Icon(item.icon! as IconData, size: 22, color: tierColor);
    } else if (item.icon is String) {
      iconWidget = Text(
        item.icon! as String,
        style: TextStyle(
          fontSize: 22,
          shadows: [Shadow(color: tierColor, blurRadius: 8)],
        ),
      );
    } else {
      iconWidget = const Text('⚔️', style: TextStyle(fontSize: 22));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        if (energyValue > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Color(0x99FFD700), blurRadius: 4),
                ],
              ),
              child: Text(
                '+$energyValue',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = widget.item?.tierColor ?? Colors.transparent;

    final slotBorderColor = widget.item != null
        ? tierColor.withOpacity(0.7)
        : widget.unlocked
        ? const Color(0xFF888888)
        : const Color(0xFF444444);

    return CompositedTransformTarget(
      link: _layerLink,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) =>
            widget.unlocked && details.data != widget.index,
        onAcceptWithDetails: (details) => widget.onDrop(details.data),
        builder: (context, candidateData, _) {
          final isHovered = candidateData.isNotEmpty;

          final slot = Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF555555)
                  : widget.unlocked
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFF222222),
              border: Border.all(
                color: isHovered ? Colors.white54 : slotBorderColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: widget.item != null
                  ? [
                      BoxShadow(
                        color: tierColor.withOpacity(0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: widget.unlocked
                ? widget.item != null
                      ? Center(child: _buildIconWithBadge(widget.item!))
                      : null
                : const Center(
                    child: Icon(Icons.lock, color: Color(0xFF555555), size: 20),
                  ),
          );

          if (widget.unlocked && widget.item != null) {
            return GestureDetector(
              onTap: _showMenu,
              child: Draggable<int>(
                data: widget.index,
                onDragStarted: _removeMenu,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.85,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        border: Border.all(color: tierColor, width: 2),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(child: _buildIconWithBadge(widget.item!)),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    border: Border.all(
                      color: const Color(0xFF666666),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: slot,
              ),
            );
          }

          return slot;
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ItemMenuOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final ItemModel item;
  final VoidCallback onUse;
  final VoidCallback onDestroy;
  final VoidCallback onDismiss;

  const _ItemMenuOverlay({
    required this.layerLink,
    required this.item,
    required this.onUse,
    required this.onDestroy,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const double menuWidth = 140;
    const double slotWidth = 56;
    final tierColor = item.tierColor;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset((slotWidth - menuWidth) / 2, -136),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: menuWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tierColor.withOpacity(0.5)),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: tierColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(
                    color: Color(0xFF444444),
                    height: 1,
                    thickness: 1,
                  ),
                  _MenuButton(
                    icon: Icons.play_arrow,
                    label: 'Benutzen',
                    color: Colors.greenAccent,
                    onTap: onUse,
                    isBottom: false,
                  ),
                  const Divider(
                    color: Color(0xFF444444),
                    height: 1,
                    thickness: 1,
                  ),
                  _MenuButton(
                    icon: Icons.delete_forever,
                    label: 'Zerstören',
                    color: Colors.redAccent,
                    onTap: onDestroy,
                    isBottom: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isBottom;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isBottom,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        bottom: isBottom ? const Radius.circular(8) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
