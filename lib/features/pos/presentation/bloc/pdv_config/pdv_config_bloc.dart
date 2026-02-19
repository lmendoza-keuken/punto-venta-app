import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'pdv_config_event.dart';
import 'pdv_config_state.dart';

class PdvConfigBloc extends Bloc<PdvConfigEvent, PdvConfigState> {
  final FetchPdvConfigUsecase fetchPdvConfigUsecase;
  final PdvConfigRepository repository;

  PdvConfigBloc({
    required this.fetchPdvConfigUsecase,
    required this.repository,
  }) : super(PdvConfigInitial()) {
    on<FetchPdvConfigEvent>(_onFetchPdvConfig);
    on<SavePdvConfigEvent>(_onSavePdvConfig);
  }

  Future<void> _onFetchPdvConfig(
      FetchPdvConfigEvent event, Emitter<PdvConfigState> emit) async {
    emit(PdvConfigLoading());
    try {
      final config = await fetchPdvConfigUsecase();
      emit(PdvConfigLoaded(config));
    } catch (e) {
      emit(PdvConfigError(e.toString()));
    }
  }

  Future<void> _onSavePdvConfig(
      SavePdvConfigEvent event, Emitter<PdvConfigState> emit) async {
    try {
      await repository.savePdvConfig(event.config);
      emit(PdvConfigSaved(event.config));
    } catch (e) {
      emit(PdvConfigError('Error al guardar configuración: $e'));
    }
  }
}
