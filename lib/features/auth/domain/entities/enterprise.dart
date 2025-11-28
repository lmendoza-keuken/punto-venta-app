import 'package:equatable/equatable.dart';

class Enterprise extends Equatable {
  final int id;
  final String name;

  const Enterprise({
    required this.id,
    required this.name,
  });


  @override
  List<Object?> get props => [id, name];
}