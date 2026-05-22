// inventory/inventory_display.dart
import 'package:flutter/material.dart';
import 'inventory_service.dart';
import 'item_effect_handler.dart';
import 'item_model.dart';

// ─── Konfiguration ────────────────────────────────────────────────────────────
// Wie viele Slots gehören zur Hotbar (untere Reihe, immer sichtbar)?
const int _hotbarSlots = 8;
// Slotgröße
const double _slotSize = 48;
const double _slotMargin = 4;

// ─────────────────────────────────────────────────────────────────────────────

class InventoryDisplay extends StatefulWidget {
  final InventoryService inventoryService;
  final ItemEffectHandler effectHandler;

  const InventoryDisplay({
    super.key,
    required this.inventoryService,
    required this.effectHandler,
  });

  @override
  State<InventoryDisplay> createState() => _InventoryDisplayState();
}

class _InventoryDisplayState extends State<InventoryDisplay>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  // Anzahl der Erweiterungs-Slots (Slots oberhalb der Hotbar)
  int get _extendedSlots => InventoryService.totalSlots - _hotbarSlots;

  // Höhe des ausfahrbaren Panels inkl. Padding
  // NEU
  static const int _extendedRows = 3;
  static const int _extendedCols = 8;

  double get _panelHeight => _extendedSlots > 0
      ? (_extendedRows * (_slotSize + _slotMargin * 2) + 20)
      : 0;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ValueListenableBuilder<List<ItemModel?>>(
          valueListenable: widget.inventoryService.inventoryNotifier,
          builder: (context, slots, _) {
            final unlockedSlots = widget.inventoryService.unlockedSlots;

            // ── Erweiterungs-Slots (Indizes 4–7) ──
            // NEU – Extended-Slot-Widgets als 3 Reihen à 8 Slots
            final extendedRows = List.generate(_extendedRows, (row) {
              final rowSlots = List.generate(_extendedCols, (col) {
                final index = _hotbarSlots + row * _extendedCols + col;
                if (index >= InventoryService.totalSlots)
                  return const SizedBox.shrink();
                return _SlotWidget(
                  index: index,
                  item: slots[index],
                  unlocked: index < unlockedSlots,
                  inventoryService: widget.inventoryService,
                  effectHandler: widget.effectHandler,
                  onDrop: (from) =>
                      widget.inventoryService.moveItem(from, index),
                );
              });
              return Row(mainAxisSize: MainAxisSize.min, children: rowSlots);
            });

            // ── Hotbar-Slots (Indizes 0–3) ──
            final hotbarSlotWidgets = List.generate(_hotbarSlots, (i) {
              return _SlotWidget(
                index: i,
                item: slots[i],
                unlocked: i < unlockedSlots,
                inventoryService: widget.inventoryService,
                effectHandler: widget.effectHandler,
                onDrop: (from) => widget.inventoryService.moveItem(from, i),
              );
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Ausfahrbares Erweiterungs-Panel ────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  height: _expanded ? _panelHeight : 0,
                  child: SingleChildScrollView(
                    // verhindert Flutter-Layout-Fehler während Animation
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        border: Border(
                          top: BorderSide(color: Color(0xFF555555), width: 1.5),
                          left: BorderSide(
                            color: Color(0xFF555555),
                            width: 1.5,
                          ),
                          right: BorderSide(
                            color: Color(0xFF555555),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: extendedRows,
                      ),
                    ),
                  ),
                ),

                // ── Hotbar + Toggle-Button (bleibt immer sichtbar) ─────────
                IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hotbar-Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.only(
                            // Ecken nur abrunden wenn Panel zu ist
                            topLeft: _expanded
                                ? Radius.zero
                                : const Radius.circular(10),
                            topRight: _expanded
                                ? Radius.zero
                                : const Radius.circular(10),
                            bottomLeft: const Radius.circular(10),
                            bottomRight: const Radius.circular(10),
                          ),
                          border: Border.all(
                            color: const Color(0xFF555555),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: hotbarSlotWidgets,
                        ),
                      ),

                      const SizedBox(width: 6),

                      // ── Toggle-Button ────────────────────────────────────
                      GestureDetector(
                        onTap: _toggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          width: 28,
                          decoration: BoxDecoration(
                            color: _expanded
                                ? const Color(0xFF444444)
                                : const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _expanded
                                  ? const Color(0xFF888888)
                                  : const Color(0xFF555555),
                              width: 1.5,
                            ),
                            boxShadow: _expanded
                                ? [
                                    const BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: AnimatedRotation(
                              turns: _expanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeInOutCubic,
                              child: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Color(0xFFAAAAAA),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── _SlotWidget (unverändert, nur ausgelagert) ───────────────────────────────

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
            margin: EdgeInsets.symmetric(horizontal: _slotMargin),
            width: _slotSize,
            height: _slotSize,
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
                      width: _slotSize,
                      height: _slotSize,
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
                  margin: EdgeInsets.symmetric(horizontal: _slotMargin),
                  width: _slotSize,
                  height: _slotSize,
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

// ─── _ItemMenuOverlay (unverändert) ──────────────────────────────────────────

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
