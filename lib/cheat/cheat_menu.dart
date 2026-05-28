// cheat/cheat_menu.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../energy/energy_service.dart';
import '../player/player_service.dart';
import '../inventory/inventory_service.dart';
import '../skills/skill_service.dart';
import '../beat/beat_level_service.dart';
import '../chest/chest_service.dart';
import '../chest/chest_registry.dart';
import '../chest/chest_model.dart';

class CheatMenuButton extends StatelessWidget {
  final EnergyService energyService;
  final PlayerService playerService;
  final InventoryService inventoryService;
  final SkillService skillService;
  final BeatLevelService beatLevelService;
  final bool enabled;

  const CheatMenuButton({
    super.key,
    required this.energyService,
    required this.playerService,
    required this.inventoryService,
    required this.skillService,
    required this.beatLevelService,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class CheatMenuDialog extends StatelessWidget {
  final EnergyService energyService;
  final PlayerService playerService;
  final InventoryService inventoryService;
  final SkillService skillService;
  final BeatLevelService beatLevelService;
  final ChestService chestService;
  final VoidCallback onResetPosition;

  const CheatMenuDialog({
    super.key,
    required this.energyService,
    required this.playerService,
    required this.inventoryService,
    required this.skillService,
    required this.beatLevelService,
    required this.chestService,
    required this.onResetPosition,
  });

  // ─── Aktionen ─────────────────────────────────────────────────────────────

  Future<void> _deleteAllData(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: '⚠️ Alle Daten löschen?',
      message:
          'Energy, Gold, EXP, Level, Skills, Inventar, Position, '
          'Beat-Fortschritte und Chests werden komplett zurückgesetzt.',
    );
    if (!confirm) return;

    await Hive.box('energy').clear();
    await Hive.box('player').clear();
    await Hive.box<String>('inventory').clear();

    energyService.fillEnergy();
    playerService.resetGold();
    playerService.resetExp();
    playerService.cheatResetSkillLevels();
    playerService.resetPosition();
    inventoryService.clearAll();
    skillService.cheatResetAll();
    await beatLevelService.resetAll();
    await _clearAllChests();

    onResetPosition();

    if (context.mounted) _showSnack(context, '🗑️ Alle Daten gelöscht');
  }

  // ── Energie ───────────────────────────────────────────────────────────────
  void _resetEnergy(BuildContext context) {
    energyService.fillEnergy();
    _showSnack(context, '⚡ Energie aufgefüllt');
  }

  // ── Gold ──────────────────────────────────────────────────────────────────
  void _resetGold(BuildContext context) {
    playerService.resetGold();
    _showSnack(context, '💰 Gold zurückgesetzt');
  }

  void _addGold(BuildContext context) {
    playerService.cheatAddGold();
    _showSnack(context, '💰 +999 Gold');
  }

  // ── Player Level ──────────────────────────────────────────────────────────
  void _resetExp(BuildContext context) {
    playerService.resetExp();
    playerService.cheatResetSkillLevels();
    inventoryService.removeItemsInLockedSlots();
    skillService.cheatResetAll();
    _showSnack(context, '⭐ EXP & Level zurückgesetzt');
  }

  void _addExp(BuildContext context) {
    playerService.cheatAddExp();
    _showSnack(context, '⭐ +50 EXP');
  }

  void _maxPlayerLevel(BuildContext context) {
    playerService.cheatMaxPlayerLevel();
    skillService.checkAndUnlockAll();
    _showSnack(context, '⭐ Player Level MAX (${PlayerService.maxLevel})');
  }

  // ── CrazyLevel ────────────────────────────────────────────────────────────
  void _addCrazyExp(BuildContext context) {
    playerService.cheatAddCrazyExp();
    skillService.checkAndUnlockAll();
    _showSnack(context, '💨 +50 CrazyEXP');
  }

  void _resetCrazyLevel(BuildContext context) {
    playerService.cheatResetCrazyLevel();
    skillService.cheatResetAll();
    _showSnack(context, '💨 CrazyLevel zurückgesetzt');
  }

  void _maxCrazyLevel(BuildContext context) {
    playerService.cheatMaxCrazyLevel();
    skillService.checkAndUnlockAll();
    _showSnack(context, '💨 CrazyLevel MAX (${PlayerService.maxCrazyLevel})');
  }

  // ── RageLevel ─────────────────────────────────────────────────────────────
  void _addRageKill(BuildContext context) {
    playerService.registerAttackSkillKill();
    skillService.checkAndUnlockAll();
    _showSnack(context, '🔥 +1 Rage Kill');
  }

  void _resetRageLevel(BuildContext context) {
    playerService.cheatResetRageLevel();
    skillService.cheatResetAll();
    _showSnack(context, '🔥 RageLevel zurückgesetzt');
  }

  void _maxRageLevel(BuildContext context) {
    playerService.cheatMaxRageLevel();
    skillService.checkAndUnlockAll();
    _showSnack(context, '🔥 RageLevel MAX (${PlayerService.maxRageLevel})');
  }

  // ── Inventar ──────────────────────────────────────────────────────────────
  void _resetInventory(BuildContext context) {
    inventoryService.clearAll();
    _showSnack(context, '🎒 Inventar geleert');
  }

  // ── Beat Portal ───────────────────────────────────────────────────────────
  Future<void> _resetBeatProgress(BuildContext context) async {
    await beatLevelService.resetAll();
    if (context.mounted)
      _showSnack(context, '🎵 Beat-Fortschritt zurückgesetzt');
  }

  // ── Chests ────────────────────────────────────────────────────────────────

  /// Fügt alle Chests aus der Registry hinzu, die noch nicht im Inventar sind.
  Future<void> _addAllMissingChests(BuildContext context) async {
    final existing = chestService.chests;
    final existingIds = existing.map((c) => c.id).toSet();

    final toAdd = ChestRegistry.allChests
        .where((def) => !existingIds.contains(def.id))
        .toList();

    if (toAdd.isEmpty) {
      if (context.mounted)
        _showSnack(context, '📦 Alle Chests bereits im Inventar');
      return;
    }

    for (final def in toAdd) {
      await chestService.addChest(
        ChestModel(
          id: def.id,
          fromBeatWorldId: def.fromBeatWorldId,
          displayName: def.displayName,
          earnedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    if (context.mounted)
      _showSnack(context, '📦 ${toAdd.length} Chest(s) hinzugefügt');
  }

  /// Leert das gesamte Chest-Inventar.
  Future<void> _clearAllChests() async {
    final ids = chestService.chests.map((c) => c.id).toList();
    for (final id in ids) {
      await chestService.removeChest(id);
    }
  }

  Future<void> _clearChests(BuildContext context) async {
    await _clearAllChests();
    if (context.mounted) _showSnack(context, '📦 Chest-Inventar geleert');
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Titel ──────────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.red, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Cheat Menü',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),

              // ── Scrollbarer Inhalt ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Alles löschen ──────────────────────────────────────
                      _CheatButton(
                        label: '🗑️  ALLE DATEN LÖSCHEN',
                        subtitle:
                            'Energy · Gold · EXP · Skills · Inventar · Position · Beat · Chests',
                        color: Colors.red.shade800,
                        onTap: () => _deleteAllData(context),
                      ),

                      // ── Energie ────────────────────────────────────────────
                      const _SectionDivider(label: '⚡ ENERGIE'),
                      _CheatButton(
                        label: 'Energie auffüllen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _resetEnergy(context),
                      ),

                      // ── Gold ───────────────────────────────────────────────
                      const _SectionDivider(label: '💰 GOLD'),
                      _CheatButtonRow(
                        children: [
                          _CheatButton(
                            label: '+999 Gold',
                            color: const Color(0xFF2A2A4A),
                            onTap: () => _addGold(context),
                          ),
                          _CheatButton(
                            label: 'Reset',
                            color: const Color(0xFF3A1A1A),
                            borderColor: Colors.red.shade900,
                            onTap: () => _resetGold(context),
                          ),
                        ],
                      ),

                      // ── Player Level ───────────────────────────────────────
                      const _SectionDivider(label: '⭐ PLAYER LEVEL'),
                      _CheatButtonRow(
                        children: [
                          _CheatButton(
                            label: '+50 EXP',
                            color: const Color(0xFF2A2A4A),
                            onTap: () => _addExp(context),
                          ),
                          _CheatButton(
                            label: 'MAX',
                            subtitle: 'Lv.${PlayerService.maxLevel}',
                            color: const Color(0xFF1A3A1A),
                            borderColor: Colors.green.shade700,
                            onTap: () => _maxPlayerLevel(context),
                          ),
                          _CheatButton(
                            label: 'Reset',
                            color: const Color(0xFF3A1A1A),
                            borderColor: Colors.red.shade900,
                            onTap: () => _resetExp(context),
                          ),
                        ],
                      ),

                      // ── CrazyLevel ─────────────────────────────────────────
                      const _SectionDivider(label: '💨 CRAZY LEVEL'),
                      _CheatButtonRow(
                        children: [
                          _CheatButton(
                            label: '+50 CrazyEXP',
                            color: const Color(0xFF2A2A4A),
                            onTap: () => _addCrazyExp(context),
                          ),
                          _CheatButton(
                            label: 'MAX',
                            subtitle: 'Lv.${PlayerService.maxCrazyLevel}',
                            color: const Color(0xFF1A2A3A),
                            borderColor: const Color(0xFF4A9EFF),
                            onTap: () => _maxCrazyLevel(context),
                          ),
                          _CheatButton(
                            label: 'Reset',
                            color: const Color(0xFF3A1A1A),
                            borderColor: Colors.red.shade900,
                            onTap: () => _resetCrazyLevel(context),
                          ),
                        ],
                      ),

                      // ── RageLevel ──────────────────────────────────────────
                      const _SectionDivider(label: '🔥 RAGE LEVEL'),
                      _CheatButtonRow(
                        children: [
                          _CheatButton(
                            label: '+1 Rage Kill',
                            color: const Color(0xFF2A2A4A),
                            onTap: () => _addRageKill(context),
                          ),
                          _CheatButton(
                            label: 'MAX',
                            subtitle: 'Lv.${PlayerService.maxRageLevel}',
                            color: const Color(0xFF3A1A0A),
                            borderColor: Colors.orange.shade700,
                            onTap: () => _maxRageLevel(context),
                          ),
                          _CheatButton(
                            label: 'Reset',
                            color: const Color(0xFF3A1A1A),
                            borderColor: Colors.red.shade900,
                            onTap: () => _resetRageLevel(context),
                          ),
                        ],
                      ),

                      // ── Inventar ───────────────────────────────────────────
                      const _SectionDivider(label: '🎒 INVENTAR'),
                      _CheatButton(
                        label: 'Inventar leeren',
                        subtitle: 'Alle Items aus allen Slots entfernen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _resetInventory(context),
                      ),

                      // ── Beat Portal ────────────────────────────────────────
                      const _SectionDivider(label: '🎵 BEAT PORTAL'),
                      _CheatButton(
                        label: 'Fortschritt zurücksetzen',
                        subtitle:
                            'Alle abgeschlossenen Beat-Level zurücksetzen',
                        color: const Color(0xFF2A1800),
                        borderColor: const Color(0xFFFFAA00),
                        onTap: () => _resetBeatProgress(context),
                      ),

                      // ── Chests ─────────────────────────────────────────────
                      const _SectionDivider(label: '📦 CHESTS'),
                      _CheatButtonRow(
                        children: [
                          _CheatButton(
                            label: 'Alle hinzufügen',
                            subtitle: 'Nur fehlende Chests',
                            color: const Color(0xFF1A2A1A),
                            borderColor: Colors.green.shade700,
                            onTap: () => _addAllMissingChests(context),
                          ),
                          _CheatButton(
                            label: 'Alle löschen',
                            subtitle: 'Chest-Inventar leeren',
                            color: const Color(0xFF3A1A1A),
                            borderColor: Colors.red.shade900,
                            onTap: () => _clearChests(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hilfsmethoden ────────────────────────────────────────────────────────

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2A2A4A),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _CheatButtonRow extends StatelessWidget {
  final List<_CheatButton> children;
  const _CheatButtonRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children.indexed
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: e.$1 < children.length - 1 ? 6 : 0,
                ),
                child: e.$2,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CheatButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Color color;
  final Color? borderColor;
  final VoidCallback onTap;

  const _CheatButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Colors.white12, height: 1)),
        ],
      ),
    );
  }
}
