import 'dart:async';

import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';

class CustomerDisplayAdCarousel extends StatefulWidget {
  const CustomerDisplayAdCarousel({
    super.key,
    required this.products,
  });

  final List<CustomerDisplayAdProduct> products;

  @override
  State<CustomerDisplayAdCarousel> createState() =>
      _CustomerDisplayAdCarouselState();
}

class _CustomerDisplayAdCarouselState extends State<CustomerDisplayAdCarousel> {
  static const _autoPlay = Duration(seconds: 4);
  static const _anim = Duration(milliseconds: 450);

  late final PageController _controller;
  Timer? _timer;
  late final int _seed;

  @override
  void initState() {
    super.initState();
    _seed = widget.products.isEmpty ? 0 : 1000 * widget.products.length;
    _controller = PageController(initialPage: _seed);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant CustomerDisplayAdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _timer?.cancel();
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (widget.products.length < 2) return;
    _timer = Timer.periodic(_autoPlay, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_controller.page?.round() ?? _seed) + 1;
      _controller.animateToPage(
        next,
        duration: _anim,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos en oferta',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    if (products.length == 1) {
      return _AdProductSlide(product: products.first);
    }

    return PageView.builder(
      controller: _controller,
      itemBuilder: (context, index) {
        final product = products[index % products.length];
        return _AdProductSlide(product: product);
      },
    );
  }
}

class _AdProductSlide extends StatelessWidget {
  const _AdProductSlide({required this.product});

  final CustomerDisplayAdProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? ProductImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      size: 96,
                      color: AppColors.primary,
                    ),
            ),
          ),
          Text(
            product.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (product.isOnSale &&
              product.regularPrice != null &&
              product.regularPrice! > product.unitPrice)
            Text(
              product.regularPrice!.formatToCurrency(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white70,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white70,
              ),
            ),
          Text(
            product.unitPrice.formatToCurrency(),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
          ),
          if (product.isOnSale) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OFERTA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
