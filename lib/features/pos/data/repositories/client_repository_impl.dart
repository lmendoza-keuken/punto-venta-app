import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_local_datasource.dart';
import '../datasources/client_remote_datasource.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource localDataSource;
  final ClientRemoteDataSource remoteDataSource;

  ClientRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Client>> getClients() async {
    try {
      final clients = await remoteDataSource.getClients();
      return clients;
    } catch (e) {
      print('Error al cargar clientes del backend: $e');
      print('Cargando clientes desde almacenamiento local...');
    }
    final clients = await localDataSource.getClients();
    return clients;
  }

  @override
  Future<void> saveClient(Client client) async {
    await localDataSource.saveClient(client);
  }

  @override
  Future<void> deleteClient(String clientId) async {
    await localDataSource.deleteClient(clientId);
  }

  @override
  Future<Client?> getClientById(String clientId) async {
    final client = await localDataSource.getClientById(clientId);
    return client;
  }
}
