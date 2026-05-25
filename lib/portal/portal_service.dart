// portal/portal_service.dart
import 'portal_model.dart';
import 'portal_types/world_portal.dart';
import 'portal_types/beat_portal.dart';

class PortalService {
  final List<PortalModel> portals;

  PortalService({required this.portals});

  PortalModel? portalAt(int x, int y) =>
      portals.where((p) => p.x == x && p.y == y).firstOrNull;

  WorldPortal? worldPortalAt(int x, int y) {
    final portal = portalAt(x, y);
    if (portal is WorldPortal) return portal;
    return null;
  }

  BeatPortal? beatPortalAt(int x, int y) {
    final portal = portalAt(x, y);
    if (portal is BeatPortal) return portal;
    return null;
  }

  /// Gibt das WorldPortal mit dieser ID zurück
  WorldPortal? portalById(String id) {
    return portals
        .whereType<WorldPortal>()
        .where((p) => p.id == id)
        .firstOrNull;
  }
}
