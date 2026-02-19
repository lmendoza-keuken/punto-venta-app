import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';

abstract class PdvConfigEvent extends Equatable {
  const PdvConfigEvent();
  @override
  List<Object?> get props => [];
}

class FetchPdvConfigEvent extends PdvConfigEvent {}

class SavePdvConfigEvent extends PdvConfigEvent {
  final PdvConfig config;
  
  const SavePdvConfigEvent(this.config);
  
  @override
  List<Object?> get props => [config];
}
