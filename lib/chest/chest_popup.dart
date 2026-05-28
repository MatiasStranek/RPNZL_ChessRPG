import 'package:flutter/material.dart';
import 'chest_model.dart';
import 'chest_service.dart';

class ChestPopup extends StatefulWidget {
  final ChestService chestService;

  const ChestPopup({super.key, required this.chestService});

  static Future<void> show(
    BuildContext context, {
    required ChestService chestService,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChestPopup(chestService: chestService),
    );
  }

  @override
  State<ChestPopup> createState() => _ChestPopupState();
}

class _ChestPopupState extends State<ChestPopup> {
  @override
  void initState() {
    super.initState();
    widget.chestService.chestsNotifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.chestService.chestsNotifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  static const int _maxSlots = 40;

  @override
  Widget build(BuildContext context) {
    final chests = widget.chestService.chests;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF44FF99).withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF44FF99).withOpacity(0.12),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44FF99).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF44FF99).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF44FF99),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meine Kisten',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          chests.isEmpty
                              ? 'Noch keine Kisten'
                              : '${chests.length} / $_maxSlots',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.5),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Trennlinie ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF44FF99).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Grid ────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                child: chests.isEmpty ? _buildEmptyState() : _buildGrid(chests),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<ChestModel> chests) {
    final reversed = chests.reversed.toList();
    final displayCount = _maxSlots < chests.length ? _maxSlots : chests.length;
    final rows = ((displayCount - 1) ~/ 8) + 1;
    final totalSlots = rows * 8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < reversed.length) {
          return _ChestSlot(
            chest: reversed[index],
            onTap: () => _showChestDetail(context, reversed[index]),
          );
        }
        return _EmptySlot();
      },
    );
  }

  void _showChestDetail(BuildContext context, ChestModel chest) {
    showDialog(
      context: context,
      builder: (_) => _ChestDetailDialog(
        chest: chest,
        onOpen: () async {
          Navigator.of(context).pop();
          await widget.chestService.openChest(chest.id);
          // TODO: Kisten-Inhalt verteilen
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => _EmptySlot(),
        ),
        const SizedBox(height: 20),
        Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: Colors.white.withOpacity(0.12),
        ),
        const SizedBox(height: 10),
        Text(
          'Schließe Beat Levels ab\num Kisten zu erhalten!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Gefüllter Slot ───────────────────────────────────────────────────────────

class _ChestSlot extends StatelessWidget {
  final ChestModel chest;
  final VoidCallback onTap;

  const _ChestSlot({required this.chest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpened = chest.isOpened;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isOpened
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFF44FF99).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOpened
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFF44FF99).withOpacity(0.35),
            width: 1,
          ),
          boxShadow: isOpened
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF44FF99).withOpacity(0.08),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Opacity(
            opacity: isOpened ? 0.35 : 1.0,
            child: CustomPaint(
              size: const Size(28, 22),
              painter: _MiniChestPainter(isOpened: isOpened),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Leerer Slot ──────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
    );
  }
}

// ── Mini-Kiste (CustomPainter) ───────────────────────────────────────────────

class _MiniChestPainter extends CustomPainter {
  final bool isOpened;

  const _MiniChestPainter({this.isOpened = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isOpened) {
      // Geöffnete Kiste: Deckel aufgeklappt nach hinten
      // Körper
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.45, w, h * 0.55),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFB340).withOpacity(0.6),
      );
      // Band
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.45, w, h * 0.09),
        Paint()..color = const Color(0xFF8B5E00).withOpacity(0.6),
      );
      // Deckel (aufgeklappt – flach oben)
      final lid = Path()
        ..moveTo(0, h * 0.38)
        ..lineTo(w, h * 0.38)
        ..lineTo(w, h * 0.22)
        ..lineTo(0, h * 0.28)
        ..close();
      canvas.drawPath(
        lid,
        Paint()..color = const Color(0xFFCC8800).withOpacity(0.5),
      );
      // Schloss (offen / hängend)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w / 2 - 3, h * 0.41, 6, 5),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFFFE066).withOpacity(0.5),
      );
    } else {
      // Geschlossene Kiste (original)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, h * 0.38, w - 4, h * 0.62),
          const Radius.circular(3),
        ),
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.38, w, h * 0.62),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFB340),
      );
      final lid = Path()
        ..moveTo(0, h * 0.42)
        ..lineTo(w, h * 0.42)
        ..lineTo(w, h * 0.22)
        ..quadraticBezierTo(w / 2, 0, 0, h * 0.22)
        ..close();
      canvas.drawPath(lid, Paint()..color = const Color(0xFFCC8800));
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.38, w, h * 0.09),
        Paint()..color = const Color(0xFF8B5E00),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w / 2 - 3, h * 0.34, 6, 5),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFFFE066),
      );
    }
  }

  @override
  bool shouldRepaint(_MiniChestPainter old) => old.isOpened != isOpened;
}

// ── Detail-Dialog beim Antippen ──────────────────────────────────────────────

class _ChestDetailDialog extends StatelessWidget {
  final ChestModel chest;
  final VoidCallback onOpen;

  const _ChestDetailDialog({required this.chest, required this.onOpen});

  String _formatDate(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'Vor ${diff.inDays} Tagen';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isOpened = chest.isOpened;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpened
                ? Colors.white.withOpacity(0.15)
                : const Color(0xFFFFD700).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOpened
                  ? Colors.transparent
                  : const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Große Kiste
            Opacity(
              opacity: isOpened ? 0.4 : 1.0,
              child: SizedBox(
                width: 72,
                height: 58,
                child: CustomPaint(
                  painter: _MiniChestPainter(isOpened: isOpened),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              chest.displayName,
              style: TextStyle(
                color: isOpened ? Colors.white.withOpacity(0.5) : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Geöffnet-Badge oder Datum
            if (isOpened)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  'Bereits geöffnet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              )
            else
              Text(
                _formatDate(chest.earnedAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 20),

            // ── Action-Buttons ─────────────────────────────────────────
            _ChestActionButton(
              icon: Icons.analytics_outlined,
              label: 'Analyse',
              color: const Color(0xFF44AAFF),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Analyse-Logik
              },
            ),
            const SizedBox(height: 8),
            _ChestActionButton(
              icon: Icons.lock_open_rounded,
              label: 'Unlock',
              color: const Color(0xFFBB88FF),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Unlock-Logik
              },
            ),
            const SizedBox(height: 8),

            // Open-Button – ausgegraut wenn bereits geöffnet
            _ChestActionButton(
              icon: Icons.card_giftcard_rounded,
              label: 'Open',
              color: const Color(0xFFFFD700),
              disabled: isOpened,
              onTap: isOpened
                  ? () {}
                  : () {
                      Navigator.of(context).pop();
                      onOpen();
                    },
            ),

            const SizedBox(height: 16),

            // Trennlinie
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Abbrechen
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Center(
                  child: Text(
                    'Abbrechen',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action-Button ────────────────────────────────────────────────────────────

class _ChestActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;

  const _ChestActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled ? Colors.white.withOpacity(0.2) : color;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: effectiveColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (disabled)
              Icon(Icons.lock_outline_rounded, size: 15, color: effectiveColor)
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: effectiveColor.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}
