import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';

class CustomerDisplayPage extends StatelessWidget {
  const CustomerDisplayPage({
    super.key,
    required this.snapshot,
  });

  final CustomerDisplaySnapshot snapshot;

  static final _currency = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBackground,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (snapshot.mode) {
            CustomerDisplayMode.idle => const _IdleView(key: ValueKey('idle')),
            CustomerDisplayMode.cart => _CartView(
                key: const ValueKey('cart'),
                snapshot: snapshot,
                currency: _currency,
              ),
            CustomerDisplayMode.payment => _PaymentView(
                key: const ValueKey('payment'),
                total: snapshot.totalConIva,
                currency: _currency,
              ),
            CustomerDisplayMode.done => _DoneView(
                key: const ValueKey('done'),
                total: snapshot.totalConIva,
                currency: _currency,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: 96, color: AppColors.sidebarAccent),
          SizedBox(height: 24),
          Text(
            'Bienvenido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Su compra aparecerá aquí',
            style: TextStyle(color: AppColors.sidebarIconInactive, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({
    super.key,
    required this.snapshot,
    required this.currency,
  });

  final CustomerDisplaySnapshot snapshot;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Su compra',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: snapshot.items.isEmpty
                ? const Center(
                    child: Text(
                      'Sin artículos',
                      style: TextStyle(
                        color: AppColors.sidebarIconInactive,
                        fontSize: 22,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: snapshot.items.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.sidebarDivider,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = snapshot.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.quantityLabel,
                                    style: const TextStyle(
                                      color: AppColors.sidebarIconInactive,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currency.format(item.lineTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sidebarSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currency.format(snapshot.totalConIva),
                  style: const TextStyle(
                    color: AppColors.sidebarAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
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

class _PaymentView extends StatelessWidget {
  const _PaymentView({
    super.key,
    required this.total,
    required this.currency,
  });

  final double total;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined,
              size: 80, color: AppColors.sidebarAccent),
          const SizedBox(height: 24),
          const Text(
            'Total a pagar',
            style: TextStyle(color: AppColors.sidebarIconInactive, fontSize: 24),
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({
    super.key,
    required this.total,
    required this.currency,
  });

  final double total;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 96, color: AppColors.success),
          const SizedBox(height: 24),
          const Text(
            '¡Gracias por su compra!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(total),
            style: const TextStyle(
              color: AppColors.sidebarAccent,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
