import 'package:flutter/material.dart';
import 'player_service.dart';
import 'player_hud_pill.dart';

const int _killsPerCrazyLevel = 5;

class PlayerCrazyDisplay extends StatelessWidget {
  final PlayerService playerService;

  const PlayerCrazyDisplay({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerState>(
      valueListenable: playerService.playerNotifier,
      builder: (context, state, _) {
        return HudPill(
          children: [
            const Text('💨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Crazy Lv.${state.crazyLevel}',
              style: const TextStyle(
                color: Color(0xFF4A9EFF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            HudProgressBar(
              progress: state.crazyLevelProgress,
              color: const Color(0xFF4A9EFF),
            ),
            const SizedBox(width: 6),
            Text(
              '${state.crazyKills}/$_killsPerCrazyLevel',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}
