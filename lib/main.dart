import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'app/app.dart';
import 'injection_container.dart' as di;
import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'features/pos/presentation/bloc/product/product_bloc.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SplashBloc>()),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<ProductBloc>()),
        BlocProvider(create: (_) => di.sl<CartBloc>()),
        BlocProvider(create: (_) => di.sl<UiBloc>()),
        BlocProvider(create: (_) => di.sl<SavedOrdersBloc>()),
        BlocProvider(create: (_) => di.sl<ReportsBloc>()),
        BlocProvider(create: (_) => di.sl<ClientsBloc>()),
      ],
      child: const PosApp(),
    );
  }
}
