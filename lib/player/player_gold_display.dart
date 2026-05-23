import 'package:flutter/material.dart';
import 'player_service.dart';
import 'player_hud_pill.dart';
import '../animations/rupee_coin_widget.dart';

class PlayerGoldDisplay extends StatelessWidget {
  final PlayerService playerService;

  const PlayerGoldDisplay({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerState>(
      valueListenable: playerService.playerNotifier,
      builder: (context, state, _) {
        return HudPill(
          children: [
            const RupeeCoin(size: 20),
            const SizedBox(width: 6),
            Text(
              '${state.gold}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }
}
