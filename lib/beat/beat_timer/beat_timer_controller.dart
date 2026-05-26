// beat/beat_timer/beat_timer_controller.dart
import 'package:flutter/foundation.dart';

/// Zustand des Beat-Timers – wird vom HUD-Widget beobachtet.
enum BeatTimerState { idle, ticking, pulse, shockwave }

class BeatTimerController extends ChangeNotifier {
  bool _active = false;
  double _interval = 0.0;
  double _elapsed = 0.0;

  /// Aktueller Zustand für die Animation
  BeatTimerState _animState = BeatTimerState.idle;

  /// Wird auf true gesetzt für einen Frame → löst Sekunden-Pulse aus
  bool _secondPulse = false;
  double _lastSecondMark = 0.0;

  /// Wird auf true gesetzt wenn der Counter auf 0 läuft → Shockwave
  bool _shockwaveTriggered = false;

  // ── Getter ────────────────────────────────────────────────────────────────
  bool get isActive => _active;
  double get elapsed => _elapsed;
  double get interval => _interval;
  BeatTimerState get animState => _animState;
  bool get secondPulse => _secondPulse;
  bool get shockwaveTriggered => _shockwaveTriggered;

  /// Fortschritt 0.0–1.0 (0 = voll, 1 = leer)
  double get progress =>
      _active && _interval > 0 ? (_elapsed / _interval).clamp(0.0, 1.0) : 0.0;

  /// Verbleibende Sekunden (aufgerundet)
  int get remainingSeconds => _active && _interval > 0
      ? (_interval - _elapsed).ceil().clamp(0, _interval.ceil())
      : 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  void activate(double intervalSeconds) {
    _interval = intervalSeconds;
    _elapsed = 0.0;
    _lastSecondMark = 0.0;
    _active = true;
    _secondPulse = false;
    _shockwaveTriggered = false;
    _animState = BeatTimerState.ticking;
    notifyListeners();
  }

  void deactivate() {
    _active = false;
    _elapsed = 0.0;
    _lastSecondMark = 0.0;
    _secondPulse = false;
    _shockwaveTriggered = false;
    _animState = BeatTimerState.idle;
    notifyListeners();
  }

  void reset() {
    _elapsed = 0.0;
    _lastSecondMark = 0.0;
    _secondPulse = false;
    _shockwaveTriggered = false;
    if (_active) {
      _animState = BeatTimerState.ticking;
      notifyListeners();
    }
  }

  // ── Wird aus chess_game.dart update() aufgerufen ──────────────────────────
  void tick(double dt) {
    if (!_active) return;

    _elapsed += dt;

    // Sekunden-Pulse: jede volle Sekunde kurz "drummen"
    final currentSecond = _elapsed.floor();
    if (currentSecond > _lastSecondMark.floor()) {
      _lastSecondMark = _elapsed;
      _secondPulse = true;
      _animState = BeatTimerState.pulse;
      notifyListeners();

      // Pulse nach kurzer Zeit zurücksetzen
      Future.delayed(const Duration(milliseconds: 180), () {
        _secondPulse = false;
        if (_active && !_shockwaveTriggered) {
          _animState = BeatTimerState.ticking;
          notifyListeners();
        }
      });
    }
  }

  // ── Wird aus chess_game.dart aufgerufen wenn Timer abläuft ───────────────
  void triggerAutoMove() {
    _elapsed = 0.0;
    _lastSecondMark = 0.0;
    _shockwaveTriggered = true;
    _animState = BeatTimerState.shockwave;
    notifyListeners();

    // Shockwave zurücksetzen nach Animation
    Future.delayed(const Duration(milliseconds: 700), () {
      _shockwaveTriggered = false;
      if (_active) {
        _animState = BeatTimerState.ticking;
        notifyListeners();
      }
    });
  }
}
