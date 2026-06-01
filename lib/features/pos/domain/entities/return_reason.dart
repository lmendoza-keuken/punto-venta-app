class ReturnReason {
  final int id;
  final String description;
  final String? code;

  const ReturnReason({
    required this.id,
    required this.description,
    this.code,
  });
}
