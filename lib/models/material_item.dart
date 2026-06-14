import 'supplier.dart';

class MaterialItem {
  final int id;
  final String name;
  final String? photo;
  final String category; // equipment | document | consumable | kit
  final String? description;
  final int totalQuantity;
  final int? supplierId;
  final Supplier? supplier;

  MaterialItem({
    required this.id,
    required this.name,
    this.photo,
    required this.category,
    this.description,
    required this.totalQuantity,
    this.supplierId,
    this.supplier,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
        id: json['id'],
        name: json['name'] ?? '',
        photo: json['photo'],
        category: json['category'] ?? 'equipment',
        description: json['description'],
        totalQuantity: json['total_quantity'] ?? 0,
        supplierId: json['supplier_id'],
        supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'total_quantity': totalQuantity,
        'supplier_id': supplierId,
      };

  static const categoryLabels = {
    'equipment': 'Équipement',
    'document': 'Document',
    'consumable': 'Consommable',
    'kit': 'Kit',
  };
}
