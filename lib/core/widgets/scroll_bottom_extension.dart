import 'package:flutter/material.dart';

extension ScrollControllerExtensions on ScrollController {
  void scrollToBottom({
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasClients) return;
      final maxScroll = position.maxScrollExtent;
      if (maxScroll <= 0) return;
      try {
        animateTo(maxScroll, duration: duration, curve: curve);
      } catch (_) {
        if (hasClients) {
          jumpTo(position.maxScrollExtent);
        }
      }
    });
  }
}