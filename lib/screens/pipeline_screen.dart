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
  void initState() { super.initState(); _tabController = TabController(length: _stages.length, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _header(context, crm),
        _summary(crm),
        _tabs(),
        Expanded(child: _tabView(crm)),
      ]));
    });
  }

  Widget _header(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('销售管线', style: TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Sales Pipeline', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
        ])),
        IconButton(
          tooltip: '新增订单',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.steel.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.add_shopping_cart, color: AppTheme.gold, size: 18),
          ),
          onPressed: () => _showNewOrderSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _summary(CrmProvider crm) {
    final active = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost);
    double pipeline = 0, weighted = 0;
    for (final d in active) { pipeline += d.amount; weighted += d.amount * d.probability / 100; }
    final completedDeals = crm.deals.where((d) => d.stage == DealStage.completed);
    double closedVal = 0;
    for (final d in completedDeals) { closedVal += d.amount; }
    final pendingShip = crm.orders.where((o) => o.status == 'confirmed').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: Row(children: [
        _kpi('管线总额', Formatters.currency(pipeline), AppTheme.gold),
        _vd(),
        _kpi('加权期望', Formatters.currency(weighted), AppTheme.info),
        _vd(),
        _kpi('已成交', Formatters.currency(closedVal), AppTheme.success),
        _vd(),
        _kpi('待出货', '$pendingShip', AppTheme.warning),
      ]),
    );
  }

  Widget _kpi(String label, String val, Color c) => Expanded(child: Column(children: [
    Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
  ]));
  Widget _vd() => Container(width: 1, height: 28, color: AppTheme.steel.withValues(alpha: 0.2));

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: AppTheme.gold,
      indicatorWeight: 2,
      labelColor: AppTheme.gold,
      unselectedLabelColor: AppTheme.slate,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      tabAlignment: TabAlignment.start,
      dividerColor: AppTheme.steel.withValues(alpha: 0.2),
      tabs: _stages.map((s) {
        final count = Provider.of<CrmProvider>(context, listen: false).getDealsByStage(s).length;
        return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s.label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: _color(s).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text('$count', style: TextStyle(color: _color(s), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ]));
      }).toList(),
    );
  }

  Widget _tabView(CrmProvider crm) {
    return TabBarView(controller: _tabController, children: _stages.map((stage) {
      final deals = crm.getDealsByStage(stage);
      if (deals.isEmpty) {
        return Center(child: Text('${stage.label} 暂无订单', style: const TextStyle(color: AppTheme.slate)));
      }
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: deals.length,
        itemBuilder: (ctx, i) => _dealCard(ctx, crm, deals[i]));
    }).toList());
  }

  Widget _dealCard(BuildContext context, CrmProvider crm, Deal deal) {
    final c = _color(deal.stage);
    final canShip = deal.orderId != null && (deal.stage == DealStage.ordered || deal.stage == DealStage.paid);
    SalesOrder? linkedOrder;
    if (deal.orderId != null) {
      final m = crm.orders.where((o) => o.id == deal.orderId).toList();
      if (m.isNotEmpty) linkedOrder = m.first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(deal.title, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13))),
          PopupMenuButton<DealStage>(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.slate, size: 16),
            color: AppTheme.navyMid,
            onSelected: (s) => crm.moveDealStage(deal.id, s),
            itemBuilder: (_) => _stages.where((s) => s != deal.stage).map((s) => PopupMenuItem(value: s,
              child: Text(s.label, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12)))).toList(),
          ),
          GestureDetector(
            onTap: () => crm.deleteDeal(deal.id),
            child: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
          ),
        ]),
        Text(deal.contactName, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
        if (deal.description.isNotEmpty) Text(deal.description, style: const TextStyle(color: AppTheme.slate, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          if (linkedOrder != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _orderColor(linkedOrder.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(SalesOrder.statusLabel(linkedOrder.status), style: TextStyle(color: _orderColor(linkedOrder.status), fontSize: 9)),
            ),
            const SizedBox(width: 6),
          ],
          Text('${deal.probability.toInt()}%', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: deal.probability / 100, backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(c), minHeight: 2)),
        if (canShip && linkedOrder != null && (linkedOrder.status == 'confirmed' || linkedOrder.status == 'draft')) ...[
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 32, child: ElevatedButton(
            onPressed: () {
              crm.shipOrder(deal.orderId!);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${deal.contactName} 已出货'), backgroundColor: AppTheme.success));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.info, padding: EdgeInsets.zero),
            child: const Text('出货 (扣库存)', style: TextStyle(fontSize: 11)),
          )),
        ],
      ]),
    );
  }

  Color _orderColor(String s) {
    switch (s) { case 'draft': return AppTheme.slate; case 'confirmed': return AppTheme.warning; case 'shipped': return AppTheme.info; case 'completed': return AppTheme.success; case 'cancelled': return AppTheme.danger; default: return AppTheme.slate; }
  }

  Color _color(DealStage s) {
    switch (s) {
      case DealStage.lead: return AppTheme.slate;
      case DealStage.contacted: return AppTheme.info;
      case DealStage.proposal: return const Color(0xFF9B59B6);
      case DealStage.negotiation: return AppTheme.warning;
      case DealStage.ordered: return const Color(0xFF1ABC9C);
      case DealStage.paid: return AppTheme.success;
      case DealStage.shipped: return AppTheme.info;
      case DealStage.inTransit: return const Color(0xFF8E7CC3);
      case DealStage.received: return const Color(0xFF5DADE2);
      case DealStage.completed: return AppTheme.success;
      case DealStage.lost: return AppTheme.danger;
    }
  }

  // ========== New Order Sheet ==========
  void _showNewOrderSheet(BuildContext context, CrmProvider crm) {
    String? selectedContactId;
    String selectedContactName = '';
    final contacts = crm.allContacts;
    final products = crm.products;
    final selectedProducts = <String, int>{};
    String priceType = 'retail';
    final qtyControllers = <String, TextEditingController>{};

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        double total = 0;
        for (final e in selectedProducts.entries) {
          final p = products.firstWhere((p) => p.id == e.key);
          double up;
          switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
          total += up * e.value;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('新增订单', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
              ]),
              Text('下单 = 预定 (不扣库存), 出货时才扣', style: TextStyle(color: AppTheme.info.withValues(alpha: 0.8), fontSize: 10)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedContactId,
                decoration: const InputDecoration(labelText: '选择客户'),
                dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite),
                items: contacts.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.company}', style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => set(() { selectedContactId = v; selectedContactName = contacts.firstWhere((c) => c.id == v).name; }),
              ),
              const SizedBox(height: 8),
              Row(children: ['agent', 'clinic', 'retail'].map((pt) {
                final labels = {'agent': '代理', 'clinic': '诊所', 'retail': '零售'};
                final sel = priceType == pt;
                return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                  label: Text(labels[pt]!, style: TextStyle(fontSize: 11, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                  selected: sel, onSelected: (_) => set(() => priceType = pt),
                  selectedColor: AppTheme.gold, backgroundColor: AppTheme.navyMid,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                ));
              }).toList()),
              const SizedBox(height: 6),
              Flexible(child: ListView(shrinkWrap: true, children: products.map((p) {
                final qty = selectedProducts[p.id] ?? 0;
                double up;
                switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
                final stock = crm.getProductStock(p.id);
                qtyControllers.putIfAbsent(p.id, () => TextEditingController(text: qty > 0 ? '$qty' : ''));
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: qty > 0 ? AppTheme.gold.withValues(alpha: 0.06) : AppTheme.navyMid,
                    borderRadius: BorderRadius.circular(6),
                    border: qty > 0 ? Border.all(color: AppTheme.gold.withValues(alpha: 0.3)) : null,
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.w500)),
                      Row(children: [
                        Text(Formatters.currency(up), style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text('库存:$stock', style: TextStyle(color: stock <= 0 ? AppTheme.danger : AppTheme.slate, fontSize: 10)),
                      ]),
                    ])),
                    SizedBox(width: 56, height: 32, child: TextField(
                      controller: qtyControllers[p.id], keyboardType: TextInputType.number, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(hintText: '0', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        filled: true, fillColor: AppTheme.navyLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                      onChanged: (v) { final n = int.tryParse(v) ?? 0; set(() { if (n > 0) selectedProducts[p.id] = n; else selectedProducts.remove(p.id); }); },
                    )),
                  ]),
                );
              }).toList())),
              const SizedBox(height: 6),
              Row(children: [
                const Text('合计: ', style: TextStyle(color: AppTheme.slate, fontSize: 13)),
                Text(Formatters.currency(total), style: const TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: (selectedContactId == null || selectedProducts.isEmpty) ? null : () {
                  final items = selectedProducts.entries.map((e) {
                    final p = products.firstWhere((p) => p.id == e.key);
                    double up;
                    switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
                    return OrderItem(productId: p.id, productName: p.name, productCode: p.code, quantity: e.value, unitPrice: up, subtotal: up * e.value);
                  }).toList();
                  crm.createOrderWithDeal(SalesOrder(id: crm.generateId(), contactId: selectedContactId!, contactName: selectedContactName, items: items, totalAmount: total, priceType: priceType));
                  Navigator.pop(ctx);
                },
                child: const Text('下单 (预定)'),
              )),
              const SizedBox(height: 12),
            ]),
          ),
        );
      }),
    );
  }
}
