import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_event.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';

class CompanySelectionPage extends StatelessWidget {
  const CompanySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthCompanySelected) {
          // Navegar a pantalla de credenciales
          context.go(
            RoutePaths.credentials,
            extra: {
              'email': state.email,
              'companyId': state.companyId,
              'companyName': state.companyName,
            },
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    'Cargando empresas...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AuthCompanySelectionRequired) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Selecciona tu Empresa'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    context.go(RoutePaths.login);
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                child: Text(
                                  state.email[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.email,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingL),
                      Text(
                        'Selecciona la empresa con la que deseas trabajar:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Expanded(
                        child: state.companies.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.business_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: AppDimensions.paddingM),
                                    Text(
                                      'No tienes empresas vinculadas',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: state.companies.length,
                                itemBuilder: (context, index) {
                                  final company = state.companies[index];
                                  return Card(
                                    margin: const EdgeInsets.only(
                                      bottom: AppDimensions.paddingM,
                                    ),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.business),
                                      ),
                                      title: Text(company['name'] as String),
                                      subtitle: Text('ID: ${company['id']}'),
                                      trailing: const Icon(Icons.arrow_forward_ios),
                                      onTap: () {
                                        context.read<AuthBloc>().add(
                                              CompanySelected(
                                                email: state.email,
                                                companyId: company['id'],
                                              ),
                                            );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
