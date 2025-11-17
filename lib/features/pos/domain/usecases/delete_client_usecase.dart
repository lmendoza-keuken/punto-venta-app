import '../repositories/client_repository.dart';

class DeleteClientUsecase {
  final ClientRepository repository;
  DeleteClientUsecase(this.repository);

  Future<void> call(String clientId) async {
    await repository.deleteClient(clientId);
  }
}
