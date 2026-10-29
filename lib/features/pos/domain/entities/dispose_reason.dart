class DisposeReason {
  final int id;
  final String description;
  final String? code;
  final String? firebirdCode;
  final bool enabled;

  const DisposeReason({
    required this.id,
    required this.description,
    this.code,
    this.firebirdCode,
    this.enabled = true,
  });
}
