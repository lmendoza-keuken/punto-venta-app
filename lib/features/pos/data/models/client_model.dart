import '../../domain/entities/client.dart';

class ClientModel {
  static Map<String, dynamic> toJson(Client client) {
    return client.toJson();
  }

  static Client fromJson(Map<String, dynamic> json) {
    return Client.fromJson(json);
  }

  static Client fromBackendJson(Map<String, dynamic> json) {
    return Client.fromBackendJson(json);
  }
}
