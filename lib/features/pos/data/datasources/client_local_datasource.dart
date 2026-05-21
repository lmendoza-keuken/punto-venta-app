import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/client.dart';

abstract class ClientLocalDataSource {
  Future<List<Client>> getClients();
  Future<void> saveClient(Client client);
  Future<void> deleteClient(int clientId);
  Future<Client?> getClientById(String clientId);
  Future<void> saveClients(List<Client> clients);
}

class ClientLocalDataSourceImpl implements ClientLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String clientsKey = 'POS_CLIENTS';
  ClientLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<Client>> getClients() async {
    final jsonString = sharedPreferences.getString(clientsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => Client.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveClient(Client client) async {
    final clients = await getClients();
    final index = clients.indexWhere((c) => c.id == client.id);
    if (index >= 0) {
      clients[index] = client;
    } else {
      clients.add(client);
    }
    final jsonString = json.encode(clients.map((c) => c.toJson()).toList());
    await sharedPreferences.setString(clientsKey, jsonString);
  }

  @override
  Future<void> saveClients(List<Client> clients) async {
    final jsonString = json.encode(clients.map((c) => c.toJson()).toList());
    await sharedPreferences.setString(clientsKey, jsonString);

  }

  @override
  Future<void> deleteClient(int clientId) async {
    final clients = await getClients();
    clients.removeWhere((c) => c.id == clientId);
    final jsonString = json.encode(clients.map((c) => c.toJson()).toList());
    await sharedPreferences.setString(clientsKey, jsonString);
  }

  @override
  Future<Client?> getClientById(String clientId) async {
    final clients = await getClients();
    try {
      return clients.firstWhere((c) => c.id == clientId);
    } catch (_) {
      return null;
    }
  }
}
