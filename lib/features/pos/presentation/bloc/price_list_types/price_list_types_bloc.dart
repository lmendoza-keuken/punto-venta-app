import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/price_list_types_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_price_list_types_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/price_list_types/price_list_types_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/price_list_types/price_list_types_state.dart';

class PriceListTypesBloc extends Bloc<PriceListTypesEvent, PriceListTypesState> {
  final FetchPriceListTypesUsecase fetchPriceListTypesUsecase;
  final PriceListTypesRepository repository;

  PriceListTypesBloc({
    required this.fetchPriceListTypesUsecase,
    required this.repository,
  }) : super(PriceListTypesInitial()) {
    on<FetchPriceListTypesEvent>(_onFetchPriceListTypes);
  }

  Future<void> _onFetchPriceListTypes(
      FetchPriceListTypesEvent event, Emitter<PriceListTypesState> emit) async {
    emit(PriceListTypesLoading());
    try {
      final listTypes = await fetchPriceListTypesUsecase();

      emit(PriceListTypesLoaded(listTypes: listTypes));
    } catch (e) {
      emit(PriceListTypesError(e.toString()));
    }
  }

  
}
