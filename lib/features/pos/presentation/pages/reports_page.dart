import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/ticket_preview_dialog.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedEndDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _onTabChanged(_tabController.index);
    }
  }

  void _onTabChanged(int index) {
    if (index == 0) {
      // Mantener el rango de fechas al volver a resumen diario
      if (selectedEndDate != null) {
        context.read<ReportsBloc>().add(
              LoadReportsByDateRange(selectedDate, selectedEndDate!),
            );
      } else {
        context
            .read<ReportsBloc>()
            .add(LoadDailySummary(selectedDate));
      }
    } else {
      // Limpiar buscador y cargar todos los tickets
      _searchController.clear();
      setState(() {});
      context.read<ReportsBloc>().add(LoadAllReports());
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is TicketPrinted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ReportsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.calendar_today, size: 15),
                  text: 'Resumen Diario',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.history, size: 15),
                  text: 'Historial',
                  height: 50,
                ),
              ],
              onTap: _onTabChanged,
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailySummaryTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryTab() {
    return Column(
      children: [
        // Date picker
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Fecha inicio: '),
                  const SizedBox(width: AppDimensions.paddingS),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingS,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.borderRadiusS),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: AppDimensions.paddingS),
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  const Text('Fecha fin (opcional): '),
                  const SizedBox(width: AppDimensions.paddingS),
                  InkWell(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingS,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.borderRadiusS),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: AppDimensions.paddingS),
                          Text(selectedEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(selectedEndDate!)
                              : 'Sin seleccionar'),
                        ],
                      ),
                    ),
                  ),
                  if (selectedEndDate != null) ...[
                    const SizedBox(width: AppDimensions.paddingS),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          selectedEndDate = null;
                        });
                      },
                      tooltip: 'Limpiar fecha fin',
                    ),
                  ],
                  const SizedBox(width: AppDimensions.paddingM),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedEndDate != null) {
                        context.read<ReportsBloc>().add(
                              LoadReportsByDateRange(selectedDate, selectedEndDate!),
                            );
                      } else {
                        context
                            .read<ReportsBloc>()
                            .add(LoadDailySummary(selectedDate));
                      }
                    },
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Summary and orders
        Expanded(
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportsLoaded) {
                return Column(
                  children: [
                    if (state.summary != null)
                      _buildSummaryCards(state.summary!),
                    Expanded(
                      child: _buildOrdersList(state.orders, showDate: selectedEndDate != null),
                    ),
                  ],
                );
              } else if (state is ReportsError) {
                return _buildErrorWidget(state.message);
              }
              return const Center(
                  child: Text('Selecciona una fecha para ver el reporte'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Buscador
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por ID de ticket...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        // Lista de órdenes
        Expanded(
          child: BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              if (state is ReportsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportsLoaded) {
                final filteredOrders = _searchController.text.isEmpty
                    ? state.orders
                    : state.orders
                        .where((order) => order.id
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();
                return _buildOrdersList(filteredOrders, showDate: true);
              } else if (state is ReportsError) {
                return _buildErrorWidget(state.message);
              }
              return const Center(child: Text('Cargando historial...'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: Row(
        children: [
          Expanded(
              child: _buildSummaryCard(
                  'Total Ventas',
                  (summary['total_sales'] as double).formatToCurrency(),
                  Icons.attach_money,
                  AppColors.success)),
          Expanded(
              child: _buildSummaryCard('Órdenes', '${summary['total_orders']}',
                  Icons.receipt, AppColors.primary)),
          Expanded(
              child: _buildSummaryCard('Artículos', '${summary['total_items']}',
                  Icons.inventory, AppColors.warning)),
          Expanded(
              child: _buildSummaryCard(
                  'IVA Total',
                  (summary['total_tax'] as double).formatToCurrency(),
                  Icons.percent,
                  AppColors.info)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<CompletedOrder> orders,
      {required bool showDate}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No hay órdenes completadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return GestureDetector(
          onTap: () => _showTicketPreview(order),
          child: Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            child: ListTile(
              title: Text(
                showDate
                    ? "#${order.id} | ${DateFormat('dd/MM/yyyy HH:mm').format(order.completedAt)}"
                    : "#${order.orderNumber} | ${DateFormat('HH:mm').format(order.completedAt)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.clientName != null)
                    Text('Cliente: ${order.clientName}'),
                  Text('${order.items.length} artículos'),
                  Text('Pago: ${order.paymentMethod?.shortDescription.toLowerCase()}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    order.total.formatToCurrency(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: AppColors.error, size: 64),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Error al cargar reportes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(message),
          const SizedBox(height: AppDimensions.paddingM),
          ElevatedButton(
            onPressed: () {
              if (_tabController.index == 0) {
                if (selectedEndDate != null) {
                  context.read<ReportsBloc>().add(
                        LoadReportsByDateRange(selectedDate, selectedEndDate!),
                      );
                } else {
                  context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
                }
              } else {
                context.read<ReportsBloc>().add(LoadAllReports());
              }
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? selectedDate,
      firstDate: selectedDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedEndDate = picked;
      });
    }
  }

  void _showTicketPreview(CompletedOrder order) {
    showDialog(
      context: context,
      builder: (context) => TicketPreviewDialog(order: order),
    );
  }
}
