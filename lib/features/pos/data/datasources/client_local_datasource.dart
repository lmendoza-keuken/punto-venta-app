import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_model.dart';

abstract class ClientLocalDataSource {
  Future<List<ClientModel>> getClients();
  Future<void> saveClient(ClientModel client);
  Future<void> deleteClient(String clientId);
  Future<ClientModel?> getClientById(String clientId);
}

class ClientLocalDataSourceImpl implements ClientLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String clientsKey = 'POS_CLIENTS';
  ClientLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<ClientModel>> getClients() async {
    final jsonString = sharedPreferences.getString(clientsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveClient(ClientModel client) async {
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
  Future<void> deleteClient(String clientId) async {
    final clients = await getClients();
    clients.removeWhere((c) => c.id == clientId);
    final jsonString = json.encode(clients.map((c) => c.toJson()).toList());
    await sharedPreferences.setString(clientsKey, jsonString);
  }

  @override
  Future<ClientModel?> getClientById(String clientId) async {
    final clients = await getClients();
    try {
      return clients.firstWhere((c) => c.id == clientId);
    } catch (_) {
      return null;
    }
  }
}
