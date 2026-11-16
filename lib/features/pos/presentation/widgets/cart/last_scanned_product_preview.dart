import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';

class LastScannedProductPreview extends StatefulWidget {
  final CartLogEntry entry;
  final bool dense;

  const LastScannedProductPreview({
    super.key,
    required this.entry,
    this.dense = false,
  });

  @override
  State<LastScannedProductPreview> createState() =>
      _LastScannedProductPreviewState();
}

class _LastScannedProductPreviewState extends State<LastScannedProductPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    // Pulso borde: engrose + blur (2 picos cortos).
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1.2),
    ]).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));
    _triggerFlash();
  }

  @override
  void didUpdateWidget(covariant LastScannedProductPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.timestamp != widget.entry.timestamp ||
        oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.item.quantity != widget.entry.item.quantity) {
      _triggerFlash();
    }
  }

  void _triggerFlash() {
    _blink
      ..stop()
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isAdd = entry.type == CartActionType.add;
    final actionColor = isAdd ? AppColors.success : AppColors.error;
    final actionLabel = isAdd ? 'Agregado' : 'Eliminado';
    final actionIcon =
        isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final sign = isAdd ? '+' : '-';

    final product = entry.item.product;
    final isWeighted = entry.item.isWeighted ?? false;
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    final basePrice = product.price ?? 0.0;
    final vatRate = product.vat / 100.0;
    final internalTax = product.internalTax;
    final fractional = product.fractional ?? 1;

    double unitPrice = basePrice * (1 + vatRate);
    if (internalTax > 0) {
      unitPrice += internalTax * fractional;
    }

    final lineTotal = isWeighted
        ? unitPrice * (entry.item.weightKg ?? 0.0)
        : unitPrice * entry.item.quantity;

    final quantityLabel = isWeighted
        ? '$sign${entry.item.weightKg ?? 0} kg'
        : '$sign${entry.item.quantity}';

    final priceLine =
        '${unitPrice.formatToCurrency()}${isWeighted ? ' / kg' : ''}  ·  ${lineTotal.formatToCurrency()}';

    if (widget.dense) {
      return _DensePreview(
        productName: product.name,
        productId: product.id,
        hasImage: hasImage,
        imageUrl: product.imageUrl,
        actionColor: actionColor,
        actionLabel: actionLabel,
        actionIcon: actionIcon,
        quantityLabel: quantityLabel,
        priceLine: priceLine,
        entryId: entry.id,
        glow: _glow,
      );
    }

    return _FullPreview(
      productName: product.name,
      productId: product.id,
      hasImage: hasImage,
      imageUrl: product.imageUrl,
      actionColor: actionColor,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      quantityLabel: quantityLabel,
      priceLine: priceLine,
      entryId: entry.id,
      glow: _glow,
    );
  }
}

/// Borde + sombra animados (t=0 reposo, t=1 pico).
BoxDecoration _glowDecoration({
  required Color actionColor,
  required double t,
  required BorderRadius borderRadius,
  Color? fill,
}) {
  final borderColor = Color.lerp(
    actionColor.withValues(alpha: 0.35),
    actionColor,
    t,
  )!;
  return BoxDecoration(
    color: fill ?? Colors.grey.shade100,
    borderRadius: borderRadius,
    border: Border.all(
      color: borderColor,
      width: 2 + 3 * t,
    ),
    boxShadow: t > 0.04
        ? [
            BoxShadow(
              color: actionColor.withValues(alpha: 0.55 * t),
              blurRadius: 14 * t,
              spreadRadius: 1.5 * t,
            ),
            BoxShadow(
              color: actionColor.withValues(alpha: 0.25 * t),
              blurRadius: 28 * t,
              spreadRadius: 0,
            ),
          ]
        : null,
  );
}

class _FullPreview extends StatelessWidget {
  final String productName;
  final dynamic productId;
  final bool hasImage;
  final String? imageUrl;
  final Color actionColor;
  final String actionLabel;
  final IconData actionIcon;
  final String quantityLabel;
  final String priceLine;
  final dynamic entryId;
  final Animation<double> glow;

  const _FullPreview({
    required this.productName,
    required this.productId,
    required this.hasImage,
    required this.imageUrl,
    required this.actionColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.quantityLabel,
    required this.priceLine,
    required this.entryId,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.borderRadiusM);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: glow,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  decoration: _glowDecoration(
                    actionColor: actionColor,
                    t: glow.value,
                    borderRadius: radius,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    ProductImage(
                      key: ValueKey(
                        'scanner-img-$entryId-$productId-$imageUrl',
                      ),
                      imageUrl: imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: Icon(
                        Icons.inventory_2,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                    )
                  else
                    Icon(
                      Icons.inventory_2,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(actionIcon, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            productName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Código: $productId',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            quantityLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: actionColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            priceLine,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _DensePreview extends StatelessWidget {
  final String productName;
  final dynamic productId;
  final bool hasImage;
  final String? imageUrl;
  final Color actionColor;
  final String actionLabel;
  final IconData actionIcon;
  final String quantityLabel;
  final String priceLine;
  final dynamic entryId;
  final Animation<double> glow;

  const _DensePreview({
    required this.productName,
    required this.productId,
    required this.hasImage,
    required this.imageUrl,
    required this.actionColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.quantityLabel,
    required this.priceLine,
    required this.entryId,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    const imageSize = 72.0;
    final radius = BorderRadius.circular(AppDimensions.borderRadiusM);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingS,
      ),
      child: AnimatedBuilder(
        animation: glow,
        builder: (context, child) {
          return Container(
            decoration: _glowDecoration(
              actionColor: actionColor,
              t: glow.value,
              borderRadius: radius,
            ),
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: child,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: hasImage
                    ? ProductImage(
                        key: ValueKey(
                          'scanner-dense-$entryId-$productId-$imageUrl',
                        ),
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        width: imageSize,
                        height: imageSize,
                        placeholder: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(actionIcon, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          quantityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: actionColor,
                                    fontSize: 18,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                  ),
                  Text(
                    'Código: $productId  ·  $priceLine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
