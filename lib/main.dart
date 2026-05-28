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
import 'beat/beat_level_service.dart';
import 'beat/beat_exit_button.dart';
import 'beat/beat_timer/beat_timer_display.dart';
import 'chest/chest_service.dart';
import 'chest/chest_model.dart';
import 'chest/chest_popup.dart';

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

  final beatLevelService = BeatLevelService();
  await beatLevelService.init();

  final chestService = ChestService();
  await chestService.init();

  final effectHandler = ItemEffectHandler(energyService: energyService);

  final board = await BoardLoader.loadMap('map_board_1');
  final game = ChessGame(
    board: board,
    energyService: energyService,
    inventoryService: inventoryService,
    playerService: playerService,
    activeSkillService: activeSkillService,
    skillService: skillService,
    beatLevelService: beatLevelService,
    chestService: chestService,
  );

  final hudVisible = ValueNotifier<bool>(true);

  // ── Beat-Session Notifier ────────────────────────────────────────────────
  final beatSessionActive = ValueNotifier<bool>(false);
  game.onBeatSessionChanged = (active) => beatSessionActive.value = active;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: BeatTimerDisplay(
          controller: game.beatTimerController,
          child: Stack(
            children: [
              // ── Spielfeld ────────────────────────────────────────────────
              GameWidget(game: game),

              // ── HUD oben links ───────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 0, top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListenableBuilder(
                        listenable: game.beatTimerController,
                        builder: (context, _) => AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: SizedBox(
                            height: game.beatTimerController.isActive ? 68 : 0,
                          ),
                        ),
                      ),

                      // ── Normales HUD (Energy + Player) ──────────────────
                      ValueListenableBuilder<bool>(
                        valueListenable: hudVisible,
                        builder: (context, visible, _) => AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: visible
                              ? AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      EnergyDisplay(
                                        energyService: energyService,
                                      ),
                                      const SizedBox(height: 4),
                                      PlayerDisplay(
                                        playerService: playerService,
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Inventar ─────────────────────────────────────────────────
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

              // ── Skill Button ──────────────────────────────────────────────
              SkillButton(
                skillService: skillService,
                activeSkillService: activeSkillService,
                energyService: energyService,
                onSkillActivated: () => game.selectPlayerPiece(),
              ),

              // ── Reward Animationen ────────────────────────────────────────
              const RewardOverlay(),

              // ── Beat Exit Button ──────────────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: beatSessionActive,
                builder: (context, inBeatWorld, _) => inBeatWorld
                    ? BeatExitButton(onExit: () => game.exitBeatWorld())
                    : const SizedBox.shrink(),
              ),

              // ── Oben rechts ───────────────────────────────────────────────
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
                          ListenableBuilder(
                            listenable: game.beatTimerController,
                            builder: (context, _) => AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              child: SizedBox(
                                height: game.beatTimerController.isActive
                                    ? 68
                                    : 0,
                              ),
                            ),
                          ),

                          // ── Toggle Button ────────────────────────────────
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
                                visible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: visible ? 20 : 14,
                                color: visible
                                    ? Colors.black87
                                    : Colors.white54,
                              ),
                            ),
                          ),

                          if (visible) ...[
                            const SizedBox(height: 6),

                            // ── Cheat Button ──────────────────────────────
                            Builder(
                              builder: (context) => GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => CheatMenuDialog(
                                    energyService: energyService,
                                    playerService: playerService,
                                    inventoryService: inventoryService,
                                    skillService: skillService,
                                    beatLevelService: beatLevelService,
                                    chestService: chestService,
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
                                    color: Colors.red.shade700.withOpacity(
                                      0.85,
                                    ),
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
                            ),

                            const SizedBox(height: 6),

                            // ── Zoom Buttons ──────────────────────────────
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

                            const SizedBox(height: 6),

                            // ── Kisten Button ─────────────────────────────
                            Builder(
                              builder: (context) => GestureDetector(
                                onTap: () => ChestPopup.show(
                                  context,
                                  chestService: chestService,
                                ),
                                child: ValueListenableBuilder<List<ChestModel>>(
                                  valueListenable: chestService.chestsNotifier,
                                  builder: (context, chests, _) {
                                    final hasChests = chests.isNotEmpty;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: hasChests
                                                ? const Color(
                                                    0xFF44FF99,
                                                  ).withOpacity(0.18)
                                                : Colors.white.withOpacity(
                                                    0.15,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: hasChests
                                                  ? const Color(
                                                      0xFF44FF99,
                                                    ).withOpacity(0.6)
                                                  : Colors.white24,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.inventory_2_rounded,
                                            color: hasChests
                                                ? const Color(0xFF44FF99)
                                                : Colors.white70,
                                            size: 18,
                                          ),
                                        ),
                                        if (hasChests)
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF44FF99),
                                                shape: chests.length > 9
                                                    ? BoxShape.rectangle
                                                    : BoxShape.circle,
                                                borderRadius: chests.length > 9
                                                    ? BorderRadius.circular(8)
                                                    : null,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  chests.length > 99
                                                      ? '99+'
                                                      : '${chests.length}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1A1A1A),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
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
