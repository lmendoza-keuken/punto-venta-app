import 'package:flutter/material.dart';

/// Whether the top route of [navigator] is a dialog/modal popup.
///
/// Uses [Navigator.popUntil] with an immediate stop so no routes are popped.
bool navigatorTopIsPopup(NavigatorState navigator) {
  var isPopup = false;
  navigator.popUntil((route) {
    isPopup = route is PopupRoute;
    return true;
  });
  return isPopup;
}

/// Pops only if the top route is a [PopupRoute] (dialog, bottom sheet, etc.).
/// Never pops page/shell routes from go_router history.
bool popNavigatorPopup(NavigatorState navigator) {
  if (!navigatorTopIsPopup(navigator)) return false;
  navigator.pop();
  return true;
}
