import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});
  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _stages = DealStage.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _buildHeader(context, crm),
        _buildSummary(crm),
        _buildTabs(),
        Expanded(child: _buildTabView(crm)),
      ]));
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
      child: Row(children: [
        const Icon(Icons.view_kanban_rounded, color: AppTheme.primaryPurple, size: 24),
        const SizedBox(width: 10),
        const Text('销售管线', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
          ),
          tooltip: '新增订单',
          onPressed: () => _showNewOrderSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummary(CrmProvider crm) {
    final active = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost);
    double pipeline = 0, weighted = 0;
    for (final d in active) {
      pipeline += d.amount;
      weighted += d.amount * d.probability / 100;
    }
    final completedDeals = crm.deals.where((d) => d.stage == DealStage.completed);
    double closedVal = 0;
    for (final d in completedDeals) { closedVal += d.amount; }
    final pendingShip = crm.orders.where((o) => o.status == 'confirmed').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Expanded(child: _summaryCard('管线总额', Formatters.currency(pipeline), AppTheme.primaryPurple)),
        const SizedBox(width: 6),
        Expanded(child: _summaryCard('加权期望', Formatters.currency(weighted), AppTheme.primaryBlue)),
        const SizedBox(width: 6),
        Expanded(child: _summaryCard('已成交', Formatters.currency(closedVal), AppTheme.success)),
        const SizedBox(width: 6),
        Expanded(child: _summaryCard('待出货', '$pendingShip', AppTheme.warning)),
      ]),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: AppTheme.primaryPurple,
      indicatorWeight: 3,
      labelColor: AppTheme.primaryPurple,
      unselectedLabelColor: AppTheme.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      tabAlignment: TabAlignment.start,
      tabs: _stages.map((s) {
        final count = Provider.of<CrmProvider>(context, listen: false).getDealsByStage(s).length;
        return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s.label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: _color(s).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: TextStyle(color: _color(s), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ]));
      }).toList(),
    );
  }

  Widget _buildTabView(CrmProvider crm) {
    return TabBarView(
      controller: _tabController,
      children: _stages.map((stage) {
        final deals = crm.getDealsByStage(stage);
        if (deals.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 12),
            Text('${stage.label} 暂无订单', style: const TextStyle(color: AppTheme.textSecondary)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: deals.length,
          itemBuilder: (context, index) => _dealCard(context, crm, deals[index]),
        );
      }).toList(),
    );
  }

  Widget _dealCard(BuildContext context, CrmProvider crm, Deal deal) {
    final color = _color(deal.stage);
    // Check if linked order is ready to ship
    final canShip = deal.orderId != null && (deal.stage == DealStage.ordered || deal.stage == DealStage.paid);
    SalesOrder? linkedOrder;
    if (deal.orderId != null) {
      final matches = crm.orders.where((o) => o.id == deal.orderId).toList();
      if (matches.isNotEmpty) linkedOrder = matches.first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (deal.orderId != null) ...[
            const Icon(Icons.receipt, color: AppTheme.accentGold, size: 14),
            const SizedBox(width: 4),
          ],
          Expanded(child: Text(deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
          PopupMenuButton<DealStage>(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.textSecondary, size: 18),
            color: AppTheme.cardBgLight,
            onSelected: (s) => crm.moveDealStage(deal.id, s),
            itemBuilder: (_) => _stages.where((s) => s != deal.stage).map((s) => PopupMenuItem(
              value: s,
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(s.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
              ]),
            )).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
            onPressed: () => crm.deleteDeal(deal.id),
          ),
        ]),
        const SizedBox(height: 4),
        Text(deal.contactName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        if (deal.description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(deal.description, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          // Status badge
          if (linkedOrder != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _orderStatusColor(linkedOrder.status).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(SalesOrder.statusLabel(linkedOrder.status), style: TextStyle(color: _orderStatusColor(linkedOrder.status), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('${deal.probability.toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: deal.probability / 100, backgroundColor: AppTheme.cardBgLight, valueColor: AlwaysStoppedAnimation(color), minHeight: 3),
        ),
        // Ship button
        if (canShip && linkedOrder != null && (linkedOrder.status == 'confirmed' || linkedOrder.status == 'draft')) ...[
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('出货 (扣库存)', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF74B9FF),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              crm.shipOrder(deal.orderId!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${deal.contactName} 订单已出货, 库存已扣减'),
                  backgroundColor: AppTheme.success,
                ));
              }
            },
          )),
        ],
      ]),
    );
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'draft': return AppTheme.textSecondary;
      case 'confirmed': return AppTheme.warning;
      case 'shipped': return const Color(0xFF74B9FF);
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  Color _color(DealStage s) {
    switch (s) {
      case DealStage.lead: return AppTheme.textSecondary;
      case DealStage.contacted: return AppTheme.primaryBlue;
      case DealStage.proposal: return AppTheme.primaryPurple;
      case DealStage.negotiation: return AppTheme.warning;
      case DealStage.ordered: return const Color(0xFF00CEC9);
      case DealStage.paid: return const Color(0xFF55EFC4);
      case DealStage.shipped: return const Color(0xFF74B9FF);
      case DealStage.inTransit: return const Color(0xFFA29BFE);
      case DealStage.received: return const Color(0xFF81ECEC);
      case DealStage.completed: return AppTheme.success;
      case DealStage.lost: return AppTheme.danger;
    }
  }

  // ========== New Order Sheet (unified) ==========
  void _showNewOrderSheet(BuildContext context, CrmProvider crm) {
    String? selectedContactId;
    String selectedContactName = '';
    final contacts = crm.allContacts;
    final products = crm.products;
    final selectedProducts = <String, int>{};
    String priceType = 'retail';
    final qtyControllers = <String, TextEditingController>{};

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          double total = 0;
          for (final entry in selectedProducts.entries) {
            final p = products.firstWhere((p) => p.id == entry.key);
            double up;
            switch (priceType) {
              case 'agent': up = p.agentPrice; break;
              case 'clinic': up = p.clinicPrice; break;
              default: up = p.retailPrice; break;
            }
            total += up * entry.value;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.add_shopping_cart, color: AppTheme.success, size: 20),
                  const SizedBox(width: 8),
                  const Text('新增订单', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                ]),
                // Reservation info
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 14),
                    SizedBox(width: 6),
                    Expanded(child: Text('下单 = 预定 (不扣库存), 出货时才扣库存', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11))),
                  ]),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedContactId,
                  decoration: const InputDecoration(labelText: '选择客户', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 20)),
                  dropdownColor: AppTheme.cardBgLight,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: contacts.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.company}', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setModalState(() {
                    selectedContactId = v;
                    selectedContactName = contacts.firstWhere((c) => c.id == v).name;
                  }),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('价格: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ...['agent', 'clinic', 'retail'].map((pt) {
                    final labels = {'agent': '代理', 'clinic': '诊所', 'retail': '零售'};
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(labels[pt]!, style: TextStyle(fontSize: 11, color: priceType == pt ? Colors.white : AppTheme.textPrimary)),
                        selected: priceType == pt,
                        onSelected: (_) => setModalState(() => priceType = pt),
                        selectedColor: AppTheme.primaryPurple, backgroundColor: AppTheme.cardBgLight,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ]),
                const SizedBox(height: 6),
                const Text('选择产品 (输入数量):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(shrinkWrap: true, children: products.map((p) {
                    final qty = selectedProducts[p.id] ?? 0;
                    double up;
                    switch (priceType) {
                      case 'agent': up = p.agentPrice; break;
                      case 'clinic': up = p.clinicPrice; break;
                      default: up = p.retailPrice; break;
                    }
                    final stock = crm.getProductStock(p.id);
                    final reserved = crm.getReservedStock(p.id);
                    final available = stock - reserved;
                    qtyControllers.putIfAbsent(p.id, () => TextEditingController(text: qty > 0 ? '$qty' : ''));
                    if (qty == 0 && qtyControllers[p.id]!.text == '0') { qtyControllers[p.id]!.text = ''; }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: qty > 0 ? AppTheme.primaryPurple.withValues(alpha: 0.08) : AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: qty > 0 ? Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)) : null,
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          Row(children: [
                            Text(Formatters.currency(up), style: const TextStyle(color: AppTheme.accentGold, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text('库存:$stock', style: TextStyle(color: stock <= 0 ? AppTheme.danger : AppTheme.textSecondary, fontSize: 10)),
                            if (reserved > 0) ...[
                              const SizedBox(width: 4),
                              Text('预定:$reserved', style: const TextStyle(color: AppTheme.warning, fontSize: 10)),
                            ],
                            const SizedBox(width: 4),
                            Text('可用:$available', style: TextStyle(color: available <= 0 ? AppTheme.danger : AppTheme.success, fontSize: 10, fontWeight: FontWeight.w600)),
                          ]),
                        ])),
                        SizedBox(
                          width: 60, height: 34,
                          child: TextField(
                            controller: qtyControllers[p.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '0', hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              filled: true, fillColor: AppTheme.cardBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            onChanged: (v) {
                              final newQty = int.tryParse(v) ?? 0;
                              setModalState(() {
                                if (newQty > 0) { selectedProducts[p.id] = newQty; } else { selectedProducts.remove(p.id); }
                              });
                            },
                          ),
                        ),
                      ]),
                    );
                  }).toList()),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Text('合计: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Text(Formatters.currency(total), style: const TextStyle(color: AppTheme.accentGold, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  icon: const Icon(Icons.bookmark_add, size: 18),
                  label: const Text('下单 (预定)'),
                  onPressed: (selectedContactId == null || selectedProducts.isEmpty) ? null : () {
                    final items = selectedProducts.entries.map((e) {
                      final p = products.firstWhere((p) => p.id == e.key);
                      double up;
                      switch (priceType) {
                        case 'agent': up = p.agentPrice; break;
                        case 'clinic': up = p.clinicPrice; break;
                        default: up = p.retailPrice; break;
                      }
                      return OrderItem(productId: p.id, productName: p.name, productCode: p.code, quantity: e.value, unitPrice: up, subtotal: up * e.value);
                    }).toList();
                    final order = SalesOrder(id: crm.generateId(), contactId: selectedContactId!, contactName: selectedContactName, items: items, totalAmount: total);
                    crm.createOrderWithDeal(order);
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('订单已预定: $selectedContactName ${Formatters.currency(total)} (出货时扣库存)'),
                        backgroundColor: AppTheme.success,
                      ));
                    }
                  },
                )),
                const SizedBox(height: 12),
              ]),
            ),
          );
        });
      },
    );
  }
}
