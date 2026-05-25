// portal/portal_types/beat_portal.dart
import '../portal_model.dart';
import '../portal_type.dart';

class BeatPortal extends PortalModel {
  final String id;
  final String
  beatMapName; // z.B. 'beat_map_1' → assets/beat_maps/beat_map_1.json
  final int requiredLevel; // Mindest-Level um beizutreten

  const BeatPortal({
    required super.x,
    required super.y,
    required this.id,
    required this.beatMapName,
    required this.requiredLevel,
  }) : super(type: PortalType.beat);
}
