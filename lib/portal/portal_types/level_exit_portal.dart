// portal/portal_types/level_exit_portal.dart
import '../portal_model.dart';
import '../portal_type.dart';

class LevelExitPortal extends PortalModel {
  final String id;

  const LevelExitPortal({required super.x, required super.y, required this.id})
    : super(type: PortalType.levelExit);
}
