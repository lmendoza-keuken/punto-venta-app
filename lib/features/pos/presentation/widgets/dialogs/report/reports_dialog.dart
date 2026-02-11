// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:punto_venta_app/core/constants/app_colors.dart';
// import 'package:punto_venta_app/core/constants/app_dimensions.dart';
// import 'package:punto_venta_app/core/utils/extensions.dart';
// import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
// import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
// import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_event.dart';
// import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
// import 'ticket_preview_dialog.dart';

// class ReportsDialog extends StatefulWidget {
//   const ReportsDialog({super.key});

//   @override
//   State<ReportsDialog> createState() => _ReportsDialogState();
// }

// class _ReportsDialogState extends State<ReportsDialog>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   DateTime selectedDate = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ReportsBloc, ReportsState>(
//       listener: (context, state) {
//         if (state is TicketPrinted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(state.message),
//               backgroundColor: AppColors.success,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         } else if (state is ReportsError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(state.message),
//               backgroundColor: AppColors.error,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       },
//       child: Dialog(
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.9,
//           height: MediaQuery.of(context).size.height * 0.8,
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.all(AppDimensions.paddingM),
//                 decoration: const BoxDecoration(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(AppDimensions.borderRadiusL),
//                     topRight: Radius.circular(AppDimensions.borderRadiusL),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.assessment, color: AppColors.primary),
//                     const SizedBox(width: AppDimensions.paddingS),
//                     Text(
//                       'Reportes de Ventas',
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.black),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                   ],
//                 ),
//               ),

//               // Tabs
//               TabBar(
//                 controller: _tabController,
//                 labelColor: AppColors.primary,
//                 unselectedLabelColor: Colors.grey,
//                 indicatorColor: AppColors.primary,
//                 tabs: const [
//                   Tab(text: 'Resumen del Día'),
//                   Tab(text: 'Historial Completo'),
//                 ],
//                 onTap: (index) {
//                   if (index == 0) {
//                     context
//                         .read<ReportsBloc>()
//                         .add(LoadDailySummary(selectedDate));
//                   } else {
//                     context.read<ReportsBloc>().add(LoadAllReports());
//                   }
//                 },
//               ),

//               // Content
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     _buildDailySummaryTab(),
//                     _buildHistoryTab(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDailySummaryTab() {
//     return Column(
//       children: [
//         // Date picker
//         Container(
//           padding: const EdgeInsets.all(AppDimensions.paddingM),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
//           ),
//           child: Row(
//             children: [
//               const Text('Fecha: '),
//               const SizedBox(width: AppDimensions.paddingS),
//               InkWell(
//                 onTap: _selectDate,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: AppDimensions.paddingM,
//                     vertical: AppDimensions.paddingS,
//                   ),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius:
//                         BorderRadius.circular(AppDimensions.borderRadiusS),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.calendar_today, size: 16),
//                       const SizedBox(width: AppDimensions.paddingS),
//                       Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: AppDimensions.paddingM),
//               ElevatedButton(
//                 onPressed: () {
//                   context
//                       .read<ReportsBloc>()
//                       .add(LoadDailySummary(selectedDate));
//                 },
//                 child: const Text('Actualizar'),
//               ),
//             ],
//           ),
//         ),

//         // Summary and orders
//         Expanded(
//           child: BlocBuilder<ReportsBloc, ReportsState>(
//             builder: (context, state) {
//               if (state is ReportsLoading) {
//                 return const Center(child: CircularProgressIndicator());
//               } else if (state is ReportsLoaded) {
//                 return Column(
//                   children: [
//                     if (state.summary != null)
//                       _buildSummaryCards(state.summary!),
//                     Expanded(
//                         child: _buildOrdersList(state.orders, showDate: false)),
//                   ],
//                 );
//               } else if (state is ReportsError) {
//                 return _buildErrorWidget(state.message);
//               }
//               return const Center(
//                   child: Text('Selecciona una fecha para ver el reporte'));
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHistoryTab() {
//     return BlocBuilder<ReportsBloc, ReportsState>(
//       builder: (context, state) {
//         if (state is ReportsLoading) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (state is ReportsLoaded) {
//           return _buildOrdersList(state.orders, showDate: true);
//         } else if (state is ReportsError) {
//           return _buildErrorWidget(state.message);
//         }
//         return const Center(child: Text('Cargando historial...'));
//       },
//     );
//   }

//   Widget _buildSummaryCards(Map<String, dynamic> summary) {
//     return Container(
//       padding: const EdgeInsets.all(AppDimensions.paddingM),
//       child: Row(
//         children: [
//           Expanded(
//               child: _buildSummaryCard(
//                   'Total Ventas',
//                   (summary['total_sales'] as double).formatToCurrency(),
//                   Icons.attach_money,
//                   AppColors.success)),
//           Expanded(
//               child: _buildSummaryCard('Órdenes', '${summary['total_orders']}',
//                   Icons.receipt, AppColors.primary)),
//           Expanded(
//               child: _buildSummaryCard('Artículos', '${summary['total_items']}',
//                   Icons.inventory, AppColors.warning)),
//           Expanded(
//               child: _buildSummaryCard(
//                   'IVA Total',
//                   (summary['total_tax'] as double).formatToCurrency(),
//                   Icons.percent,
//                   AppColors.info)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryCard(
//       String title, String value, IconData icon, Color color) {
//     return Card(
//       child: Container(
//         padding: const EdgeInsets.all(AppDimensions.paddingS),
//         child: Column(
//           children: [
//             Text(
//               title,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey.shade600,
//                   ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOrdersList(List<CompletedOrder> orders,
//       {required bool showDate}) {
//     if (orders.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
//             const SizedBox(height: AppDimensions.paddingM),
//             Text(
//               'No hay órdenes completadas',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: Colors.grey.shade600,
//                   ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(AppDimensions.paddingM),
//       itemCount: orders.length,
//       itemBuilder: (context, index) {
//         final order = orders[index];
//         return GestureDetector(
//           onTap: () => _showTicketPreview(order),
//           child: Card(
//             margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: AppColors.success,
//                 child: Text(
//                   order.totalItems.toString(),
//                   style: const TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               title: Text(
//                 order.orderNumber,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Total: ${order.total.formatToCurrency()}'),
//                   if (showDate)
//                     Text(
//                         'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(order.completedAt)}'),
//                   if (order.clientName != null)
//                     Text('Cliente: ${order.clientName}'),
//                   Text('Cajero: ${order.cashierName}'),
//                   Text('Pago: ${order.paymentMethod}'),
//                 ],
//               ),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.visibility, color: AppColors.info),
//                     onPressed: () => _showTicketPreview(order),
//                     tooltip: 'Ver ticket',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error, color: AppColors.error, size: 64),
//           const SizedBox(height: AppDimensions.paddingM),
//           Text(
//             'Error al cargar reportes',
//             style: Theme.of(context).textTheme.titleMedium,
//           ),
//           const SizedBox(height: AppDimensions.paddingS),
//           Text(message),
//           const SizedBox(height: AppDimensions.paddingM),
//           ElevatedButton(
//             onPressed: () {
//               if (_tabController.index == 0) {
//                 context.read<ReportsBloc>().add(LoadDailySummary(selectedDate));
//               } else {
//                 context.read<ReportsBloc>().add(LoadAllReports());
//               }
//             },
//             child: const Text('Reintentar'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }

//   void _showTicketPreview(CompletedOrder order) {
//     showDialog(
//       context: context,
//       builder: (context) => TicketPreviewDialog(order: order),
//     );
//   }
// }
