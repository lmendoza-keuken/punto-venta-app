import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/features/pos/data/models/ticket_config_model.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'ticket_config_remote_datasource.g.dart';

@RestApi()
abstract class TicketConfigService {
  factory TicketConfigService(Dio dio, {String baseUrl}) = _TicketConfigService;

  @GET('/ticket_config/')
  Future<TicketConfigModel> getTicketConfig();

  @PUT('/ticket_config/')
  Future<TicketConfigModel> updateTicketConfig(@Body() TicketConfigModel config);
}

abstract class TicketConfigRemoteDataSource {
  Future<TicketConfigModel> fetchAppConfig();
  Future<TicketConfigModel> updateAppConfig(TicketConfigModel config);
}

class TicketConfigRemoteDataSourceImpl implements TicketConfigRemoteDataSource {
  TicketConfigService get _apiService => di.sl<TicketConfigService>();
  final Duration timeout;

  TicketConfigRemoteDataSourceImpl({
    this.timeout = const Duration(seconds: 10),
  });

  @override
  Future<TicketConfigModel> fetchAppConfig() async {
    try {
      return await _apiService.getTicketConfig();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener configuración'));
    }
  }

  @override
  Future<TicketConfigModel> updateAppConfig(TicketConfigModel config) async {
    try {
      return await _apiService.updateTicketConfig(config);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al actualizar configuración'));
    }
  }
}
