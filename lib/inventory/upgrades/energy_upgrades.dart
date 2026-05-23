// inventory/upgrades/energy_upgrades.dart
import 'package:flutter/material.dart';
import '../item_model.dart';
import '../item_effect.dart';

/// Energie Upgrade 1 → 3 Energie (2x energy_drop)
ItemModel energyUpgrade1() => ItemModel(
  id: 'energy_upgrade_1',
  type: ItemType.drop,
  name: 'Energie x3',
  category: ItemCategory.energy,
  icon: Icons.bolt,
  effect: const ItemEffect(restoreEnergy: 3),
  level: 2,
  upgradesTo: energyUpgrade2,
);

/// Energie Upgrade 2 → 7 Energie (2x energy_upgrade_1)
ItemModel energyUpgrade2() => ItemModel(
  id: 'energy_upgrade_2',
  type: ItemType.drop,
  name: 'Energie x7',
  category: ItemCategory.energy,
  icon: Icons.bolt,
  effect: const ItemEffect(restoreEnergy: 7),
  level: 3,
  upgradesTo: energyUpgrade3,
);

/// Energie Upgrade 3 → 15 Energie (2x energy_upgrade_2)
ItemModel energyUpgrade3() => ItemModel(
  id: 'energy_upgrade_3',
  type: ItemType.drop,
  name: 'Energie x15',
  category: ItemCategory.energy,
  icon: Icons.bolt,
  effect: const ItemEffect(restoreEnergy: 15),
  level: 4,
  upgradesTo: energyUpgrade4,
);

/// Energie Upgrade 4 → 31 Energie (2x energy_upgrade_3)
ItemModel energyUpgrade4() => ItemModel(
  id: 'energy_upgrade_4',
  type: ItemType.drop,
  name: 'Energie x31',
  category: ItemCategory.energy,
  icon: Icons.bolt,
  effect: const ItemEffect(restoreEnergy: 31),
  level: 5,
  upgradesTo: energyUpgrade5,
);

/// Energie Upgrade 5 → 63 Energie (2x energy_upgrade_4)
ItemModel energyUpgrade5() => ItemModel(
  id: 'energy_upgrade_5',
  type: ItemType.drop,
  name: 'Energie x63',
  category: ItemCategory.energy,
  icon: Icons.bolt,
  effect: const ItemEffect(restoreEnergy: 63),
  level: 6,
  upgradesTo: energyUpgrade6,
);

/// Energie Upgrade 6 → 127 Energie (2x energy_upgrade_5) – maximale Stufe
ItemModel energyUpgrade6() => ItemModel(
  id: 'energy_upgrade_6',
  type: ItemType.drop,
  name: 'Energie x127',
  category: ItemCategory.energy,
  icon: Icons.bolt,
  effect: const ItemEffect(restoreEnergy: 127),
  level: 7,
  upgradesTo: null,
);
