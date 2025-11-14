import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_flutter_app/app/routes/route_paths.dart';
import 'package:pos_flutter_app/core/constants/app_dimensions.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:pos_flutter_app/features/auth/prensetation/widgets/login_form.dart';
import 'package:pos_flutter_app/features/auth/prensetation/widgets/login_header.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RoutePaths.pos);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: const Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LoginHeader(),
                        LoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
