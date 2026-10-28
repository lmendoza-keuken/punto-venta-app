import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_host.dart';

/// MaterialApp mínima para la subventana Windows del cliente.
class CustomerDisplayApp extends StatelessWidget {
  const CustomerDisplayApp({
    super.key,
    required this.hostKey,
  });

  final GlobalKey<CustomerDisplayHostState> hostKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pantalla cliente',
      home: CustomerDisplayHost(key: hostKey),
    );
  }
}
