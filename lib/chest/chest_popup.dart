// chest/chest_popup.dart
//
// Scrollbares PopUp das alle gesammelten Kisten des Spielers anzeigt.
// Passend zum dunklen Spielstil mit grünem Beat-Akzent.

import 'package:flutter/material.dart';
import 'chest_model.dart';
import 'chest_service.dart';

class ChestPopup extends StatefulWidget {
  final ChestService chestService;

  const ChestPopup({super.key, required this.chestService});

  /// Zeigt das PopUp und wartet bis es geschlossen wird.
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

  @override
  Widget build(BuildContext context) {
    final chests = widget.chestService.chests;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520),
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
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  // Kisten-Icon mit Glow
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
                              : '${chests.length} Kiste${chests.length == 1 ? '' : 'n'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Schließen-Button
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

            // ── Trennlinie ─────────────────────────────────────────────────
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

            // ── Inhalt ─────────────────────────────────────────────────────
            if (chests.isEmpty)
              _buildEmptyState()
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  shrinkWrap: true,
                  itemCount: chests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // Neueste Kisten oben
                    final chest = chests[chests.length - 1 - index];
                    return _ChestTile(
                      chest: chest,
                      onOpen: () async {
                        await widget.chestService.removeChest(chest.id);
                        // TODO: Kisten-Inhalt verteilen
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Schließe Beat Levels ab\num Kisten zu erhalten!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Einzelne Kisten-Kachel ────────────────────────────────────────────────────

class _ChestTile extends StatelessWidget {
  final ChestModel chest;
  final VoidCallback onOpen;

  const _ChestTile({required this.chest, required this.onOpen});

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF44FF99).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Kisten-Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF44FF99).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF44FF99).withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Color(0xFF44FF99),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chest.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(chest.earnedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Öffnen-Button
          GestureDetector(
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF44FF99).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF44FF99).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Text(
                'Öffnen',
                style: TextStyle(
                  color: Color(0xFF44FF99),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
