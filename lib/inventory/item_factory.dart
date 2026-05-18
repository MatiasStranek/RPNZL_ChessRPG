// inventory/item_factory.dart
import 'package:flutter/material.dart';
import 'item_model.dart';
import 'item_effect.dart';
import 'upgrades/energy_upgrades.dart';

class ItemFactory {
  static ItemModel energyDrop() => ItemModel(
    id: 'energy_drop',
    type: ItemType.drop,
    name: 'Energie x1',
    icon: Icons.bolt,
    effect: const ItemEffect(restoreEnergy: 1),
    upgradesTo: energyUpgrade1,
  );

  // Weitere Basis-Items hier ergänzen:
  // static ItemModel shieldDrop() => ItemModel(...)
}
