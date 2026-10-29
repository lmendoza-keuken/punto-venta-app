class DisposeReason {
  final int id;
  final String description;
  final String? code;

  const DisposeReason({
    required this.id,
    required this.description,
    this.code,
  });
}
