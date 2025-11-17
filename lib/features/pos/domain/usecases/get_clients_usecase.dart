import '../repositories/client_repository.dart';
import '../entities/client.dart';

class GetClientsUsecase {
  final ClientRepository repository;
  GetClientsUsecase(this.repository);

  Future<List<Client>> call() async {
    return await repository.getClients();
  }
}
