// portal/portal_types/world_portal.dart
import '../portal_model.dart';
import '../portal_type.dart';

class WorldPortal extends PortalModel {
  final String id;
  final String linkedPortalId;
  final String targetMap;

  const WorldPortal({
    required super.x,
    required super.y,
    required this.id,
    required this.linkedPortalId,
    required this.targetMap,
  }) : super(type: PortalType.world);
}
