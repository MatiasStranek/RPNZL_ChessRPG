// chest/chest_hud_button.dart
//
// HUD-Button der rechts unten angezeigt wird (über dem BeatExitButton).
// Zeigt einen Badge mit der Anzahl an Kisten.
// Beim Tippen öffnet sich ChestPopup.

import 'package:flutter/material.dart';
import 'chest_popup.dart';
import 'chest_service.dart';

class ChestHudButton extends StatefulWidget {
  final ChestService chestService;

  const ChestHudButton({super.key, required this.chestService});

  @override
  State<ChestHudButton> createState() => _ChestHudButtonState();
}

class _ChestHudButtonState extends State<ChestHudButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.chestService.count;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    widget.chestService.chestsNotifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    widget.chestService.chestsNotifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final newCount = widget.chestService.count;
    if (newCount != _lastCount) {
      _lastCount = newCount;
      setState(() {});
    }
  }

  void _openPopup() {
    ChestPopup.show(context, chestService: widget.chestService);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.chestService.count;
    final hasChests = count > 0;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          // Über dem BeatExitButton (dieser hat bottom: 24),
          // daher hier bottom: 80 damit sie sich nicht überlappen.
          padding: const EdgeInsets.only(bottom: 80, right: 16),
          child: GestureDetector(
            onTap: _openPopup,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(
                scale: hasChests ? _pulse.value : 1.0,
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Haupt-Button ────────────────────────────────────────
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasChests
                          ? const Color(0xFF44FF99).withOpacity(0.18)
                          : Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasChests
                            ? const Color(0xFF44FF99).withOpacity(0.6)
                            : Colors.white24,
                        width: 1.5,
                      ),
                      boxShadow: hasChests
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF44FF99,
                                ).withOpacity(0.25),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: hasChests
                          ? const Color(0xFF44FF99)
                          : Colors.white38,
                      size: 22,
                    ),
                  ),

                  // ── Badge ───────────────────────────────────────────────
                  if (hasChests)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF44FF99),
                          shape: count > 9
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: count > 9
                              ? BorderRadius.circular(9)
                              : null,
                          border: Border.all(
                            color: const Color(0xFF1A1A1A),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
