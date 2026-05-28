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

  Future<void> addChest(ChestModel chest) async {
    final updated = [...chestsNotifier.value, chest];
    chestsNotifier.value = updated;
    await _save(updated);
  }

  /// Markiert eine Kiste als geöffnet – sie bleibt im Inventar.
  Future<void> openChest(String chestId) async {
    final updated = chestsNotifier.value.map((c) {
      return c.id == chestId ? c.copyWith(isOpened: true) : c;
    }).toList();
    chestsNotifier.value = updated;
    await _save(updated);
  }

  /// Entfernt eine Kiste komplett (falls noch gebraucht).
  Future<void> removeChest(String chestId) async {
    final updated = chestsNotifier.value.where((c) => c.id != chestId).toList();
    chestsNotifier.value = updated;
    await _save(updated);
  }

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
