// chest/chest_service.dart
//
// Verwaltet gesammelte Kisten des Spielers.
// Jede Kiste hat einen Ursprung (beatWorldId) und einen Zeitstempel.
// Wird via Hive persistent gespeichert.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chest_model.dart';

class ChestService {
  static const String _boxName = 'chests';
  static const String _chestsKey = 'chest_list';

  late Box _box;

  final ValueNotifier<List<ChestModel>> chestsNotifier = ValueNotifier([]);

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _load();
  }

  List<ChestModel> get chests => List.unmodifiable(chestsNotifier.value);

  int get count => chestsNotifier.value.length;

  /// Fügt eine neue Kiste hinzu und speichert sie.
  Future<void> addChest(ChestModel chest) async {
    final updated = [...chestsNotifier.value, chest];
    chestsNotifier.value = updated;
    await _save(updated);
  }

  /// Entfernt eine Kiste anhand ihrer ID (z.B. beim Öffnen).
  Future<void> removeChest(String chestId) async {
    final updated = chestsNotifier.value.where((c) => c.id != chestId).toList();
    chestsNotifier.value = updated;
    await _save(updated);
  }

  // ── Intern ────────────────────────────────────────────────────────────────

  void _load() {
    final raw = _box.get(_chestsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      chestsNotifier.value = list
          .map((e) => ChestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      chestsNotifier.value = [];
    }
  }

  Future<void> _save(List<ChestModel> chests) async {
    await _box.put(
      _chestsKey,
      jsonEncode(chests.map((c) => c.toJson()).toList()),
    );
  }
}
