import 'package:equatable/equatable.dart';
import '../../../domain/entities/client.dart';

abstract class ClientsEvent extends Equatable {
  const ClientsEvent();
  @override
  List<Object?> get props => [];
}

class LoadClients extends ClientsEvent {}

class AddClientEvent extends ClientsEvent {
  final Client client;
  const AddClientEvent(this.client);
  @override
  List<Object?> get props => [client];
}

class DeleteClientEvent extends ClientsEvent {
  final String clientId;
  const DeleteClientEvent(this.clientId);
  @override
  List<Object?> get props => [clientId];
}

class SelectClientEvent extends ClientsEvent {
  final Client? client;
  const SelectClientEvent(this.client);
  @override
  List<Object?> get props => [client];
}

class LoadDefaultClientEvent extends ClientsEvent {}

class ResetToDefaultClientEvent extends ClientsEvent {}
