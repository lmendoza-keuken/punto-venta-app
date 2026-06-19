import 'package:equatable/equatable.dart';

abstract class SettlementsEvent extends Equatable {
  const SettlementsEvent();

  @override
  List<Object?> get props => [];
}

class FetchPendingCollectors extends SettlementsEvent {
  final String date;

  const FetchPendingCollectors({required this.date});

  @override
  List<Object?> get props => [date];
}

class FetchPendingCollectorDetail extends SettlementsEvent {
  final String collectorId;

  const FetchPendingCollectorDetail({required this.collectorId});

  @override
  List<Object?> get props => [collectorId];
}
