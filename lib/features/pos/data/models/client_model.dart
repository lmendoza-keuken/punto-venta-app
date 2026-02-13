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

  // Para datos locales (SharedPreferences)
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

  // Para datos del backend
  factory ClientModel.fromBackendJson(Map<String, dynamic> json) {
    final String document;
    final cuit = json['cuit'] as String? ?? '';
    final dni = json['dni'] as String? ?? '';
    
    if (cuit.isNotEmpty) {
      document = cuit;
    } else if (dni.isNotEmpty) {
      document = dni;
    } else {
      document = '';
    }

    return ClientModel(
      id: json['id'].toString(), 
      name: json['business_name'] as String? ?? '',
      document: document.isNotEmpty ? document : null,
      address: json['address'] as String?,
      phone: null, 
      email: null, 
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
