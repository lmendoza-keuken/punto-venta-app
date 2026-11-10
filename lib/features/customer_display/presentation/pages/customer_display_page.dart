import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/core/widgets/scroll_bottom_extension.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/customer_display/presentation/widgets/customer_display_ad_carousel.dart';
import 'package:punto_venta_app/features/customer_display/presentation/widgets/customer_display_last_product.dart';
import 'package:punto_venta_app/features/customer_display/presentation/widgets/customer_display_qr_panel.dart';
import 'package:punto_venta_app/features/customer_display/presentation/widgets/customer_display_qr_status.dart';

class CustomerDisplayPage extends StatelessWidget {
  const CustomerDisplayPage({
    super.key,
    required this.snapshot,
  });

  final CustomerDisplaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (snapshot.mode) {
            CustomerDisplayMode.idle => const _IdleView(key: ValueKey('idle')),
            CustomerDisplayMode.advertising => _AdvertisingView(
                key: const ValueKey('ads'),
                title: snapshot.adTitle,
                message: snapshot.adMessage,
                products: snapshot.adProducts,
              ),
            // Key estable: no remount en cada scan (evita traba al escanear rápido).
            CustomerDisplayMode.cart => _CartView(
                key: const ValueKey('cart'),
                snapshot: snapshot,
              ),
            CustomerDisplayMode.payment => _PaymentView(
                key: const ValueKey('payment'),
                snapshot: snapshot,
              ),
            CustomerDisplayMode.done => _DoneView(
                key: const ValueKey('done'),
                total: snapshot.totalConIva,
              ),
          },
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront, size: 88, color: AppColors.primary),
          const SizedBox(height: AppDimensions.paddingL),
          Text(
            'Bienvenido',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Su compra aparecerá aquí',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvertisingView extends StatelessWidget {
  const _AdvertisingView({
    super.key,
    this.title,
    this.message,
    this.products = const [],
  });

  final String? title;
  final String? message;
  final List<CustomerDisplayAdProduct> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle = (title != null && title!.trim().isNotEmpty)
        ? title!.trim()
        : 'Promociones';
    final resolvedMessage =
        (message != null && message!.trim().isNotEmpty) ? message!.trim() : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingM,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.greenDark,
            AppColors.green,
            AppColors.greenLight,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            resolvedTitle,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (resolvedMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: CustomerDisplayAdCarousel(products: products),
          ),
        ],
      ),
    );
  }
}

class _CartView extends StatefulWidget {
  const _CartView({
    super.key,
    required this.snapshot,
  });

  final CustomerDisplaySnapshot snapshot;

  @override
  State<_CartView> createState() => _CartViewState();
}

class _CartViewState extends State<_CartView> {
  final ScrollController _scrollController = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.snapshot.items.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant _CartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.snapshot.items.length;
    final lastChanged = oldWidget.snapshot.lastProduct?.entryId !=
        widget.snapshot.lastProduct?.entryId;
    if (next != _lastCount || lastChanged) {
      _lastCount = next;
      _scrollController.scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = widget.snapshot;
    final hasHero = snapshot.lastProduct != null;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHero) ...[
            Expanded(
              flex: 6,
              child: CustomerDisplayLastProductPreview(
                product: snapshot.lastProduct!,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingL),
          ],
          Expanded(
            flex: hasHero ? 4 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusL),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          snapshot.totalConIva.formatToCurrency(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Expanded(
                  child: snapshot.items.isEmpty
                      ? Center(
                          child: Text(
                            'Sin artículos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusL,
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 12,
                            ),
                            itemCount: snapshot.items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              return _TicketLine(
                                item: snapshot.items[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila densa tipo ticket (legible a distancia, sin cards).
class _TicketLine extends StatelessWidget {
  const _TicketLine({required this.item});

  final CustomerDisplayLineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              item.quantityLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isOnSale) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6, top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'OFERTA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.lineTotal.formatToCurrency(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({
    super.key,
    required this.snapshot,
  });

  final CustomerDisplaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrLabel = snapshot.qrLabel;
    final hasPayload =
        snapshot.qrPayload != null && snapshot.qrPayload!.trim().isNotEmpty;
    final totalText = snapshot.totalConIva.formatToCurrency();
    final phase = snapshot.qrPhase;

    // Solo cuando CheckoutBloc está en CheckoutProcessing.
    if (snapshot.isProcessing) {
      return _PaymentShell(
        totalText: totalText,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Procesando pago…',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Mismo switch que el confirmation panel (approved / rejected / expired / pending).
    if (qrLabel != null &&
        qrLabel.isNotEmpty &&
        (phase == CustomerDisplayQrPhase.approved ||
            phase == CustomerDisplayQrPhase.rejected ||
            phase == CustomerDisplayQrPhase.expired ||
            (phase == CustomerDisplayQrPhase.pending && !hasPayload))) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total a pagar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        totalText,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingL),
            Expanded(
              flex: 3,
              child: CustomerDisplayQrStatus(
                phase: phase,
                label: qrLabel,
                detail: snapshot.qrDetail,
                totalLabel: totalText,
              ),
            ),
          ],
        ),
      );
    }

    // ready / pending con payload: mostrar QR (como el panel del cajero).
    if (qrLabel != null && qrLabel.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total a pagar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        totalText,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (phase == CustomerDisplayQrPhase.pending) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Confirmando pago…',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingL),
            Expanded(
              flex: 3,
              child: CustomerDisplayQrPanel(
                label: qrLabel,
                payload: snapshot.qrPayload,
              ),
            ),
          ],
        ),
      );
    }

    // Otros medios (efectivo, tarjeta, etc.): total + espera en caja.
    return _PaymentShell(
      totalText: totalText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined,
              size: 80, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Aguarde mientras confirman el pago',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentShell extends StatelessWidget {
  const _PaymentShell({
    required this.totalText,
    required this.child,
  });

  final String totalText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          Text(
            'Total a pagar',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              totalText,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 72,
                height: 1.1,
              ),
            ),
          ),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({
    super.key,
    required this.total,
  });

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 96, color: AppColors.success),
          const SizedBox(height: 24),
          Text(
            '¡Gracias por su compra!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            total.formatToCurrency(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
