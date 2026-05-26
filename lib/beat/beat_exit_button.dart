// beat/beat_exit_button.dart
//
// Roter Exit-Button der angezeigt wird solange der Spieler in einer BeatWorld ist.
// Beim Tippen → Callback der zurück auf die Außen-Map teleportiert.

import 'package:flutter/material.dart';

class BeatExitButton extends StatelessWidget {
  final VoidCallback onExit;

  const BeatExitButton({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, right: 16),
          child: GestureDetector(
            onTap: onExit,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade800.withOpacity(0.90),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade400, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade900.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
