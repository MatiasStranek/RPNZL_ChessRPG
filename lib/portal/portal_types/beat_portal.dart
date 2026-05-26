// portal/portal_types/beat_portal.dart
import '../portal_model.dart';
import '../portal_type.dart';

class BeatPortal extends PortalModel {
  final String id;
  final String beatMapName;
  final int requiredLevel;
  final String spawnMap;
  final int spawnX;
  final int spawnY;

  const BeatPortal({
    required super.x,
    required super.y,
    required this.id,
    required this.beatMapName,
    required this.requiredLevel,
    this.spawnMap = 'beat_map_1',
    this.spawnX = 1,
    this.spawnY = 1,
  }) : super(type: PortalType.beat);
}
