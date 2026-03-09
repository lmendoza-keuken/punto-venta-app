import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';

abstract class PdvConfigState extends Equatable {
  const PdvConfigState();
  @override
  List<Object?> get props => [];
}

class PdvConfigInitial extends PdvConfigState {}

class PdvConfigLoading extends PdvConfigState {}

class PdvConfigLoaded extends PdvConfigState {
  final PdvConfig config;
  final List<Branch> branches;

  const PdvConfigLoaded(this.config, {this.branches = const []});

  @override
  List<Object?> get props => [config, branches];
}

class BranchesLoading extends PdvConfigState {}

class BranchesLoaded extends PdvConfigState {
  final List<Branch> branches;

  const BranchesLoaded(this.branches);

  @override
  List<Object?> get props => [branches];
}

class PdvConfigError extends PdvConfigState {
  final String message;

  const PdvConfigError(this.message);

  @override
  List<Object?> get props => [message];
}

class PdvConfigSaved extends PdvConfigState {
  final PdvConfig config;

  const PdvConfigSaved(this.config);

  @override
  List<Object?> get props => [config];
}

class OfflineModeUpdated extends PdvConfigState {
  final bool offlineMode;

  const OfflineModeUpdated(this.offlineMode);

  @override
  List<Object?> get props => [offlineMode];
}
