import 'package:equatable/equatable.dart';

class Enterprise extends Equatable {
  final int id;
  final String name;
  final String? baseUrl;
  final int? listPriceId;

  const Enterprise({
    required this.id,
    required this.name,
    this.baseUrl,
    this.listPriceId,
  });


  @override
  List<Object?> get props => [id, name, baseUrl, listPriceId];
}