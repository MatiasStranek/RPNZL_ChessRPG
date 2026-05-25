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
import 'animations/reward_overlay.dart';
import 'skills/skill_service.dart';
import 'skills/skill_button.dart';
import 'skills/active_skill_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final playerService = PlayerService();
  await playerService.init();

  final energyService = EnergyService(playerService: playerService);
  await energyService.init();

  final inventoryService = InventoryService(playerService: playerService);
  await inventoryService.init();

  final skillService = SkillService(playerService: playerService);
  await skillService.init();

  final activeSkillService = ActiveSkillService();

  final effectHandler = ItemEffectHandler(energyService: energyService);

  final board = await BoardLoader.loadMap('map_board_1');
  final game = ChessGame(
    board: board,
    energyService: energyService,
    inventoryService: inventoryService,
    playerService: playerService,
    activeSkillService: activeSkillService,
    skillService: skillService,
  );

  final hudVisible = ValueNotifier<bool>(true);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: game),

            // ── HUD oben links ─────────────────────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: hudVisible,
              builder: (context, visible, child) => AnimatedOpacity(
                opacity: visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !visible,
                  child: SafeArea(
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
                ),
              ),
            ),

            // ── Inventar ───────────────────────────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: hudVisible,
              builder: (context, visible, child) => AnimatedOpacity(
                opacity: visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !visible,
                  child: InventoryDisplay(
                    inventoryService: inventoryService,
                    effectHandler: effectHandler,
                  ),
                ),
              ),
            ),

            // ── Skill Button ───────────────────────────────────────────
            SkillButton(
              skillService: skillService,
              activeSkillService: activeSkillService,
              energyService: energyService,
              onSkillActivated: () => game.selectPlayerPiece(),
            ),

            // ── Reward Animationen ─────────────────────────────────────
            const RewardOverlay(),

            // ── Oben rechts ────────────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: hudVisible,
                    builder: (context, visible, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ── Toggle Button ────────────────────────────
                        GestureDetector(
                          onTap: () => hudVisible.value = !hudVisible.value,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: visible ? 36 : 28,
                            height: visible ? 36 : 28,
                            decoration: BoxDecoration(
                              color: visible
                                  ? Colors.white.withOpacity(0.85)
                                  : Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              visible ? Icons.visibility : Icons.visibility_off,
                              size: visible ? 20 : 14,
                              color: visible ? Colors.black87 : Colors.white54,
                            ),
                          ),
                        ),

                        if (visible) ...[
                          const SizedBox(height: 6),

                          // ── Cheat Button ─────────────────────────
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => CheatMenuDialog(
                                energyService: energyService,
                                playerService: playerService,
                                inventoryService: inventoryService,
                                skillService: skillService,
                                // ── NEU: Spiel zur Startposition teleportieren ──
                                onResetPosition: () =>
                                    game.teleportToSavedPosition(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bug_report,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'CHEAT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // ── Zoom Buttons ─────────────────────────
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ZoomButton(
                                icon: Icons.zoom_in,
                                onTap: () => game.setZoomNear(),
                              ),
                              const SizedBox(width: 4),
                              _ZoomButton(
                                icon: Icons.zoom_out,
                                onTap: () => game.setZoomDefault(),
                              ),
                              const SizedBox(width: 4),
                              _ZoomButton(
                                icon: Icons.paragliding,
                                onTap: () => game.setZoomFar(),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Zoom Button ───────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}
