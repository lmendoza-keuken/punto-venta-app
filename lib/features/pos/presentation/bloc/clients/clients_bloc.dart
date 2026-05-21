import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/add_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/delete_client_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_clients_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'clients_event.dart';
import 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final GetClientsUsecase getClients;
  final AddClientUsecase addClient;
  final DeleteClientUsecase deleteClient;
  final PriceListLocalDataSource priceListLocalDataSource;
  final PdvLocalDataSource pdvLocalDataSource;

  ClientsBloc({
    required this.getClients,
    required this.addClient,
    required this.deleteClient,
    required this.priceListLocalDataSource,
    required this.pdvLocalDataSource,
  }) : super(ClientsInitial()) {
    on<LoadClients>(_onLoadClients);
    on<AddClientEvent>(_onAddClient);
    on<DeleteClientEvent>(_onDeleteClient);
    on<SelectClientEvent>(_onSelectClient);
    on<LoadDefaultClientEvent>(_onLoadDefaultClient);
    on<ResetToDefaultClientEvent>(_onResetToDefaultClient);
  }

  Future<void> _onLoadClients(
      LoadClients event, Emitter<ClientsState> emit) async {
    final currentState = state;
    final currentSelectedClient =
        currentState is ClientsLoaded ? currentState.selectedClient : null;
    final currentDefaultClient =
        currentState is ClientsLoaded ? currentState.defaultClient : null;

    emit(ClientsLoading());
    try {
      final clients = await getClients();
      emit(ClientsLoaded(
        clients: clients,
        selectedClient: currentSelectedClient,
        defaultClient: currentDefaultClient,
      ));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onAddClient(
      AddClientEvent event, Emitter<ClientsState> emit) async {
    final currentState = state;
    final currentDefaultClient =
        currentState is ClientsLoaded ? currentState.defaultClient : null;
        
    try {
      await addClient.call(event.client);
      final clients = await getClients();
      emit(ClientsLoaded(
        clients: clients, 
        selectedClient: event.client,
        defaultClient: currentDefaultClient,
      ));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  Future<void> _onDeleteClient(
      DeleteClientEvent event, Emitter<ClientsState> emit) async {
    try {
      await deleteClient.call(int.parse(event.clientId));
      final clients = await getClients();

      // Si el cliente eliminado era el seleccionado, deseleccionar
      final currentState = state;
      final currentSelectedClient =
          currentState is ClientsLoaded ? currentState.selectedClient : null;
      final currentDefaultClient =
          currentState is ClientsLoaded ? currentState.defaultClient : null;

      final selectedClient = currentSelectedClient?.id.toString() == event.clientId
          ? null
          : currentSelectedClient;

      final defaultClient = currentDefaultClient?.id.toString() == event.clientId
          ? null
          : currentDefaultClient;

      emit(ClientsLoaded(
        clients: clients, 
        selectedClient: selectedClient,
        defaultClient: defaultClient,
      ));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  void _onSelectClient(SelectClientEvent event, Emitter<ClientsState> emit) {
    final current = state;
    if (current is ClientsLoaded) {
      emit(ClientsLoaded(
        clients: current.clients, 
        selectedClient: event.client,
        defaultClient: current.defaultClient,
      ));
    } else {
      emit(ClientsLoaded(
        clients: [], 
        selectedClient: event.client,
      ));
    }
  }

  Future<void> _onLoadDefaultClient(
      LoadDefaultClientEvent event, Emitter<ClientsState> emit) async {
    try {
      final pdvConfig = await pdvLocalDataSource.getPdvConfig();
      final defaultClientId = pdvConfig?.pdvId;

      if (defaultClientId == null) {
        return;
      }

      final clients = await getClients();
      
      Client? defaultClient;
      for (final client in clients) {
        if (client.id == defaultClientId.toString()) {
          defaultClient = client;
          break;
        }
      }

      final currentState = state;
      final currentSelectedClient =
          currentState is ClientsLoaded ? currentState.selectedClient : null;

      emit(ClientsLoaded(
        clients: clients,
        selectedClient: currentSelectedClient ?? defaultClient,
        defaultClient: defaultClient,
      ));
    } catch (e) {
      emit(ClientsError(e.toString()));
    }
  }

  void _onResetToDefaultClient(
      ResetToDefaultClientEvent event, Emitter<ClientsState> emit) {
    final current = state;
    if (current is ClientsLoaded && current.defaultClient != null) {
      emit(ClientsLoaded(
        clients: current.clients,
        selectedClient: current.defaultClient,
        defaultClient: current.defaultClient,
      ));
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
