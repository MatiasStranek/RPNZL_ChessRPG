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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final energyService = EnergyService();
  await energyService.init();

  final inventoryService = InventoryService();

  final board = await BoardLoader.loadMap('map_board_1');
  final game = ChessGame(
    board: board,
    energyService: energyService,
    inventoryService: inventoryService,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: game),
            EnergyDisplay(energyService: energyService),
            InventoryDisplay(inventoryService: inventoryService),
          ],
        ),
      ),
    ),
  );
}
