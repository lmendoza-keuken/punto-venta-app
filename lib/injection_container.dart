import 'package:get_it/get_it.dart';
import 'package:pos_flutter_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:pos_flutter_app/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:pos_flutter_app/features/pos/data/datasources/client_local_datasource.dart';
import 'package:pos_flutter_app/features/pos/data/datasources/completed_orders_local_datasource.dart';
import 'package:pos_flutter_app/features/pos/data/datasources/printer_socket_datasource.dart';
import 'package:pos_flutter_app/features/pos/data/datasources/product_local_data.datasource.dart';
import 'package:pos_flutter_app/features/pos/data/datasources/saved_orders_local_dasource.dart';
import 'package:pos_flutter_app/features/pos/data/repositories/client_repository_impl.dart';
import 'package:pos_flutter_app/features/pos/data/repositories/completed_orders_repository_impl.dart';
import 'package:pos_flutter_app/features/pos/data/repositories/printer_repository_impl.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/client_repository.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/completed_orders_repository.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/printer_repository.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/product_repository.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/saved_orders_repository.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/add_client_usecase.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/delete_client_usecase.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/get_clients_usecase.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/get_reports_usecase.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/load_ordes_usecase.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/print_ticket_usecase.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/pos/data/repositories/product_repository_impl.dart';
import 'features/pos/data/repositories/saved_orders_repository_impl.dart';
import 'features/pos/domain/usecases/get_products_usecase.dart';
import 'features/pos/domain/usecases/manage_cart_usecase.dart';
import 'features/pos/domain/usecases/save_order_usecase.dart';
import 'features/pos/presentation/bloc/product/product_bloc.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Splash
  sl.registerFactory(() => SplashBloc());

  //! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc(
        loginUsecase: sl(),
        logoutUsecase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => LoginUsecase(sl()));
  sl.registerLazySingleton(() => LogoutUsecase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - POS
  // Bloc
  sl.registerFactory(() => ProductBloc(getProductsUsecase: sl()));
  sl.registerFactory(() => CartBloc(manageCartUsecase: sl()));
  sl.registerFactory(() => UiBloc());
  sl.registerFactory(() => SavedOrdersBloc(
        saveOrderUsecase: sl(),
        loadSavedOrdersUsecase: sl(),
      ));
  sl.registerFactory(() => ReportsBloc(getReportsUsecase: sl()));
  sl.registerFactory(
      () => ClientsBloc(getClients: sl(), addClient: sl(), deleteClient: sl()));
  sl.registerFactory(() => PrinterBloc(printTicketUsecase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetProductsUsecase(sl()));
  sl.registerLazySingleton(() => ManageCartUsecase());
  sl.registerLazySingleton(() => SaveOrderUsecase(sl()));
  sl.registerLazySingleton(() => LoadSavedOrdersUsecase(sl()));
  sl.registerLazySingleton(() => CompleteOrderUsecase(sl()));
  sl.registerLazySingleton(() => GetReportsUsecase(sl()));
  sl.registerLazySingleton(() => GetClientsUsecase(sl()));
  sl.registerLazySingleton(() => AddClientUsecase(sl()));
  sl.registerLazySingleton(() => DeleteClientUsecase(sl()));
  sl.registerLazySingleton(() => PrintTicketUsecase(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<SavedOrdersRepository>(
    () => SavedOrdersRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<CompletedOrdersRepository>(
    () => CompletedOrdersRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ClientRepository>(
    () => ClientRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(printerDatasource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SavedOrdersLocalDataSource>(
    () => SavedOrdersLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<CompletedOrdersLocalDataSource>(
    () => CompletedOrdersLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<ClientLocalDataSource>(
      () => ClientLocalDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<PrinterSocketDatasource>(
    () => PrinterSocketDatasourceImpl(),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // HTTP client
  sl.registerLazySingleton(() => http.Client());
}
