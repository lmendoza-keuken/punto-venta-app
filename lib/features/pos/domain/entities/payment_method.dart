class PaymentMethod {
  final int id;
  final String description;
  final String shortDescription;
  final String deleteAt;

  const PaymentMethod({
    required this.id,
    required this.description,
    required this.shortDescription,
    required this.deleteAt,
  });
}
