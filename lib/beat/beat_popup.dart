// beat/beat_popup.dart
import 'package:flutter/material.dart';
import 'beat_level_model.dart';

class BeatPopup extends StatelessWidget {
  final BeatLevelModel level;
  final int playerLevel;
  final VoidCallback onEnter;
  final VoidCallback onCancel;

  const BeatPopup({
    super.key,
    required this.level,
    required this.playerLevel,
    required this.onEnter,
    required this.onCancel,
  });

  static Future<bool> show({
    required BuildContext context,
    required BeatLevelModel level,
    required int playerLevel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BeatPopup(
        level: level,
        playerLevel: playerLevel,
        onEnter: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  bool get _canEnter => playerLevel >= level.requiredLevel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _canEnter
                      ? const Color(0xFF4A9EFF)
                      : Colors.red.shade700,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.music_note,
                color: _canEnter
                    ? const Color(0xFF4A9EFF)
                    : Colors.red.shade400,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            // ── Titel ─────────────────────────────────────────────────────
            const Text(
              'Beat Portal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            // ── Map-ID ────────────────────────────────────────────────────
            Text(
              level.id,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // ── Level-Anforderung ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Benötigt Level ${level.requiredLevel}',
                  style: TextStyle(
                    color: _canEnter ? Colors.white70 : Colors.red.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Abgeschlossen-Badge ───────────────────────────────────────
            if (level.completed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade700),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Bereits abgeschlossen',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // ── Nicht genug Level ─────────────────────────────────────────
            if (!_canEnter)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Dein Level: $playerLevel',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ),

            const SizedBox(height: 20),

            // ── Buttons ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A4A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child: Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _canEnter ? onEnter : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _canEnter
                            ? const Color(0xFF1A3A5A)
                            : const Color(0xFF2A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _canEnter
                              ? const Color(0xFF4A9EFF)
                              : Colors.red.shade900,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _canEnter ? 'Betreten' : 'Zu niedrig',
                          style: TextStyle(
                            color: _canEnter
                                ? const Color(0xFF4A9EFF)
                                : Colors.red.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
