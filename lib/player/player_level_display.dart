import 'package:flutter/material.dart';
import 'player_service.dart';
import 'player_hud_pill.dart';

class PlayerLevelDisplay extends StatelessWidget {
  final PlayerService playerService;

  const PlayerLevelDisplay({super.key, required this.playerService});

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

        return HudPill(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00CFFF), size: 16),
            const SizedBox(width: 4),
            Text(
              'Lv.${state.level}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            HudProgressBar(
              progress: state.levelProgress,
              color: const Color(0xFF00CFFF),
            ),
            const SizedBox(width: 6),
            Text(
              isMaxLevel ? 'MAX' : '$expCurrent/$expNeeded',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}
