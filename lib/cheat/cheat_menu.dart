// cheat/cheat_menu.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../energy/energy_service.dart';
import '../player/player_service.dart';
import '../inventory/inventory_service.dart';

class CheatMenuButton extends StatelessWidget {
  final EnergyService energyService;
  final PlayerService playerService;
  final InventoryService inventoryService;
  final bool enabled;

  const CheatMenuButton({
    super.key,
    required this.energyService,
    required this.playerService,
    required this.inventoryService,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CheatMenuDialog extends StatelessWidget {
  final EnergyService energyService;
  final PlayerService playerService;
  final InventoryService inventoryService;

  const CheatMenuDialog({
    super.key,
    required this.energyService,
    required this.playerService,
    required this.inventoryService,
  });

  Future<void> _deleteAllData(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: '⚠️ Alle Daten löschen?',
      message:
          'Energy, Gold, EXP, Level und Inventar werden komplett zurückgesetzt. Das kann nicht rückgängig gemacht werden!',
    );
    if (!confirm) return;

    await Hive.box('energy').clear();
    await Hive.box('player').clear();
    await Hive.box<String>('inventory').clear();

    energyService.fillEnergy();
    playerService.resetGold();
    playerService.resetExp();
    inventoryService.clearAll();

    if (context.mounted) {
      _showSnack(context, '🗑️ Alle Daten gelöscht');
    }
  }

  void _resetEnergy(BuildContext context) {
    energyService.fillEnergy();
    _showSnack(context, '⚡ Energie aufgefüllt');
  }

  void _resetGold(BuildContext context) {
    playerService.resetGold();
    _showSnack(context, '💰 Gold zurückgesetzt');
  }

  void _addGold(BuildContext context) {
    playerService.cheatAddGold();
    _showSnack(context, '💰 +999 Gold');
  }

  void _resetExp(BuildContext context) {
    playerService.resetExp();
    inventoryService.removeItemsInLockedSlots();
    _showSnack(context, '⭐ EXP & Level zurückgesetzt');
  }

  void _addExp(BuildContext context) {
    playerService.cheatAddExp();
    _showSnack(context, '⭐ +50 EXP');
  }

  void _resetInventory(BuildContext context) {
    inventoryService.clearAll();
    _showSnack(context, '🎒 Inventar geleert');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Titel fix, scrollt nicht mit ──
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

              // ── Scrollbarer Inhalt ──
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CheatButton(
                        label: '🗑️  ALLE DATEN LÖSCHEN',
                        subtitle: 'Energy · Gold · EXP · Inventar',
                        color: Colors.red.shade800,
                        onTap: () => _deleteAllData(context),
                      ),
                      const _Divider(label: '⚡ ENERGIE'),
                      _CheatButton(
                        label: 'Energie auffüllen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _resetEnergy(context),
                      ),
                      const _Divider(label: '💰 GOLD'),
                      _CheatButton(
                        label: 'Gold auf 0 setzen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _resetGold(context),
                      ),
                      const SizedBox(height: 8),
                      _CheatButton(
                        label: '+999 Gold hinzufügen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _addGold(context),
                      ),
                      const _Divider(label: '⭐ ERFAHRUNG'),
                      _CheatButton(
                        label: 'EXP & Level zurücksetzen',
                        subtitle: 'Entfernt auch Items in gesperrten Slots',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _resetExp(context),
                      ),
                      const SizedBox(height: 8),
                      _CheatButton(
                        label: '+50 EXP hinzufügen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _addExp(context),
                      ),
                      const _Divider(label: '🎒 INVENTAR'),
                      _CheatButton(
                        label: 'Inventar leeren',
                        subtitle: 'Alle Items aus allen Slots entfernen',
                        color: const Color(0xFF2A2A4A),
                        onTap: () => _resetInventory(context),
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

class _CheatButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CheatButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

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
