import 'package:flutter/material.dart';

class PaymentMethodDetailsControllers {
  final TextEditingController accountOwner;
  final TextEditingController bankId;
  final TextEditingController checkNumber;
  final TextEditingController transferId;
  final TextEditingController verificationId;

  PaymentMethodDetailsControllers()
      : accountOwner = TextEditingController(),
        bankId = TextEditingController(),
        checkNumber = TextEditingController(),
        transferId = TextEditingController(),
        verificationId = TextEditingController();

  void dispose() {
    accountOwner.dispose();
    bankId.dispose();
    checkNumber.dispose();
    transferId.dispose();
    verificationId.dispose();
  }
}
