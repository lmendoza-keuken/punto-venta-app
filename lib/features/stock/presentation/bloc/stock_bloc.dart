import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/add_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/adjust_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/get_all_products_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/get_product_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/get_stock_movements_usecase.dart';
import 'package:punto_venta_app/features/stock/domain/usecases/remove_stock_usecase.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_event.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final GetAllProductsUsecase getAllProductsUsecase;
  final GetProductStockUsecase getProductStockUsecase;
  final AddStockUsecase addStockUsecase;
  final RemoveStockUsecase removeStockUsecase;
  final AdjustStockUsecase adjustStockUsecase;
  final GetStockMovementsUsecase getStockMovementsUsecase;

  String? _currentUserId;
  String? _currentUserName;

  StockBloc({
    required this.getAllProductsUsecase,
    required this.getProductStockUsecase,
    required this.addStockUsecase,
    required this.removeStockUsecase,
    required this.adjustStockUsecase,
    required this.getStockMovementsUsecase,
  }) : super(StockInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddStock>(_onAddStock);
    on<RemoveStock>(_onRemoveStock);
    on<AdjustStock>(_onAdjustStock);
    on<LoadMovements>(_onLoadMovements);
  }

  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      final products = await getAllProductsUsecase();
      
      final stockMap = <int, int>{};
      for (final product in products) {
        final stock = await getProductStockUsecase(product.id);
        stockMap[product.id] = stock;
      }
      
      emit(StockLoaded(products, stockMap));
    } catch (e) {
      emit(StockError('Error al cargar productos: ${e.toString()}'));
    }
  }

  Future<void> _onAddStock(
    AddStock event,
    Emitter<StockState> emit,
  ) async {
    if (_currentUserId == null || _currentUserName == null) {
      emit(const StockError('Usuario no autenticado'));
      return;
    }

    emit(StockLoading());
    try {
      await addStockUsecase(
        productCodigo: event.productCodigo,
        quantity: event.quantity,
        reason: event.reason,
        userId: _currentUserId!,
        userName: _currentUserName!,
      );
      
      final products = await getAllProductsUsecase();
      final stockMap = <int, int>{};
      for (final product in products) {
        final stock = await getProductStockUsecase(product.id);
        stockMap[product.id] = stock;
      }
      
      emit(StockOperationSuccess('Stock agregado exitosamente', products, stockMap));
    } catch (e) {
      emit(StockError('Error al agregar stock: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveStock(
    RemoveStock event,
    Emitter<StockState> emit,
  ) async {
    if (_currentUserId == null || _currentUserName == null) {
      emit(const StockError('Usuario no autenticado'));
      return;
    }

    emit(StockLoading());
    try {
      await removeStockUsecase(
        productCodigo: event.productCodigo,
        quantity: event.quantity,
        reason: event.reason,
        userId: _currentUserId!,
        userName: _currentUserName!,
      );
      
      final products = await getAllProductsUsecase();
      final stockMap = <int, int>{};
      for (final product in products) {
        final stock = await getProductStockUsecase(product.id);
        stockMap[product.id] = stock;
      }
      
      emit(StockOperationSuccess('Stock removido exitosamente', products, stockMap));
    } catch (e) {
      emit(StockError('Error al remover stock: ${e.toString()}'));
    }
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<StockState> emit,
  ) async {
    if (_currentUserId == null || _currentUserName == null) {
      emit(const StockError('Usuario no autenticado'));
      return;
    }

    emit(StockLoading());
    try {
      await adjustStockUsecase(
        productCodigo: event.productCodigo,
        newStock: event.newStock,
        reason: event.reason,
        userId: _currentUserId!,
        userName: _currentUserName!,
      );
      
      final products = await getAllProductsUsecase();
      final stockMap = <int, int>{};
      for (final product in products) {
        final stock = await getProductStockUsecase(product.id);
        stockMap[product.id] = stock;
      }
      
      emit(StockOperationSuccess('Stock ajustado exitosamente', products, stockMap));
    } catch (e) {
      emit(StockError('Error al ajustar stock: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMovements(
    LoadMovements event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      final movements = await getStockMovementsUsecase(
        productCodigo: event.productCodigo,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(StockMovementsLoaded(movements));
    } catch (e) {
      emit(StockError('Error al cargar movimientos: ${e.toString()}'));
    }
  }
}
