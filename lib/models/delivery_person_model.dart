
class DeliveryPersonModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType; // moto, bicicleta, carro
  final bool isActive;
  final DateTime createdAt;

  const DeliveryPersonModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.vehicleType = 'moto',
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'vehicleType': vehicleType,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DeliveryPersonModel.fromMap(Map<String, dynamic> map) =>
      DeliveryPersonModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        vehicleType: (map['vehicleType'] as String?) ?? 'moto',
        isActive: map['isActive'] ?? true,
        createdAt: DateTime.parse(
            map['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}
