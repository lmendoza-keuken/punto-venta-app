import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_local_datasource.dart';
import '../datasources/client_remote_datasource.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientLocalDataSource localDataSource;
  final ClientRemoteDataSource remoteDataSource;

  ClientRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Client>> getClients() async {
    //  Obtener desde el backend

    // try {
    //   final models = await remoteDataSource.getClients();
    //   return models.map((m) => m.toEntity()).toList();
    // } catch (e) {
    //   // Si falla el backend, intentar cargar desde local como fallback
    // print('Error al cargar clientes del backend: $e');
    // print('Cargando clientes desde almacenamiento local...');
    // }
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
