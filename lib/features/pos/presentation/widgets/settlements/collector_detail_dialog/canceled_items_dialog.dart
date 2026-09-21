import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/data/models/pending_canceled_items_response_model.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/settlements/settlements_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class CanceledItemsDialog extends StatelessWidget {
  final String collectorId;
  final String collectorName;
  final String date;

  const CanceledItemsDialog({
    super.key,
    required this.collectorId,
    required this.collectorName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<SettlementsBloc>()
        ..add(FetchPendingCanceledItems(
          collectorId: collectorId,
          date: date,
        )),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          height: MediaQuery.of(context).size.height * 0.7,
          child: _CanceledItemsDialogContent(
            collectorId: collectorId,
            collectorName: collectorName,
            date: date,
          ),
        ),
      ),
    );
  }
}

class _AggregatedCanceledItem {
  final int? productId;
  final String productName;
  final bool isWeighted;
  final double totalQuantity;
  final double totalWeight;
  final List<PendingCanceledTicketModel> tickets;

  const _AggregatedCanceledItem({
    required this.productId,
    required this.productName,
    required this.isWeighted,
    required this.totalQuantity,
    required this.totalWeight,
    required this.tickets,
  });

  String get quantityLabel => isWeighted
      ? '${totalWeight.toStringAsFixed(3)} kg'
      : '${totalQuantity.round()} unid.';

  int get ticketCount => tickets.length;
}

List<_AggregatedCanceledItem> _aggregateCanceledItems(
  List<PendingCanceledTicketModel> tickets,
) {
  final map = <String, _AggregatedCanceledItem>{};

  for (final ticket in tickets) {
    for (final item in ticket.canceledItems ?? const <CanceledItemModel>[]) {
      final key = item.productId?.toString() ??
          (item.productName ?? 'unknown').toLowerCase();
      final isWeighted = item.isWeighted == 'S';
      final existing = map[key];

      if (existing == null) {
        map[key] = _AggregatedCanceledItem(
          productId: item.productId,
          productName: item.productName ?? 'Producto',
          isWeighted: isWeighted,
          totalQuantity: item.quantity ?? 0,
          totalWeight: item.weight ?? 0,
          tickets: [ticket],
        );
      } else {
        final ticketsForItem = List<PendingCanceledTicketModel>.from(
          existing.tickets,
        );
        if (!ticketsForItem.any((t) => t.ticketId == ticket.ticketId)) {
          ticketsForItem.add(ticket);
        }

        map[key] = _AggregatedCanceledItem(
          productId: existing.productId,
          productName: existing.productName,
          isWeighted: existing.isWeighted || isWeighted,
          totalQuantity: existing.totalQuantity + (item.quantity ?? 0),
          totalWeight: existing.totalWeight + (item.weight ?? 0),
          tickets: ticketsForItem,
        );
      }
    }
  }

  final aggregated = map.values.toList()
    ..sort((a, b) {
      final aValue = a.isWeighted ? a.totalWeight : a.totalQuantity;
      final bValue = b.isWeighted ? b.totalWeight : b.totalQuantity;
      return bValue.compareTo(aValue);
    });

  return aggregated;
}

class _CanceledItemsDialogContent extends StatefulWidget {
  final String collectorId;
  final String collectorName;
  final String date;

  const _CanceledItemsDialogContent({
    required this.collectorId,
    required this.collectorName,
    required this.date,
  });

  @override
  State<_CanceledItemsDialogContent> createState() =>
      _CanceledItemsDialogContentState();
}

class _CanceledItemsDialogContentState extends State<_CanceledItemsDialogContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color:
              isDark ? AppColors.sidebarDarkBackground : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artículos Cancelados',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.collectorName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
        Material(
          color: isDark ? AppColors.sidebarDarkBackground : Colors.grey.shade100,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Por artículo'),
              Tab(text: 'Por factura'),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<SettlementsBloc, SettlementsState>(
            builder: (context, state) {
              if (state is SettlementsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is SettlementsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingXL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'Error al obtener artículos cancelados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<SettlementsBloc>().add(
                                  FetchPendingCanceledItems(
                                    collectorId: widget.collectorId,
                                    date: widget.date,
                                  ),
                                );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is PendingCanceledItemsLoaded) {
                if (state.canceledTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 48,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'No hay artículos cancelados',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final aggregated =
                    _aggregateCanceledItems(state.canceledTickets);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _AggregatedItemsList(
                      items: aggregated,
                      isDark: isDark,
                      onItemTap: (item) => _showRelatedTickets(context, item),
                    ),
                    _TicketsList(
                      tickets: state.canceledTickets,
                      isDark: isDark,
                      onTicketTap: (ticket) =>
                          _showTicketItems(context, ticket),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.sidebarDarkBackground : Colors.grey.shade50,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ),
        ),
      ],
    );
  }

  void _showRelatedTickets(
    BuildContext context,
    _AggregatedCanceledItem item,
  ) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => _RelatedTicketsDialog(item: item),
    );
  }

  void _showTicketItems(
    BuildContext context,
    PendingCanceledTicketModel ticket,
  ) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => _CanceledTicketItemsDialog(ticket: ticket),
    );
  }
}

class _AggregatedItemsList extends StatelessWidget {
  final List<_AggregatedCanceledItem> items;
  final bool isDark;
  final ValueChanged<_AggregatedCanceledItem> onItemTap;

  const _AggregatedItemsList({
    required this.items,
    required this.isDark,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.paddingS),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          child: InkWell(
            onTap: () => onItemTap(item),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusS),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.block,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (item.productId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Código: ${item.productId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${item.ticketCount} factura${item.ticketCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.quantityLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TicketsList extends StatelessWidget {
  final List<PendingCanceledTicketModel> tickets;
  final bool isDark;
  final ValueChanged<PendingCanceledTicketModel> onTicketTap;

  const _TicketsList({
    required this.tickets,
    required this.isDark,
    required this.onTicketTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: tickets.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.paddingS),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _CanceledTicketCard(
          ticket: ticket,
          isDark: isDark,
          onTap: () => onTicketTap(ticket),
        );
      },
    );
  }
}

class _RelatedTicketsDialog extends StatelessWidget {
  final _AggregatedCanceledItem item;

  const _RelatedTicketsDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tickets = List<PendingCanceledTicketModel>.from(item.tickets)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.timestamp ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b.timestamp ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: isDark
                  ? AppColors.sidebarDarkBackground
                  : Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingM,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facturas relacionadas',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.productId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Código: ${item.productId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          'Total cancelado: ${item.quantityLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                itemCount: tickets.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.paddingS),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return _CanceledTicketCard(
                    ticket: ticket,
                    isDark: isDark,
                    onTap: () {
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (_) =>
                            _CanceledTicketItemsDialog(ticket: ticket),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.sidebarDarkBackground
                    : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.darkDivider : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanceledTicketCard extends StatelessWidget {
  final PendingCanceledTicketModel ticket;
  final bool isDark;
  final VoidCallback onTap;

  const _CanceledTicketCard({
    required this.ticket,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatCanceledTicketTimestamp(ticket.timestamp);
    final itemsCount = ticket.canceledItems?.length ?? 0;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.description ?? 'Sin descripción',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$itemsCount artículo${itemsCount == 1 ? '' : 's'} cancelado${itemsCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _formatCanceledTicketTimestamp(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final dt = DateTime.parse(raw);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (_) {
    return raw;
  }
}

class _CanceledTicketItemsDialog extends StatelessWidget {
  final PendingCanceledTicketModel ticket;

  const _CanceledTicketItemsDialog({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ticket.canceledItems ?? const <CanceledItemModel>[];
    final timestamp = _formatCanceledTicketTimestamp(ticket.timestamp);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: isDark
                  ? AppColors.sidebarDarkBackground
                  : Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingM,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ítems cancelados',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ticket.description ?? 'Ticket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timestamp != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            timestamp,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Sin ítems',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimensions.paddingS),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isWeighted = item.isWeighted == 'S';
                        final quantityLabel = isWeighted
                            ? '${(item.weight ?? 0).toStringAsFixed(3)} kg'
                            : '${(item.quantity ?? 0).round()} unid.';

                        return Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusS,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkDivider
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.block,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName ?? 'Producto',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.productId != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Código: ${item.productId}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                quantityLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.sidebarDarkBackground
                    : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.darkDivider : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
