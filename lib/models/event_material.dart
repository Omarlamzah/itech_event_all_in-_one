import 'material_item.dart';

class EventMaterial {
  final int id;
  final int eventId;
  final int materialId;
  final int quantityNeeded;
  final int quantityAvailable;
  final int quantityUsed;
  final String status; // pending | confirmed | delivered | returned
  final String? notes;
  final MaterialItem? material;

  EventMaterial({
    required this.id,
    required this.eventId,
    required this.materialId,
    required this.quantityNeeded,
    required this.quantityAvailable,
    required this.quantityUsed,
    required this.status,
    this.notes,
    this.material,
  });

  factory EventMaterial.fromJson(Map<String, dynamic> json) => EventMaterial(
        id: json['id'],
        eventId: json['event_id'],
        materialId: json['material_id'],
        quantityNeeded: json['quantity_needed'] ?? 0,
        quantityAvailable: json['quantity_available'] ?? 0,
        quantityUsed: json['quantity_used'] ?? 0,
        status: json['status'] ?? 'pending',
        notes: json['notes'],
        material: json['material'] != null ? MaterialItem.fromJson(json['material']) : null,
      );

  static const statusLabels = {
    'pending': 'En attente',
    'confirmed': 'Confirmé',
    'delivered': 'Livré',
    'returned': 'Retourné',
  };
}
