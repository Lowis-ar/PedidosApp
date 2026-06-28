import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/coupon_controller.dart';
import '../../models/coupon_model.dart';
import '../../models/loyalty_model.dart';
import '../../utils/colors.dart';
import '../../utils/app_snackbar.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Get.find<CouponController>().loadLoyaltyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Programa de Fidelidad',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: GetBuilder<CouponController>(builder: (controller) {
        if (controller.isLoadingLoyalty && controller.loyaltyProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.loyaltyProfile;

        return Column(
          children: [
            // ── Points card ─────────────────────────────────────
            _buildPointsCard(profile),
            // ── Tabs ────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.mainColor,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: AppColors.mainColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Historial de Puntos'),
                  Tab(text: 'Mis Cupones'),
                ],
              ),
            ),
            // ── Tab content ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionsTab(controller),
                  _buildCouponsTab(controller),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPointsCard(LoyaltyProfile? profile) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.mainColor, AppColors.mainColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tus Puntos',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${profile?.loyaltyPoints ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Milestone progress
          if (profile?.nextMilestone != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  profile?.currentMilestone?.name ?? 'Inicio',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  profile?.nextMilestone?.name ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: profile?.progress ?? 0,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Te faltan ${(profile!.nextMilestone!.pointsRequired - profile.lifetimePoints).clamp(0, 999999)} puntos para ${profile.nextMilestone!.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ] else if (profile?.currentMilestone != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('${profile!.currentMilestone!.name} alcanzado',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Lifetime points
          Text(
            'Total histórico: ${profile?.lifetimePoints ?? 0} puntos',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(CouponController controller) {
    if (controller.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.grey.shade300, size: 64),
            const SizedBox(height: 12),
            Text('Sin transacciones aún',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Realiza pedidos para ganar puntos',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.mainColor,
      onRefresh: () => controller.getLoyaltyTransactions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.transactions.length,
        itemBuilder: (context, index) {
          final tx = controller.transactions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tx.isEarned
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tx.isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: tx.isEarned ? Colors.green.shade600 : Colors.red.shade400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        String titleText = tx.description ?? (tx.isEarned ? 'Puntos ganados' : 'Puntos usados');
                        
                        // El usuario indicó que el API envía el ID del pedido como el primer ID (tx.id) 
                        // en la tabla donde se archivan, pero ahora solicita que NO se muestre el ID
                        // al cliente en ninguna parte.
                        // Solo mostraremos "Puntos ganados por pedido" si tenemos un orderId asociado.
                        int? correctOrderId = tx.id ?? tx.orderId;
                        
                        if (correctOrderId != null && correctOrderId > 0) {
                          titleText = '${tx.isEarned ? 'Puntos ganados' : 'Puntos usados'} por pedido';
                        }
                        
                        return Text(titleText,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14));
                      }),
                      if (tx.createdAt != null)
                        Text(_formatDate(tx.createdAt!),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Text(
                  '${tx.isEarned ? '+' : ''}${tx.points ?? 0}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tx.isEarned ? Colors.green.shade600 : Colors.red.shade400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCouponsTab(CouponController controller) {
    if (controller.userCoupons.isEmpty) {
      return RefreshIndicator(
        color: AppColors.mainColor,
        onRefresh: () => controller.getUserCoupons(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: controller.isLoadingCoupons 
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.grey.shade300, size: 64),
                    const SizedBox(height: 12),
                    Text('Sin cupones disponibles',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Acumula puntos para desbloquear recompensas',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.mainColor,
      onRefresh: () => controller.getUserCoupons(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.userCoupons.length,
        itemBuilder: (context, index) {
          final coupon = controller.userCoupons[index];
          return _buildCouponCard(coupon);
        },
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored strip
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: coupon.type == 'free_delivery'
                    ? Colors.blue.shade400
                    : coupon.type == 'percent'
                        ? Colors.orange.shade400
                        : Colors.green.shade400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          coupon.type == 'free_delivery'
                              ? Icons.local_shipping_outlined
                              : Icons.local_offer,
                          color: AppColors.mainColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(coupon.typeLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (coupon.description != null && coupon.description!.isNotEmpty)
                      Text(coupon.description!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Code pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(coupon.code ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.mainColor,
                                letterSpacing: 1.5,
                              )),
                        ),
                        // Copy button
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: coupon.code ?? ''));
                            AppSnackbar.success('Copiado', 'Código ${coupon.code} copiado al portapapeles');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.copy, color: Colors.grey.shade600, size: 18),
                          ),
                        ),
                      ],
                    ),
                    if (coupon.minOrderAmount != null && coupon.minOrderAmount! > 0) ...[
                      const SizedBox(height: 6),
                      Text('Pedido mínimo: \$${coupon.minOrderAmount!.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                    if (coupon.expiresAt != null) ...[
                      const SizedBox(height: 4),
                      Text('Expira: ${_formatDate(coupon.expiresAt!)}',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade300)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
