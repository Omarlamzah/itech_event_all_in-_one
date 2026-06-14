class Supplier {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final int? materialsCount;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.materialsCount,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'],
        name: json['name'] ?? '',
        contactPerson: json['contact_person'],
        phone: json['phone'],
        email: json['email'],
        address: json['address'],
        materialsCount: json['materials_count'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
      };
}
