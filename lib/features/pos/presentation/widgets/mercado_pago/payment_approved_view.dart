import 'package:flutter/material.dart';

class PaymentApprovedView extends StatefulWidget {
  final String paymentId;
  final String referenceId;
  final VoidCallback onTap;
  final bool isAccountMoney;

  const PaymentApprovedView({
    super.key,
    required this.paymentId,
    required this.referenceId,
    required this.onTap,
    this.isAccountMoney = true,
  });

  @override
  State<PaymentApprovedView> createState() => _PaymentApprovedViewState();
}

class _PaymentApprovedViewState extends State<PaymentApprovedView> {
  bool _isProcessing = false;

  void _handleTap() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final Color approvedColor =
        widget.isAccountMoney ? Colors.green : Colors.orange;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/mercadopago_logo.png',
          height: 70,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: approvedColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            !widget.isAccountMoney
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            color: approvedColor,
            size: 80,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Pago Aprobado!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: approvedColor,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'El pago ha sido procesado exitosamente',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (!widget.isAccountMoney) ...[
          const Text(
            'No se ha utilizado dinero en cuenta de\nMercado Pago para realizar este pago.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          const Text(
            'Este pago tendrá una comisión\nmayor por parte de Mercado Pago.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: approvedColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'N.º de Referencia',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                widget.referenceId,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: approvedColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ID de Pago',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                widget.paymentId,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: approvedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final continueButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handleTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: approvedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: approvedColor.withValues(alpha: 0.5),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.maxHeight.isFinite;

            if (!hasBoundedHeight) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: 24),
                  continueButton,
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(child: content),
                ),
                const SizedBox(height: 16),
                continueButton,
              ],
            );
          },
        ),
      ),
    );
  }
}
