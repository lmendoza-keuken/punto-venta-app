import 'package:equatable/equatable.dart';
import '../../../domain/entities/client.dart';

abstract class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<Client> clients;
  final Client? selectedClient;
  final Client? defaultClient;

  const ClientsLoaded({
    required this.clients, 
    this.selectedClient,
    this.defaultClient,
  });
  
  @override
  List<Object?> get props => [clients, selectedClient, defaultClient];
}

class ClientsError extends ClientsState {
  final String message;
  const ClientsError(this.message);
  @override
  List<Object?> get props => [message];
}
