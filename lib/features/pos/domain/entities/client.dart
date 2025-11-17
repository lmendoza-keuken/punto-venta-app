class Client {
  final String id;
  final String name;
  final String? document; // DNI o CUIT opcional
  final String? phone;
  final String? email;
  final String? address;

  const Client({
    required this.id,
    required this.name,
    this.document,
    this.phone,
    this.email,
    this.address,
  });

  Client copyWith({
    String? id,
    String? name,
    String? document,
    String? phone,
    String? email,
    String? address,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}
