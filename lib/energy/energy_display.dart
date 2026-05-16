// energy/energy_display.dart
import 'package:flutter/material.dart';
import 'energy_service.dart';

class EnergyDisplay extends StatelessWidget {
  final EnergyService energyService;

  const EnergyDisplay({super.key, required this.energyService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: energyService.energyNotifier,
      builder: (context, energy, _) {
        final timeLeft = energyService.timeUntilNextRegen;
        final hours = timeLeft.inHours;
        final minutes = timeLeft.inMinutes % 60;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Energie-Anzeige links
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$energy / ${EnergyService.maxEnergy}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (energy < EnergyService.maxEnergy) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${hours}h ${minutes}m',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Cheat-Button rechts
                GestureDetector(
                  onTap: energyService.fillEnergy,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
