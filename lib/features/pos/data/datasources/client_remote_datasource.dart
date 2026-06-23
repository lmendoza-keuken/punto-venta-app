import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../../domain/entities/client.dart';

part 'client_remote_datasource.g.dart';

@RestApi()
abstract class ClientService {
  factory ClientService(Dio dio, {String baseUrl}) = _ClientService;

  @GET('/pdv/')
  Future<List<Client>> getClients(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 10000});
}

abstract class ClientRemoteDataSource {
  Future<List<Client>> getClients();
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  ClientService get _apiService => di.sl<ClientService>();

  ClientRemoteDataSourceImpl();

  @override
  Future<List<Client>> getClients() async {
    try {
      return await _apiService.getClients();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener clientes'));
    }
  }
}
