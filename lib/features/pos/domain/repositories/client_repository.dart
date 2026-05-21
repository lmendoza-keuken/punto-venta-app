import '../entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> getClients();
  Future<void> saveClient(Client client);
  Future<void> deleteClient(int clientId);
  Future<Client?> getClientById(String clientId);
}
