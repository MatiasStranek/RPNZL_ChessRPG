// inventory/item_effect_handler.dart
import '../energy/energy_service.dart';
import 'item_effect.dart';

class ItemEffectHandler {
  final EnergyService energyService;

  ItemEffectHandler({required this.energyService});

  void apply(ItemEffect effect) {
    if (effect.restoreEnergy > 0) {
      energyService.restoreEnergy(effect.restoreEnergy);
    }

    // Weitere Effekte hier ergänzen:
    // if (effect.heal > 0) healthService.heal(effect.heal);
    // if (effect.addGold > 0) goldService.add(effect.addGold);
  }
}
