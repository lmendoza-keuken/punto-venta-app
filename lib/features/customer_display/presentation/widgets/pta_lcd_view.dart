import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';

/// Vista Flutter fija **320×240** para el LCD SPI del PTA0130.
///
/// Se captura a PNG y se envía con [PtaSubScreen.showBitmap].
/// Rediseñá acá: no hace falta tocar Canvas nativo.
class PtaLcdView extends StatelessWidget {
  const PtaLcdView({
    super.key,
    required this.snapshot,
    this.width = 320,
    this.height = 240,
  });

  final CustomerDisplaySnapshot snapshot;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 240),
          textScaler: TextScaler.linear(1),
        ),
        child: Material(
          color: _bgFor(snapshot.mode),
          child: switch (snapshot.mode) {
            CustomerDisplayMode.idle => const _IdleLcd(),
            CustomerDisplayMode.advertising => _AdvertisingLcd(
              snapshot: snapshot,
            ),
            CustomerDisplayMode.cart => _CartLcd(snapshot: snapshot),
            CustomerDisplayMode.payment => _PaymentLcd(snapshot: snapshot),
            CustomerDisplayMode.done => _DoneLcd(snapshot: snapshot),
          },
        ),
      ),
    );
  }

  static Color _bgFor(CustomerDisplayMode mode) => switch (mode) {
    CustomerDisplayMode.payment => const Color(0xFF1B5E20),
    CustomerDisplayMode.done => const Color(0xFF0D47A1),
    // Idle ≠ azul del init nativo, para distinguir “widget pintó” vs “solo init”.
    CustomerDisplayMode.idle => const Color(0xFF102A43),
    CustomerDisplayMode.advertising => const Color(0xFF0B6E4F),
    CustomerDisplayMode.cart => const Color(0xFF0F172A),
  };
}

class _IdleLcd extends StatelessWidget {
  const _IdleLcd();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: 40, color: Colors.white),
          SizedBox(height: 8),
          Text(
            'KEUKEN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bienvenido',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Pago en LCD: monto grande + QR / estado (mismo flujo que pantalla cliente).
class _PaymentLcd extends StatelessWidget {
  const _PaymentLcd({required this.snapshot});

  final CustomerDisplaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildBody()),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'www.keuken.com.ar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final total = snapshot.totalConIva.formatToCurrency();
    final qrLabel = snapshot.qrLabel?.trim();
    final payload = snapshot.qrPayload?.trim();
    final hasPayload = payload != null && payload.isNotEmpty;
    final phase = snapshot.qrPhase;

    if (snapshot.isProcessing) {
      return _PaymentAmountOnly(total: total, caption: 'Procesando…');
    }

    if (qrLabel != null &&
        qrLabel.isNotEmpty &&
        (phase == CustomerDisplayQrPhase.approved ||
            phase == CustomerDisplayQrPhase.rejected ||
            phase == CustomerDisplayQrPhase.expired ||
            (phase == CustomerDisplayQrPhase.pending && !hasPayload))) {
      final status = _qrStatus(phase);
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: _PaymentAmountColumn(total: total, label: qrLabel),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(status.icon, size: 48, color: status.color),
                  const SizedBox(height: 8),
                  Text(
                    status.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (snapshot.qrDetail != null &&
                      snapshot.qrDetail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      snapshot.qrDetail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (qrLabel != null && qrLabel.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _PaymentAmountColumn(
                total: total,
                label: qrLabel,
                pending: phase == CustomerDisplayQrPhase.pending,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: hasPayload
                  ? _LcdQrBox(data: payload, label: qrLabel)
                  : _LcdQrPlaceholder(label: qrLabel),
            ),
          ],
        ),
      );
    }

    return _PaymentAmountOnly(total: total, caption: 'Aguarde en caja');
  }

  static ({IconData icon, Color color, String title}) _qrStatus(
    CustomerDisplayQrPhase phase,
  ) {
    return switch (phase) {
      CustomerDisplayQrPhase.approved => (
        icon: Icons.check_circle,
        color: const Color(0xFF86EFAC),
        title: '¡Aprobado!',
      ),
      CustomerDisplayQrPhase.rejected => (
        icon: Icons.cancel,
        color: const Color(0xFFFCA5A5),
        title: 'Rechazado',
      ),
      CustomerDisplayQrPhase.expired => (
        icon: Icons.timer_off,
        color: const Color(0xFFFDE68A),
        title: 'Expirado',
      ),
      CustomerDisplayQrPhase.pending => (
        icon: Icons.hourglass_top,
        color: const Color(0xFFFDBA74),
        title: 'Confirmando…',
      ),
      CustomerDisplayQrPhase.none || CustomerDisplayQrPhase.ready => (
        icon: Icons.qr_code,
        color: Colors.white70,
        title: 'QR',
      ),
    };
  }
}

class _PaymentAmountColumn extends StatelessWidget {
  const _PaymentAmountColumn({
    required this.total,
    this.label,
    this.pending = false,
  });

  final String total;
  final String? label;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PAGAR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFBBF7D0),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            total,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        if (label != null && label!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (pending) ...[
          const SizedBox(height: 6),
          const Text(
            'Confirmando…',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFDBA74),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentAmountOnly extends StatelessWidget {
  const _PaymentAmountOnly({required this.total, required this.caption});

  final String total;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PAGAR',
            style: TextStyle(
              color: Color(0xFFBBF7D0),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              total,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            caption,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DoneLcd extends StatelessWidget {
  const _DoneLcd({required this.snapshot});

  final CustomerDisplaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'GRACIAS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              snapshot.totalConIva.formatToCurrency(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LcdQrBox extends StatelessWidget {
  const _LcdQrBox({required this.data, required this.label});

  final String data;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Escaneá para pagar',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(painter: _LcdQrPainter(data)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LcdQrPlaceholder extends StatelessWidget {
  const _LcdQrPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white38),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, color: Colors.white70, size: 40),
              const SizedBox(height: 6),
              Text(
                'Generando\n$label…',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LcdQrPainter extends CustomPainter {
  _LcdQrPainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final qr = Barcode.qrCode();
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    try {
      for (final element in qr.make(
        data,
        width: size.width,
        height: size.height,
      )) {
        if (element is BarcodeBar && element.black) {
          canvas.drawRect(
            Rect.fromLTWH(
              element.left,
              element.top,
              element.width,
              element.height,
            ),
            paint,
          );
        }
      }
    } catch (_) {
      final fallback = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(Offset.zero & size, fallback);
    }
  }

  @override
  bool shouldRepaint(covariant _LcdQrPainter oldDelegate) =>
      oldDelegate.data != data;
}

/// Un slide del carrusel de ofertas (como [CustomerDisplayAdCarousel]).
/// El índice rotativo lo elige el tiempo; Android re-captura cada 4s.
class _AdvertisingLcd extends StatelessWidget {
  const _AdvertisingLcd({required this.snapshot});

  final CustomerDisplaySnapshot snapshot;

  /// Misma cadencia que el PageView de pantalla cliente (4s).
  static const rotateSeconds = 4;

  static int slideIndexFor(int productCount, [DateTime? now]) {
    if (productCount <= 0) return 0;
    final t = now ?? DateTime.now();
    return (t.millisecondsSinceEpoch ~/ (rotateSeconds * 1000)) % productCount;
  }

  @override
  Widget build(BuildContext context) {
    final products = snapshot.adProducts;
    final title = snapshot.adTitle?.trim().isNotEmpty == true
        ? snapshot.adTitle!.trim()
        : 'Promociones';

    if (products.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF0B6E4F),
        child: Center(
          child: Text(
            'No hay productos en oferta',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    final index = slideIndexFor(products.length);
    final product = products[index];
    final imageUrl = product.imageUrl?.trim();
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    final showRegular =
        product.isOnSale &&
        product.regularPrice != null &&
        product.regularPrice! > product.unitPrice;

    return ColoredBox(
      color: const Color(0xFF0B6E4F),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFBBF7D0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 3,
              child: _LcdImageFrame(
                borderColor: const Color(0xFFFBBF24),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (hasUrl)
                      _LcdProductImage(
                        imageUrl: imageUrl,
                        error: const _LcdImagePlaceholder(),
                      )
                    else
                      const _LcdImagePlaceholder(),
                    if (product.isOnSale)
                      const Positioned(top: 6, right: 6, child: _OfferBadge()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (showRegular)
              Text(
                product.regularPrice!.formatToCurrency(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.white70,
                ),
              ),
            Text(
              product.unitPrice.formatToCurrency(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            if (products.length > 1)
              Text(
                '${index + 1}/${products.length}',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'OFERTA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CartLcd extends StatelessWidget {
  const _CartLcd({required this.snapshot});

  final CustomerDisplaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final last = snapshot.lastProduct;
    final imageUrl = last?.imageUrl?.trim();
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    final badgeColor = last == null
        ? AppColors.primary
        : (last.isAdd ? const Color(0xFF2E7D32) : const Color(0xFFC62828));

    // Lista acotada para no pelear con el bloque grande del último producto.
    const maxLines = 5;
    final items = snapshot.items;
    final start = (items.length - maxLines).clamp(0, items.length);
    final visible = items.sublist(start);

    final lastProductBlock = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF134E4A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (last != null && last.isOnSale) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: _OfferBadge(),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            last?.name ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(last?.quantityLabel ?? '').replaceFirst('+', '')} x ${last?.unitPrice.formatToCurrency() ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );

    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            // Total del carrito
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF134E4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        snapshot.totalConIva.formatToCurrency(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Todo el resto en Expanded: no puede overflow el Column de 240px.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen + lista arriba, debajo del TOTAL.
                  Flexible(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 80,
                              child: _LcdImageFrame(
                                borderColor: badgeColor,
                                child: Stack(
                                  fit: StackFit.expand,
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    if (hasUrl)
                                      _LcdProductImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        error: const _LcdImagePlaceholder(),
                                      )
                                    else
                                      const _LcdImagePlaceholder(),
                                    if (last != null)
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            last.isAdd ? '+' : '−',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFF334155),
                                  ),
                                  const SizedBox(height: 2),
                                  if (visible.isEmpty)
                                    const Text(
                                      'Sin artículos',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  else
                                    for (final item in visible)
                                      _CartLineRow(item: item),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  lastProductBlock,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({required this.item});

  final CustomerDisplayLineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          // if (item.isOnSale) ...[const _OfferBadge(), const SizedBox(width: 3)],
          Expanded(
            child: Text(
              '${item.quantityLabel} ${item.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: item.isOnSale ? FontWeight.w700 : FontWeight.w400,
                color: item.isOnSale
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            item.lineTotal.formatToCurrency(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item.isOnSale ? const Color(0xFFFDE68A) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LcdImagePlaceholder extends StatelessWidget {
  const _LcdImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF1F5F9),
      child: Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 44),
    );
  }
}

/// Marco blanco con borde; recorta la imagen al radio (DecoratedBox no clippea).
class _LcdImageFrame extends StatelessWidget {
  const _LcdImageFrame({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Imagen para captura LCD: [NetworkImage]/[AssetImage] (misma cache que el
/// precache). Evita [CachedNetworkImage] + fadeIn que dejan el frame vacío.
class _LcdProductImage extends StatelessWidget {
  const _LcdProductImage({
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.error,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final fallback =
        error ?? Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 40);

    Widget image;
    if (ProductImage.isAssetUrl(url)) {
      image = Image.asset(
        ProductImage.assetPathFromUrl(url),
        fit: fit,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (url.startsWith('assets/')) {
      image = Image.asset(
        url,
        fit: fit,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      image = Image(
        image: NetworkImage(url),
        fit: fit,
        alignment: Alignment.center,
        gaplessPlayback: true,
        // Sin fade: si no, toImage captura el placeholder vacío.
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return fallback;
        },
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return ClipRect(child: SizedBox.expand(child: image));
  }
}
