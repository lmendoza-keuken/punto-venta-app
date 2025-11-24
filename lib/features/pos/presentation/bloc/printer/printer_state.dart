abstract class PrinterState {
  const PrinterState();
}

class PrinterInitial extends PrinterState {}

class PrinterConnecting extends PrinterState {}

class PrinterConnected extends PrinterState {}

class PrinterPrinting extends PrinterState {}

class PrinterSuccess extends PrinterState {
  final String message;
  
  const PrinterSuccess(this.message);
}

class PrinterError extends PrinterState {
  final String message;
  
  const PrinterError(this.message);
}

class PrinterDisconnected extends PrinterState {}