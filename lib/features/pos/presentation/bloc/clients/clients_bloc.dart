import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/add_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/delete_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_clients_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'clients_event.dart';
import 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final GetClientsUsecase getClients;
  final AddClientUsecase addClient;
  final DeleteClientUsecase deleteClient;
  final PriceListLocalDataSource priceListLocalDataSource;

  ClientsBloc({
    required this.getClients,
    required this.addClient,
    required this.deleteClient,
    required this.priceListLocalDataSource,
  }) : super(ClientsInitial()) {
    on<LoadClients>(_onLoadClients);
    on<AddClientEvent>(_onAddClient);
    on<DeleteClientEvent>(_onDeleteClient);
    on<SelectClientEvent>(_onSelectClient);
  }

  Future<void> _onLoadClients(
      LoadClients event, Emitter<ClientsState> emit) async {
    // Preservar el cliente seleccionado actual
    final currentState = state;
    final currentSelectedClient =
        currentState is ClientsLoaded ? currentState.selectedClient : null;

    emit(ClientsLoading());
    try {
      final clients = await getClients();
      emit(ClientsLoaded(
        clients: clients,
        selectedClient: currentSelectedClient,
      ));
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

      // Si el cliente eliminado era el seleccionado, deseleccionar
      final currentState = state;
      final currentSelectedClient =
          currentState is ClientsLoaded ? currentState.selectedClient : null;

      final selectedClient = currentSelectedClient?.id == event.clientId
          ? null
          : currentSelectedClient;

      emit(ClientsLoaded(clients: clients, selectedClient: selectedClient));
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

  int? getSelectedClientListId() {
    final current = state;
    if (current is ClientsLoaded && current.selectedClient != null) {
      return current.selectedClient!.listId;
    }
    return null;
  }

  Future<int> getPriceListToUse() async {
    final clientListId = getSelectedClientListId();
    if (clientListId != null && clientListId > 0) {
      return clientListId;
    }

    final defaultListId = await priceListLocalDataSource.getCurrentPriceList();
    return defaultListId > 0 ? defaultListId : 1;
  }
}
