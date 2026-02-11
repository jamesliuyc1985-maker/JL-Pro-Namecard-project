import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final orders = crm.orders;
      final stats = crm.stats;
      return SafeArea(
        child: Column(children: [
          _buildHeader(context, crm),
          _buildSummary(stats),
          Expanded(child: orders.isEmpty ? _buildEmpty() : _buildOrderList(context, crm, orders)),
        ]),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Icon(Icons.receipt_long, color: AppTheme.accentGold, size: 24),
        const SizedBox(width: 10),
        const Text('销售管理', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: Colors.white, size: 20)),
          onPressed: () => _showNewOrderSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummary(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _statCard('订单总数', '${stats['totalOrders'] ?? 0}', Icons.receipt, AppTheme.primaryBlue)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('已完成', '${stats['completedOrders'] ?? 0}', Icons.check_circle, AppTheme.success)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('销售额', Formatters.currency((stats['salesTotal'] as num?)?.toDouble() ?? 0), Icons.monetization_on, AppTheme.accentGold)),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_cart_outlined, color: AppTheme.textSecondary, size: 48),
      SizedBox(height: 12),
      Text('暂无订单', style: TextStyle(color: AppTheme.textSecondary)),
      SizedBox(height: 4),
      Text('去产品页面创建订单', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]));
  }

  Widget _buildOrderList(BuildContext context, CrmProvider crm, List<SalesOrder> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _orderCard(context, crm, orders[index]),
    );
  }

  Widget _orderCard(BuildContext context, CrmProvider crm, SalesOrder order) {
    Color statusColor;
    switch (order.status) {
      case 'confirmed': statusColor = AppTheme.primaryBlue; break;
      case 'shipped': statusColor = AppTheme.warning; break;
      case 'completed': statusColor = AppTheme.success; break;
      case 'cancelled': statusColor = AppTheme.danger; break;
      default: statusColor = AppTheme.textSecondary; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(order.contactName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(SalesOrder.statusLabel(order.status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
            color: AppTheme.cardBgLight,
            onSelected: (s) {
              if (s == 'delete') {
                crm.deleteOrder(order.id);
              } else {
                order.status = s;
                order.updatedAt = DateTime.now();
                crm.updateOrder(order);
              }
            },
            itemBuilder: (_) => [
              if (order.status == 'draft') const PopupMenuItem(value: 'confirmed', child: Text('确认订单', style: TextStyle(color: AppTheme.textPrimary))),
              if (order.status == 'confirmed') const PopupMenuItem(value: 'shipped', child: Text('标记发货', style: TextStyle(color: AppTheme.textPrimary))),
              if (order.status == 'shipped') const PopupMenuItem(value: 'completed', child: Text('标记完成', style: TextStyle(color: AppTheme.textPrimary))),
              if (order.status != 'completed' && order.status != 'cancelled') const PopupMenuItem(value: 'cancelled', child: Text('取消订单', style: TextStyle(color: AppTheme.danger))),
              const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: AppTheme.danger))),
            ],
          ),
        ]),
        const SizedBox(height: 6),
        ...order.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.circle, size: 6, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.productName} x${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
            Text(Formatters.currency(item.subtotal), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
          ]),
        )),
        const Divider(color: AppTheme.cardBgLight, height: 16),
        Row(children: [
          Text(Formatters.dateShort(order.createdAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const Spacer(),
          Text('合计: ${Formatters.currency(order.totalAmount)}', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ]),
    );
  }

  void _showNewOrderSheet(BuildContext context, CrmProvider crm) {
    String? selectedContactId;
    String selectedContactName = '';
    final contacts = crm.allContacts;
    final products = crm.products;
    final selectedProducts = <String, int>{}; // productId -> quantity

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          double total = 0;
          for (final entry in selectedProducts.entries) {
            final p = products.firstWhere((p) => p.id == entry.key);
            total += p.retailPrice * entry.value;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('新建订单', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedContactId,
                  decoration: const InputDecoration(labelText: '选择客户'),
                  dropdownColor: AppTheme.cardBgLight,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: contacts.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.company}'))).toList(),
                  onChanged: (v) => setModalState(() {
                    selectedContactId = v;
                    selectedContactName = contacts.firstWhere((c) => c.id == v).name;
                  }),
                ),
                const SizedBox(height: 12),
                const Text('选择产品:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(shrinkWrap: true, children: products.map((p) {
                    final qty = selectedProducts[p.id] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: qty > 0 ? AppTheme.primaryPurple.withValues(alpha: 0.1) : AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                          Text(Formatters.currency(p.retailPrice), style: const TextStyle(color: AppTheme.accentGold, fontSize: 11)),
                        ])),
                        IconButton(icon: const Icon(Icons.remove, size: 18, color: AppTheme.textSecondary), onPressed: () {
                          setModalState(() { if (qty > 0) selectedProducts[p.id] = qty - 1; if (selectedProducts[p.id] == 0) selectedProducts.remove(p.id); });
                        }),
                        Text('$qty', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryPurple), onPressed: () {
                          setModalState(() => selectedProducts[p.id] = qty + 1);
                        }),
                      ]),
                    );
                  }).toList()),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('合计: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Text(Formatters.currency(total), style: const TextStyle(color: AppTheme.accentGold, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: (selectedContactId == null || selectedProducts.isEmpty) ? null : () {
                    final items = selectedProducts.entries.map((e) {
                      final p = products.firstWhere((p) => p.id == e.key);
                      return OrderItem(productId: p.id, productName: p.name, productCode: p.code, quantity: e.value, unitPrice: p.retailPrice, subtotal: p.retailPrice * e.value);
                    }).toList();
                    crm.addOrder(SalesOrder(id: crm.generateId(), contactId: selectedContactId!, contactName: selectedContactName, items: items, totalAmount: total));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('订单已创建 ${Formatters.currency(total)}'), backgroundColor: AppTheme.success));
                  },
                  child: const Text('创建订单'),
                )),
                const SizedBox(height: 16),
              ]),
            ),
          );
        });
      },
    );
  }
}
