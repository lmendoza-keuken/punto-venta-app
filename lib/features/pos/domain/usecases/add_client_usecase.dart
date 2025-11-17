import '../repositories/client_repository.dart';
import '../entities/client.dart';

class AddClientUsecase {
  final ClientRepository repository;
  AddClientUsecase(this.repository);

  Future<void> call(Client client) async {
    await repository.saveClient(client);
  }
}
