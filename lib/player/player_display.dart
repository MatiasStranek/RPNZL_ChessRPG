// player/player_display.dart
import 'package:flutter/material.dart';
import 'player_service.dart';

class PlayerDisplay extends StatelessWidget {
  final PlayerService playerService;

  const PlayerDisplay({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerState>(
      valueListenable: playerService.playerNotifier,
      builder: (context, state, _) {
        final isMaxLevel = state.expToNextLevel == null;
        final expCurrent = state.expInCurrentLevel;
        final expNeeded = isMaxLevel
            ? 10
            : (state.expToNextLevel! + expCurrent);

        return Padding(
          // Kein SafeArea nötig – wird direkt unter EnergyDisplay gesetzt
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── EXP + Level-Balken ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stern-Icon als Level-Symbol
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00CFFF),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    // Level-Zahl
                    Text(
                      'Lv.${state.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // EXP-Balken
                    _ExpBar(progress: state.levelProgress, width: 60),
                    const SizedBox(width: 6),
                    // x/x EXP
                    Text(
                      isMaxLevel ? 'MAX' : '$expCurrent/$expNeeded',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Gold-Anzeige ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.gold}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Kleiner EXP-Fortschrittsbalken ──────────────────────────────────────────

class _ExpBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double width;

  const _ExpBar({required this.progress, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CFFF)),
        ),
      ),
    );
  }
}
