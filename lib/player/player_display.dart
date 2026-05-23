import 'package:flutter/material.dart';
import 'player_service.dart';
import 'player_level_display.dart';
import 'player_gold_display.dart';
import 'player_crazy_display.dart';
import 'player_rage_display.dart';

class PlayerDisplay extends StatelessWidget {
  final PlayerService playerService;

  const PlayerDisplay({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerLevelDisplay(playerService: playerService),
          const SizedBox(height: 4),
          PlayerGoldDisplay(playerService: playerService),
          const SizedBox(height: 4),
          PlayerCrazyDisplay(playerService: playerService),
          const SizedBox(height: 4),
          PlayerRageDisplay(playerService: playerService),
        ],
      ),
    );
  }
}
