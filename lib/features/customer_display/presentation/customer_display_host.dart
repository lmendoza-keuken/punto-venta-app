import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/customer_display/presentation/pages/customer_display_page.dart';

/// Host de UI cliente que recibe payloads JSON vía [applyPayload].
class CustomerDisplayHost extends StatefulWidget {
  const CustomerDisplayHost({super.key});

  @override
  State<CustomerDisplayHost> createState() => CustomerDisplayHostState();
}

class CustomerDisplayHostState extends State<CustomerDisplayHost> {
  CustomerDisplaySnapshot _snapshot = const CustomerDisplaySnapshot.idle();

  void applyPayload(dynamic argument) {
    try {
      final Map<String, dynamic> json;
      if (argument is String) {
        json = jsonDecode(argument) as Map<String, dynamic>;
      } else if (argument is Map) {
        json = Map<String, dynamic>.from(argument);
      } else {
        return;
      }
      if (!mounted) return;
      setState(() => _snapshot = CustomerDisplaySnapshot.fromJson(json));
    } catch (e) {
      debugPrint('CustomerDisplayHost: payload inválido: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerDisplayPage(snapshot: _snapshot);
  }
}
