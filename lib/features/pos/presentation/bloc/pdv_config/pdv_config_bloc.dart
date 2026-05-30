import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/core/network/exceptions.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_vat_categories_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'pdv_config_event.dart';
import 'pdv_config_state.dart';

class PdvConfigBloc extends Bloc<PdvConfigEvent, PdvConfigState> {
  final FetchPdvConfigUsecase fetchPdvConfigUsecase;
  final FetchBranchesUsecase fetchBranchesUsecase;
  final GetVatCategoriesUsecase getVatCategoriesUsecase;
  final PdvConfigRepository repository;

  PdvConfigBloc({
    required this.fetchPdvConfigUsecase,
    required this.fetchBranchesUsecase,
    required this.getVatCategoriesUsecase,
    required this.repository,
  }) : super(PdvConfigInitial()) {
    on<FetchPdvConfigEvent>(_onFetchPdvConfig);
    on<FetchBranchesEvent>(_onFetchBranches);
    on<SavePdvConfigEvent>(_onSavePdvConfig);
    on<UpdateOfflineModeEvent>(_onUpdateOfflineMode);
  }

  Future<void> _onFetchPdvConfig(
      FetchPdvConfigEvent event, Emitter<PdvConfigState> emit) async {
    emit(PdvConfigLoading());
    try {
      PdvConfig config;
      try {
        config = await fetchPdvConfigUsecase();
      } on NotFoundException {
        config = const PdvConfig();
      }

      final branches = await fetchBranchesUsecase();
      await getVatCategoriesUsecase();
      emit(PdvConfigLoaded(config, branches: branches));
    } catch (e) {
      emit(PdvConfigError(e.toString()));
    }
  }

  Future<void> _onFetchBranches(
      FetchBranchesEvent event, Emitter<PdvConfigState> emit) async {
    emit(BranchesLoading());
    try {
      final branches = await fetchBranchesUsecase();
      emit(BranchesLoaded(branches));
    } catch (e) {
      emit(PdvConfigError('Error al obtener sucursales: $e'));
    }
  }

  Future<void> _onSavePdvConfig(
      SavePdvConfigEvent event, Emitter<PdvConfigState> emit) async {
    emit(PdvConfigLoading());
    try {
      await repository.savePdvConfig(event.config);
      emit(PdvConfigSaved(event.config));
    } catch (e) {
      emit(PdvConfigError('Error al guardar configuración: $e'));
    }
  }

  Future<void> _onUpdateOfflineMode(
      UpdateOfflineModeEvent event, Emitter<PdvConfigState> emit) async {
    emit(PdvConfigLoading());
    try {
      final updatedConfig = PdvConfig(
        offlineMode: event.offlineMode,
      );

      await repository.updateOfflineMode(updatedConfig);

      emit(OfflineModeUpdated(event.offlineMode));
    } catch (e) {
      emit(PdvConfigError('Error al actualizar modo offline: $e'));
    }
  }
}
