import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/models/delivery_order_model.dart';
import 'package:pedidosapp/utils/colors.dart';

enum _Period { day, week, month, all }

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _Period _selectedPeriod = _Period.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Get.isRegistered<DeliveryOrderController>()) {
        final ctrl = Get.find<DeliveryOrderController>();
        if (ctrl.historyOrders.isEmpty || ctrl.historyError) {
          ctrl.getHistory();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // â”€â”€ Filtrado por periodo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<DeliveryOrderModel> _filterByPeriod(List<DeliveryOrderModel> orders) {
    if (_selectedPeriod == _Period.all) return orders;
    final now = DateTime.now();
    return orders.where((o) {
      if (o.createdAt == null) return false;
      try {
        final dt = DateTime.parse(o.createdAt!).toLocal();
        switch (_selectedPeriod) {
          case _Period.day:
            return dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day;
          case _Period.week:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final start =
                DateTime(weekStart.year, weekStart.month, weekStart.day);
            return dt.isAfter(start.subtract(const Duration(seconds: 1)));
          case _Period.month:
            return dt.year == now.year && dt.month == now.month;
          case _Period.all:
            return true;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  double _sumEarnings(List<DeliveryOrderModel> orders) =>
      orders.fold(0.0, (s, o) => s + (o.deliveryFee ?? 0.0));

  String _periodLabel(_Period p) {
    switch (p) {
      case _Period.day:
        return 'Hoy';
      case _Period.week:
        return 'Semana';
      case _Period.month:
        return 'Mes';
      case _Period.all:
        return 'Todo';
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
    } catch (e) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.buttonBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: AppColors.mainBlackColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Historial de Ganancias',
          style: TextStyle(
            color: AppColors.mainBlackColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.paraColor),
            onPressed: () {
              if (Get.isRegistered<DeliveryOrderController>()) {
                Get.find<DeliveryOrderController>().getHistory();
              }
            },
          ),
        ],
      ),
      body: GetBuilder<DeliveryOrderController>(builder: (ctrl) {
        if (ctrl.historyError) return _buildErrorState(ctrl);

        final delivered = _filterByPeriod(ctrl.historyOrders
            .where((o) => o.orderStatus == 'delivered')
            .toList());
        final cancelled = _filterByPeriod(ctrl.historyOrders
            .where((o) =>
                o.orderStatus == 'cancelled' || o.orderStatus == 'canceled')
            .toList());
        final earned = _sumEarnings(delivered);

        return Column(
          children: [
            // â”€â”€ Hero earnings card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildEarningsHero(
              earned: earned,
              todayEarnings: ctrl.todayEarnings,
              totalAllTime: ctrl.totalEarnings,
              deliveredCount: delivered.length,
              cancelledCount: cancelled.length,
            ),
            // â”€â”€ Period filters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildPeriodFilter(),
            // â”€â”€ Tabs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.mainColor,
                indicatorWeight: 3,
                labelColor: AppColors.mainColor,
                unselectedLabelColor: AppColors.paraColor,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(text: 'Completados (${delivered.length})'),
                  Tab(text: 'Cancelados (${cancelled.length})'),
                  const Tab(text: 'Ganancias'),
                ],
              ),
            ),
            // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(delivered, isDelivered: true),
                  _buildOrderList(cancelled, isDelivered: false),
                  _buildEarningsTab(
                    delivered: delivered,
                    totalAllTime: ctrl.totalEarnings,
                    todayEarnings: ctrl.todayEarnings,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  EARNINGS HERO HEADER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildEarningsHero({
    required double earned,
    required double todayEarnings,
    required double totalAllTime,
    required int deliveredCount,
    required int cancelledCount,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main amount + today pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ganancias · ${_periodLabel(_selectedPeriod)}',
                      style: TextStyle(
                        color: AppColors.paraColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${earned.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Today badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.mainColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hoy',
                      style: TextStyle(
                          color: AppColors.mainColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '\$${todayEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: AppColors.titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini stats row
          Row(
            children: [
              _miniStat(Icons.check_circle_outline_rounded,
                  '$deliveredCount', 'Entregas', AppColors.mainColor),
              const SizedBox(width: 10),
              _miniStat(Icons.cancel_outlined, '$cancelledCount',
                  'Cancelados', AppColors.iconColor2),
              const SizedBox(width: 10),
              _miniStat(Icons.account_balance_wallet_outlined,
                  '\$${totalAllTime.toStringAsFixed(0)}', 'Histórico',
                  AppColors.yellowColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                        color: AppColors.paraColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  PERIOD FILTER CHIPS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildPeriodFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded,
              color: AppColors.paraColor, size: 16),
          const SizedBox(width: 8),
          ..._Period.values.map((p) {
            final selected = _selectedPeriod == p;
            return GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.mainColor
                      : AppColors.buttonBackgroundColor,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected
                        ? AppColors.mainColor
                        : AppColors.textColor,
                  ),
                ),
                child: Text(
                  _periodLabel(p),
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.paraColor,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  ORDER LIST
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildOrderList(List<DeliveryOrderModel> orders,
      {required bool isDelivered}) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        isDelivered
            ? Icons.delivery_dining_rounded
            : Icons.remove_circle_outline,
        isDelivered
            ? 'Sin entregas en este periodo'
            : 'Sin cancelaciones en este periodo',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, i) =>
          _buildOrderCard(orders[i], isDelivered: isDelivered),
    );
  }

  Widget _buildOrderCard(DeliveryOrderModel order,
      {required bool isDelivered}) {
    final accentColor =
        isDelivered ? AppColors.mainColor : AppColors.iconColor2;
    final fee = order.deliveryFee ?? 0.0;
    final total = order.total ?? 0.0;
    final discount = order.discountAmount ?? 0.0;
    final subtotal = total + discount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Status bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                  isDelivered ? Icons.check_circle : Icons.cancel,
                  color: accentColor,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  isDelivered ? 'Entregado' : 'Cancelado',
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                      color: AppColors.paraColor, fontSize: 11),
                ),
              ],
            ),
          ),
          // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${order.id}',
                        style: TextStyle(
                            color: AppColors.mainBlackColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                      if (order.restaurant?.name != null)
                        _iconRow(
                            Icons.store_outlined,
                            order.restaurant!.name!,
                            AppColors.paraColor),
                      if (order.deliveryAddress != null)
                        _iconRow(
                            Icons.location_on_outlined,
                            order.deliveryAddress!,
                            AppColors.iconColor2,
                            maxLines: 2),
                    ],
                  ),
                ),
                if (isDelivered && fee > 0) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Tu ganancia',
                          style: TextStyle(
                              color: AppColors.paraColor, fontSize: 10)),
                      Text(
                        '\$${fee.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: AppColors.mainColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // â”€â”€ Price breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.buttonBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (subtotal > 0)
                  _priceRow('Subtotal',
                      '\$${subtotal.toStringAsFixed(2)}',
                      AppColors.paraColor),
                if (discount > 0)
                  _priceRow('Descuento',
                      '-\$${discount.toStringAsFixed(2)}',
                      AppColors.iconColor2),
                if (total > 0)
                  _priceRow('Total pagado',
                      '\$${total.toStringAsFixed(2)}',
                      AppColors.titleColor,
                      bold: true),
                if (fee > 0 && isDelivered) ...[
                  Divider(
                      height: 16,
                      color: AppColors.textColor.withValues(alpha: 0.4)),
                  _priceRow(
                    'Tu pago de entrega',
                    '+\$${fee.toStringAsFixed(2)}',
                    AppColors.mainColor,
                    bold: true,
                    icon: Icons.payments_outlined,
                  ),
                ],
              ],
            ),
          ),
          // â”€â”€ Items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (order.details != null && order.details!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artículos',
                      style: TextStyle(
                          color: AppColors.paraColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...order.details!.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${item.quantity ?? 1}',
                                style: TextStyle(
                                    color: AppColors.mainColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.name ?? 'Producto',
                                style: TextStyle(
                                    color: AppColors.titleColor,
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (item.price != null)
                            Text('\$${item.price}',
                                style: TextStyle(
                                    color: AppColors.paraColor,
                                    fontSize: 12)),
                        ]),
                      )),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, String text, Color color,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.paraColor, fontSize: 12),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, Color amountColor,
      {bool bold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: amountColor, size: 13),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: bold ? AppColors.titleColor : AppColors.paraColor,
                    fontSize: 12,
                    fontWeight:
                        bold ? FontWeight.w600 : FontWeight.w400)),
          ),
          Text(amount,
              style: TextStyle(
                  color: amountColor,
                  fontSize: 12,
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  EARNINGS TAB
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildEarningsTab({
    required List<DeliveryOrderModel> delivered,
    required double totalAllTime,
    required double todayEarnings,
  }) {
    final filteredEarnings = _sumEarnings(delivered);
    final avg =
        delivered.isEmpty ? 0.0 : filteredEarnings / delivered.length;

    final Map<int, double> byDay = {};
    for (final o in delivered) {
      if (o.createdAt == null) continue;
      try {
        final dt = DateTime.parse(o.createdAt!).toLocal();
        byDay[dt.weekday] =
            (byDay[dt.weekday] ?? 0) + (o.deliveryFee ?? 0);
      } catch (e) {
        // skip
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _earningsCard(
                  'Periodo', '\$${filteredEarnings.toStringAsFixed(2)}',
                  Icons.calendar_today_rounded, AppColors.mainColor),
              const SizedBox(width: 12),
              _earningsCard(
                  'Histórico', '\$${totalAllTime.toStringAsFixed(2)}',
                  Icons.account_balance_wallet_rounded,
                  AppColors.yellowColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _earningsCard('Promedio', '\$${avg.toStringAsFixed(2)}',
                  Icons.trending_up_rounded, AppColors.iconColor1),
              const SizedBox(width: 12),
              _earningsCard('Entregas', '${delivered.length}',
                  Icons.delivery_dining_rounded, AppColors.iconColor2),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          if (byDay.isNotEmpty) ...[
            Text('Ganancias por día',
                style: TextStyle(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 12),
            _buildDayBars(byDay),
            const SizedBox(height: 20),
          ],
          // Breakdown list
          if (delivered.isNotEmpty) ...[
            Text('Desglose por entrega',
                style: TextStyle(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 10),
            ...delivered.map((o) => _earningsRow(o)),
          ],
          if (delivered.isEmpty)
            _buildEmptyState(Icons.payments_outlined,
                'Sin ganancias en este periodo'),
        ],
      ),
    );
  }

  Widget _earningsCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: AppColors.paraColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBars(Map<int, double> byDay) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final maxVal =
        byDay.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final dayNum = i + 1;
          final val = byDay[dayNum] ?? 0.0;
          final fraction = maxVal > 0 ? val / maxVal : 0.0;
          final isToday = DateTime.now().weekday == dayNum;
          final barColor = isToday
              ? AppColors.mainColor
              : AppColors.mainColor.withValues(alpha: 0.35);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (val > 0)
                Text('\$${val.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: isToday
                            ? AppColors.mainColor
                            : AppColors.paraColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                width: 26,
                height: 70 * fraction + (val > 0 ? 4 : 2),
                decoration: BoxDecoration(
                  color: val > 0 ? barColor : AppColors.textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(days[i],
                  style: TextStyle(
                      color: isToday
                          ? AppColors.mainColor
                          : AppColors.paraColor,
                      fontSize: 12,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400)),
            ],
          );
        }),
      ),
    );
  }

  Widget _earningsRow(DeliveryOrderModel order) {
    final fee = order.deliveryFee ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check,
                color: AppColors.mainColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orden #${order.id}',
                    style: TextStyle(
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(_formatDate(order.createdAt),
                    style: TextStyle(
                        color: AppColors.paraColor, fontSize: 11)),
              ],
            ),
          ),
          Text('+\$${fee.toStringAsFixed(2)}',
              style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  HELPERS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 60,
              color: AppColors.textColor.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(message,
              style: TextStyle(color: AppColors.paraColor, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorState(DeliveryOrderController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 64, color: AppColors.textColor),
            const SizedBox(height: 16),
            Text('Historial no disponible',
                style: TextStyle(
                    color: AppColors.titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'El historial de entregas no está disponible\npor ahora. Intenta más tarde.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.paraColor, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ctrl.getHistory(),
              icon: Icon(Icons.refresh, color: AppColors.mainColor),
              label: Text('Reintentar',
                  style: TextStyle(color: AppColors.mainColor)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.mainColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
