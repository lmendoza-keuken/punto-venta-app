import '../../domain/entities/client.dart';

class ClientModel {
  final String id;
  final String name;
  final String? document;
  final String? phone;
  final String? email;
  final String? address;

  ClientModel({
    required this.id,
    required this.name,
    this.document,
    this.phone,
    this.email,
    this.address,
  });

  factory ClientModel.fromEntity(Client c) {
    return ClientModel(
      id: c.id,
      name: c.name,
      document: c.document,
      phone: c.phone,
      email: c.email,
      address: c.address,
    );
  }

  Client toEntity() {
    return Client(
      id: id,
      name: name,
      document: document,
      phone: phone,
      email: email,
      address: address,
    );
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      document: json['document'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'document': document,
        'phone': phone,
        'email': email,
        'address': address,
      };
}
