import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/app_update/presentation/widgets/update_available_dialog.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_event.dart';
import 'package:punto_venta_app/features/splash/presentation/bloc/splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _handlingUpdate = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    context.read<SplashBloc>().add(StartSplash());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onUpdateAvailable(
    BuildContext context,
    SplashUpdateAvailable state,
  ) async {
    if (_handlingUpdate) return;
    _handlingUpdate = true;

    final splashBloc = context.read<SplashBloc>();
    final isMandatory = state.release.mandatory;

    // false = Más tarde / dismiss; on success the process exits via installer.
    await showUpdateAvailableDialog(
      context: context,
      release: state.release,
      currentVersion: state.currentVersion,
    );

    if (!mounted) return;

    // Mandatory updates keep the dialog open until install or retry.
    if (!isMandatory) {
      splashBloc.add(ContinueAfterUpdatePrompt());
    }

    _handlingUpdate = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashCompleted) {
          context.go(RoutePaths.login);
        } else if (state is SplashUpdateAvailable) {
          _onUpdateAvailable(context, state);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cartLightBackground,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/logo.svg',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppStrings.appName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
