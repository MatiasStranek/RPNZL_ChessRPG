// inventory/item_model.dart
enum ItemType { drop }

class ItemModel {
  final String id;
  final ItemType type;
  final String name;

  ItemModel({required this.id, required this.type, required this.name});
}
