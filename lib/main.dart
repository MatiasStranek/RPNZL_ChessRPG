// main.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'board/board_loader.dart';
import 'game/chess_game.dart';
import 'energy/energy_service.dart';
import 'energy/energy_display.dart';
import 'inventory/inventory_service.dart';
import 'inventory/inventory_display.dart';
import 'inventory/item_effect_handler.dart';
import 'player/player_service.dart';
import 'player/player_display.dart';
import 'cheat/cheat_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // PlayerService zuerst – andere Services hängen davon ab
  final playerService = PlayerService();
  await playerService.init();

  final energyService = EnergyService(playerService: playerService);
  await energyService.init();

  final inventoryService = InventoryService(playerService: playerService);
  await inventoryService.init();

  final effectHandler = ItemEffectHandler(energyService: energyService);

  final board = await BoardLoader.loadMap('map_board_1');
  final game = ChessGame(
    board: board,
    energyService: energyService,
    inventoryService: inventoryService,
    playerService: playerService,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: game),

            // ── HUD oben links ─────────────────────────────────────────
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  EnergyDisplay(energyService: energyService),
                  const SizedBox(height: 4),
                  PlayerDisplay(playerService: playerService),
                ],
              ),
            ),

            // ── Inventar ───────────────────────────────────────────────
            InventoryDisplay(
              inventoryService: inventoryService,
              effectHandler: effectHandler,
            ),

            // ── Cheat Menü oben rechts ─────────────────────────────────
            CheatMenuButton(
              energyService: energyService,
              playerService: playerService,
              inventoryService: inventoryService,
            ),
          ],
        ),
      ),
    ),
  );
}
