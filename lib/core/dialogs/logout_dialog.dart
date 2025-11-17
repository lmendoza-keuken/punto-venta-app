import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_flutter_app/app/routes/route_paths.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_event.dart';

showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutRequested());
              context.go(RoutePaths.login);
            },
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );
}
