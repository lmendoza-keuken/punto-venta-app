import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_event.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';

class CredentialsPage extends StatefulWidget {
  final String email;
  final int companyId;
  final String companyName;

  const CredentialsPage({
    super.key,
    required this.email,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthenticateUserRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
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
        } else if(state is AuthUnauthenticated) {
          context.go(RoutePaths.login);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
         backgroundColor: AppColors.cartLightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cartLightBackground,
            title: const Text('Iniciar Sesión de Cajero', style: TextStyle(color: AppColors.textSecondary),),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary,),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        child: Card(
                          elevation: 8,
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppDimensions.paddingXL),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    widget.companyName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(
                                      height: AppDimensions.paddingXL),

                                  // Username Field
                                  TextFormField(
                                    controller: _usernameController,
                                    enabled: !isLoading,
                                    decoration: InputDecoration(
                                      labelText: 'Usuario',
                                      prefixIcon:
                                          const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.borderRadiusM),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu usuario';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  const SizedBox(
                                      height: AppDimensions.paddingM),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    enabled: !isLoading,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.borderRadiusM),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu contraseña';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  const SizedBox(
                                      height: AppDimensions.paddingXL),

                                  // Login Button
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          isLoading ? null : _handleLogin,
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Ingresar',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.keukenName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextPrimary
                            ),
                      ),
                      const SizedBox(height: AppDimensions.paddingXS),
                      Text(
                        AppStrings.keukenDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
