// inventory/item_model.dart
import 'package:flutter/material.dart';
import 'item_effect.dart';

enum ItemType { drop }

class ItemModel {
  final String id;
  final ItemType type;
  final String name;

  /// Kann ein [IconData] (z.B. Icons.shield) oder ein [String] (z.B. '🧪') sein.
  /// Wenn null, wird ein Fallback-Emoji angezeigt.
  final Object? icon;

  /// Effekt der beim Benutzen angewendet wird.
  final ItemEffect? effect;

  /// Fabrik-Funktion für das nächste Upgrade-Item.
  /// null = maximale Stufe, kann nicht weiter kombiniert werden.
  final ItemModel Function()? upgradesTo;

  /// Upgrade-Stufe des Items (1 = Basis, unbegrenzt nach oben).
  final int level;

  ItemModel({
    required this.id,
    required this.type,
    required this.name,
    this.icon,
    this.effect,
    this.upgradesTo,
    this.level = 1,
  });

  /// Farbe basierend auf dem Level – durchläuft das gesamte Farbspektrum.
  ///
  /// Level 1  → Grün
  /// Level 50 → Gold/Weiß (Transcendent)
  /// Dazwischen: Cyan → Blau → Violett → Rot → Orange → Gold
  /// Farbe basierend auf dem Level.
  /// Level 1 → Gelb, dann durch das Spektrum: Grün → Cyan → Blau → Violett → Rot → Orange → Gold → Weiß
  Color get tierColor {
    const int maxSoftLevel = 50;
    const double startHue = 50.0; // Gelb
    const double totalRotation = 360.0; // einmal ums gesamte Rad

    final double t = ((level - 1) / (maxSoftLevel - 1)).clamp(0.0, 1.0);
    final double rawHue = (startHue + t * totalRotation) % 360;

    // Ab maxSoftLevel: Sättigung sinkt → wirkt weißlicher (Transcendent)
    final double saturation = level >= maxSoftLevel
        ? (1.0 - ((level - maxSoftLevel) / 50).clamp(0.0, 0.7))
        : 1.0;

    return HSVColor.fromAHSV(1.0, rawHue, saturation, 1.0).toColor();
  }

  /// Lesbare Stufen-Bezeichnung für UI-Badges.
  String get tierLabel {
    if (level <= 5) return 'Common';
    if (level <= 10) return 'Uncommon';
    if (level <= 20) return 'Rare';
    if (level <= 35) return 'Epic';
    if (level <= 50) return 'Legendary';
    if (level <= 75) return 'Mythic';
    return 'Transcendent';
  }
}
