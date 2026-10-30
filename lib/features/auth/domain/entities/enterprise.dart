import 'package:equatable/equatable.dart';

class Enterprise extends Equatable {
  final int id;
  final String name;
  final String? baseUrl;
  final List<String> baseUrls;
  final int? listPriceId;

  const Enterprise({
    required this.id,
    required this.name,
    this.baseUrl,
    this.baseUrls = const [],
    this.listPriceId,
  });


  @override
  List<Object?> get props => [id, name, baseUrl, baseUrls, listPriceId];
}
