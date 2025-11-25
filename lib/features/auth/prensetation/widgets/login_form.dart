import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/utils/validators.dart';
import 'package:punto_venta_app/core/widgets/custom_butom.dart';
import 'package:punto_venta_app/core/widgets/custom_text_field.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_event.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
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

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: AppStrings.username,
                controller: _usernameController,
                validator: Validators.validateUsername,
                prefixIcon: const Icon(Icons.person_outline),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              CustomTextField(
                label: AppStrings.password,
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: Validators.validatePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: AppStrings.loginButton,
                  onPressed: _onLogin,
                  isLoading: state is AuthLoading,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Credenciales demo:\nUsuario: admin / Contraseña: admin\nUsuario: user / Contraseña: 1234',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
