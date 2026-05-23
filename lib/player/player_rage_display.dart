import 'package:flutter/material.dart';
import 'player_service.dart';
import 'player_hud_pill.dart';

const int _killsPerRageLevel = 5;

class PlayerRageDisplay extends StatelessWidget {
  final PlayerService playerService;

  const PlayerRageDisplay({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerState>(
      valueListenable: playerService.playerNotifier,
      builder: (context, state, _) {
        return HudPill(
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Rage Lv.${state.rageLevel}',
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            HudProgressBar(
              progress: state.rageLevelProgress,
              color: const Color(0xFFFF6B6B),
            ),
            const SizedBox(width: 6),
            Text(
              '${state.rageKills}/$_killsPerRageLevel',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}
