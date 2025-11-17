import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_local_datasource.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource localDataSource;
  ClientRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Client>> getClients() async {
    final models = await localDataSource.getClients();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveClient(Client client) async {
    final model = ClientModel.fromEntity(client);
    await localDataSource.saveClient(model);
  }

  @override
  Future<void> deleteClient(String clientId) async {
    await localDataSource.deleteClient(clientId);
  }

  @override
  Future<Client?> getClientById(String clientId) async {
    final model = await localDataSource.getClientById(clientId);
    return model?.toEntity();
  }
}
