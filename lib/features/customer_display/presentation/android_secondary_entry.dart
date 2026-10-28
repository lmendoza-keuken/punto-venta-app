import 'package:flutter/material.dart';
import 'package:presentation_displays/secondary_display.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_host.dart';

final GlobalKey<CustomerDisplayHostState> _androidHostKey =
    GlobalKey<CustomerDisplayHostState>();

/// Arranque de la Presentation Android (invocado desde [secondaryDisplayMain] en main.dart).
void runAndroidSecondaryDisplay() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'presentation',
      onGenerateRoute: (settings) {
        if (settings.name == 'presentation') {
          return MaterialPageRoute(
            builder: (_) => SecondaryDisplay(
              callback: (argument) {
                _androidHostKey.currentState?.applyPayload(argument);
              },
              child: CustomerDisplayHost(key: _androidHostKey),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CustomerDisplayHost(key: _androidHostKey),
        );
      },
    ),
  );
}
