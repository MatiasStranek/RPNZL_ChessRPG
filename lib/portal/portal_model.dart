// portal/portal_model.dart
import 'portal_type.dart';

abstract class PortalModel {
  final int x;
  final int y;
  final PortalType type;

  const PortalModel({required this.x, required this.y, required this.type});
}
