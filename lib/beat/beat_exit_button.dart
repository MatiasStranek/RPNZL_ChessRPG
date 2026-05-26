// beat/beat_exit_button.dart
//
// Roter Exit-Button der angezeigt wird solange der Spieler in einer BeatWorld ist.
// Beim Tippen → Bestätigungs-Popup → bei Ja: Callback der zurück auf die Außen-Map teleportiert.

import 'package:flutter/material.dart';

class BeatExitButton extends StatelessWidget {
  final VoidCallback onExit;

  const BeatExitButton({super.key, required this.onExit});

  Future<void> _showConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade800, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──────────────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade700, width: 1.5),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 26,
                ),
              ),

              const SizedBox(height: 16),

              // ── Titel ─────────────────────────────────────────────────
              const Text(
                'Beat World verlassen?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              // ── Beschreibung ──────────────────────────────────────────
              Text(
                'Dein Fortschritt in diesem Beat Level geht verloren.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // ── Buttons ───────────────────────────────────────────────
              Row(
                children: [
                  // Abbrechen
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Verlassen
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.red.shade800.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade500),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Verlassen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      onExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, right: 16),
          child: GestureDetector(
            onTap: () => _showConfirmDialog(context),
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
