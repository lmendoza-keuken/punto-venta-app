import 'package:punto_venta_app/features/pos/data/datasources/settlements_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_canceled_items_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_detail_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_collectors_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_disposed_items_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/settlements_repository.dart';

class SettlementsRepositoryImpl implements SettlementsRepository {
  final SettlementsRemoteDataSource remoteDataSource;

  SettlementsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PendingCollectorsResponseModel>> fetchPendingCollectors(String date) async {
    final models = await remoteDataSource.getPendingCollectors(date: date);
    return models;
  }

  @override
  Future<PendingCollectorsDetailResponseModel> getPendingCollectorDetail(
      String collectorId, String date) async {
    final models = await remoteDataSource.getPendingCollectorDetail(
        collectorId: collectorId, date: date);
    return models;
  }

  @override
  Future<List<PendingCanceledTicketModel>> getPendingCanceledItems(
      String collectorId, String date) async {
    return await remoteDataSource.getPendingCanceledItems(
      collectorId: collectorId,
      date: date,
    );
  }

  @override
  Future<List<PendingDisposedGroupModel>> getPendingDisposedItems(
      String collectorId, String date) async {
    return await remoteDataSource.getPendingDisposedItems(
      collectorId: collectorId,
      date: date,
    );
  }
}
