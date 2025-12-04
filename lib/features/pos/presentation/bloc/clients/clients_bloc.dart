import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/add_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/delete_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_clients_usecase.dart';
import 'clients_event.dart';
import 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final GetClientsUsecase getClients;
  final AddClientUsecase addClient;
  final DeleteClientUsecase deleteClient;
 
  ClientsBloc({
    required this.getClients,
    required this.addClient,
    required this.deleteClient,
  }) : super(ClientsInitial()) {
    on<LoadClients>(_onLoadClients);
    on<AddClientEvent>(_onAddClient);
    on<DeleteClientEvent>(_onDeleteClient);
    on<SelectClientEvent>(_onSelectClient);
  }

  Future<void> _onLoadClients(
      LoadClients event, Emitter<ClientsState> emit) async {
    emit(ClientsLoading());
    try {
      final clients = await getClients();
      emit(ClientsLoaded(clients: clients));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onAddClient(
      AddClientEvent event, Emitter<ClientsState> emit) async {
    try {
      await addClient.call(event.client);
      final clients = await getClients();
      emit(ClientsLoaded(clients: clients, selectedClient: event.client));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onDeleteClient(
      DeleteClientEvent event, Emitter<ClientsState> emit) async {
    try {
      await deleteClient.call(event.clientId);
      final clients = await getClients();
      emit(ClientsLoaded(clients: clients));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  void _onSelectClient(SelectClientEvent event, Emitter<ClientsState> emit) {
    final current = state;
    if (current is ClientsLoaded) {
      emit(ClientsLoaded(
          clients: current.clients, selectedClient: event.client));
    } else {
      emit(ClientsLoaded(clients: [], selectedClient: event.client));
    }
  }
}
