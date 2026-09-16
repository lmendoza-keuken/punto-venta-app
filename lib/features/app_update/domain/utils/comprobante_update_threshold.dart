/// Pure helper: whether the comprobante counter should trigger a Firestore check.
bool shouldCheckUpdateForComprobantes({
  required int countAfterIncrement,
  required int? threshold,
}) {
  if (threshold == null || threshold <= 0) return false;
  return countAfterIncrement >= threshold;
}
