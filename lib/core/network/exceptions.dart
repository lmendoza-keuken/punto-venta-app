class NotFoundException implements Exception {
  final String message;
  NotFoundException([this.message = 'Recurso no encontrado']);

  @override
  String toString() => message;
}
