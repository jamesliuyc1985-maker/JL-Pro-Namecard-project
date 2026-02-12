import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../models/contact.dart';
import '../models/product.dart';
import '../models/team.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});
  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 5, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); _searchCtrl.dispose(); super.dispose(); }

  List<Deal> _filtered(List<Deal> deals) {
    if (_searchQuery.isEmpty) return deals;
    final q = _searchQuery.toLowerCase();
    return deals.where((d) =>
      d.title.toLowerCase().contains(q) ||
      d.contactName.toLowerCase().contains(q) ||
      d.description.toLowerCase().contains(q) ||
      d.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _header(context, crm),
        if (_showSearch) _searchBar(),
        _summary(crm),
        _tabs(),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _allPipelineTab(crm),
          _stageTab(crm),
          _top20Tab(crm),
          _financeTab(crm),
          _staffSalesTab(crm),
        ])),
      ]));
    });
  }

  Widget _header(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('销售管线', style: TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Sales Pipeline & Finance', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
        ])),
        IconButton(
          icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: AppTheme.gold, size: 20),
          onPressed: () => setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); } }),
        ),
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

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索交易/客户/标签...', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: AppTheme.slate, size: 18),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: AppTheme.slate), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
          filled: true, fillColor: AppTheme.navyLight, contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _summary(CrmProvider crm) {
    final active = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost);
    double pipeline = 0, weighted = 0;
    for (final d in active) { pipeline += d.amount; weighted += d.amount * d.probability / 100; }
    final completedDeals = crm.deals.where((d) => d.stage == DealStage.completed);
    double closedVal = 0;
    for (final d in completedDeals) { closedVal += d.amount; }
    double collected = 0;
    for (final o in crm.orders.where((o) => o.status == 'completed')) { collected += o.totalAmount; }

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
        _kpi('已收款', Formatters.currency(collected), const Color(0xFF1ABC9C)),
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
      indicatorColor: AppTheme.gold, indicatorWeight: 2,
      labelColor: AppTheme.gold, unselectedLabelColor: AppTheme.slate,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      isScrollable: true, tabAlignment: TabAlignment.start,
      dividerColor: AppTheme.steel.withValues(alpha: 0.2),
      tabs: const [Tab(text: '全管线'), Tab(text: '按阶段'), Tab(text: 'TOP 20'), Tab(text: '财务收款'), Tab(text: '员工业绩')],
    );
  }

  // ====== TAB 1: 全管线视图 ======
  Widget _allPipelineTab(CrmProvider crm) {
    final allDeals = List<Deal>.from(crm.deals)..sort((a, b) => b.amount.compareTo(a.amount));
    final deals = _filtered(allDeals);
    if (deals.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? '暂无交易' : '未找到"$_searchQuery"', style: const TextStyle(color: AppTheme.slate)));

    return ListView.builder(
      padding: const EdgeInsets.all(12), itemCount: deals.length,
      itemBuilder: (ctx, i) => _dealCard(ctx, crm, deals[i]),
    );
  }

  // ====== TAB 2: 按阶段 ======
  Widget _stageTab(CrmProvider crm) {
    final stages = DealStage.values;
    return ListView(padding: const EdgeInsets.all(12), children: stages.map((stage) {
      final deals = _filtered(crm.getDealsByStage(stage));
      if (deals.isEmpty) return const SizedBox.shrink();
      double stageTotal = 0;
      for (final d in deals) { stageTotal += d.amount; }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => _drillStageDeals(stage, deals),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: _color(stage).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: _color(stage), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(stage.label, style: TextStyle(color: _color(stage), fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _color(stage).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('${deals.length}', style: TextStyle(color: _color(stage), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(Formatters.currency(stageTotal), style: TextStyle(color: _color(stage), fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: _color(stage), size: 16),
            ]),
          ),
        ),
        ...deals.take(3).map((d) => _miniDealCard(crm, d)),
        if (deals.length > 3) Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8),
          child: GestureDetector(
            onTap: () => _drillStageDeals(stage, deals),
            child: Text('查看全部 ${deals.length} 笔 →', style: const TextStyle(color: AppTheme.gold, fontSize: 11)),
          ),
        ),
        const SizedBox(height: 8),
      ]);
    }).toList());
  }

  // ====== TAB 3: TOP 20 交易排行 ======
  Widget _top20Tab(CrmProvider crm) {
    final sorted = List<Deal>.from(crm.deals.where((d) => d.stage != DealStage.lost))
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top20 = _filtered(sorted).take(20).toList();
    if (top20.isEmpty) return const Center(child: Text('暂无交易数据', style: TextStyle(color: AppTheme.slate)));

    double maxAmount = top20.isNotEmpty ? top20.first.amount : 1;
    if (maxAmount == 0) maxAmount = 1;

    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.emoji_events, color: AppTheme.gold, size: 20),
          const SizedBox(width: 8),
          Text('交易排行 TOP ${top20.length}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          Text('总计 ${Formatters.currency(top20.fold(0.0, (sum, d) => sum + d.amount))}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 12)),
        ]),
      ),
      ...top20.asMap().entries.map((e) {
        final i = e.key;
        final d = e.value;
        final c = _color(d.stage);
        final ratio = d.amount / maxAmount;
        final rankColor = i == 0 ? const Color(0xFFFFD700) : i == 1 ? const Color(0xFFC0C0C0) : i == 2 ? const Color(0xFFCD7F32) : AppTheme.slate;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: i < 3 ? Border.all(color: rankColor.withValues(alpha: 0.4)) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${i + 1}', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (d.isStarred) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: AppTheme.gold, size: 14)),
                  Expanded(child: Text(d.title, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
                Text('${d.contactName} | ${d.stage.label}', style: TextStyle(color: c, fontSize: 10)),
              ])),
              Text(Formatters.currency(d.amount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: ratio.clamp(0.02, 1.0), backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(c), minHeight: 3)),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // ====== TAB 4: 财务收款 ======
  Widget _financeTab(CrmProvider crm) {
    final orders = crm.orders;
    double totalAmount = 0, collected = 0, pending = 0;
    int collectedCount = 0, pendingCount = 0;
    for (final o in orders) {
      totalAmount += o.totalAmount;
      if (o.status == 'completed') { collected += o.totalAmount; collectedCount++; }
      else if (o.status != 'cancelled') { pending += o.totalAmount; pendingCount++; }
    }

    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
        child: Row(children: [
          _finKpi('订单总额', Formatters.currency(totalAmount), AppTheme.gold),
          _vd(),
          _finKpi('已收款', Formatters.currency(collected), AppTheme.success),
          _vd(),
          _finKpi('待收款', Formatters.currency(pending), AppTheme.warning),
          _vd(),
          _finKpi('回款率', totalAmount > 0 ? '${(collected / totalAmount * 100).toStringAsFixed(1)}%' : '0%', AppTheme.info),
        ]),
      ),
      const SizedBox(height: 12),
      const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('客户应收账款', style: TextStyle(color: AppTheme.offWhite, fontSize: 14, fontWeight: FontWeight.w600))),
      ..._customerReceivables(crm),
      const SizedBox(height: 12),
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('订单明细 (${orders.length})', style: const TextStyle(color: AppTheme.offWhite, fontSize: 14, fontWeight: FontWeight.w600))),
      ...orders.map((o) => _orderCard(crm, o)),
      const SizedBox(height: 30),
    ]);
  }

  List<Widget> _customerReceivables(CrmProvider crm) {
    final byCustomer = <String, Map<String, dynamic>>{};
    for (final o in crm.orders) {
      byCustomer.putIfAbsent(o.contactId, () => {'name': o.contactName, 'total': 0.0, 'collected': 0.0, 'pending': 0.0, 'count': 0});
      final c = byCustomer[o.contactId]!;
      c['total'] = (c['total'] as double) + o.totalAmount;
      c['count'] = (c['count'] as int) + 1;
      if (o.status == 'completed') { c['collected'] = (c['collected'] as double) + o.totalAmount; }
      else if (o.status != 'cancelled') { c['pending'] = (c['pending'] as double) + o.totalAmount; }
    }
    if (byCustomer.isEmpty) return [const Padding(padding: EdgeInsets.all(20), child: Text('暂无订单数据', style: TextStyle(color: AppTheme.slate)))];

    final sorted = byCustomer.entries.toList()..sort((a, b) => (b.value['pending'] as double).compareTo(a.value['pending'] as double));
    return sorted.map((e) {
      final c = e.value;
      final hasPending = (c['pending'] as double) > 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.navyLight, borderRadius: BorderRadius.circular(6),
          border: hasPending ? Border.all(color: AppTheme.warning.withValues(alpha: 0.3)) : null,
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['name'] as String, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 12)),
            Text('${c['count']}笔订单 | 已收${Formatters.currency(c['collected'] as double)}', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currency(c['pending'] as double), style: TextStyle(color: hasPending ? AppTheme.warning : AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(hasPending ? '待收款' : '已结清', style: TextStyle(color: hasPending ? AppTheme.warning : AppTheme.success, fontSize: 9)),
          ]),
        ]),
      );
    }).toList();
  }

  // 订单卡片 - 展示详细信息
  Widget _orderCard(CrmProvider crm, SalesOrder o) {
    final c = _orderColor(o.status);
    return GestureDetector(
      onTap: () => _showOrderDetail(o),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 44, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(o.contactName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(SalesOrder.statusLabel(o.status), style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${o.items.length}项产品 | ${SalesOrder.priceTypeLabel(o.priceType)} | ${Formatters.dateShort(o.createdAt)}', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Formatters.currency(o.totalAmount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
              if (o.status == 'confirmed' || o.status == 'shipped')
                GestureDetector(
                  onTap: () {
                    if (o.status == 'confirmed') { crm.shipOrder(o.id); }
                    else { o.status = 'completed'; o.updatedAt = DateTime.now(); crm.updateOrder(o); }
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(o.status == 'confirmed' ? '出货' : '确认收款', style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ]),
          // 产品明细
          const SizedBox(height: 8),
          ...o.items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 2),
            child: Row(children: [
              const Icon(Icons.inventory_2, color: AppTheme.slate, size: 12),
              const SizedBox(width: 6),
              Expanded(child: Text(item.productName, style: const TextStyle(color: AppTheme.silver, fontSize: 10), overflow: TextOverflow.ellipsis)),
              Text('x${item.quantity}', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
              const SizedBox(width: 8),
              Text(Formatters.currency(item.subtotal), style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
            ]),
          )),
          // 额外详情行
          if (o.shippingMethod.isNotEmpty || o.paymentTerms.isNotEmpty || o.deliveryAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Wrap(spacing: 8, children: [
                if (o.shippingMethod.isNotEmpty) _miniTag(Icons.local_shipping, SalesOrder.shippingLabel(o.shippingMethod), AppTheme.info),
                if (o.paymentTerms.isNotEmpty) _miniTag(Icons.payment, SalesOrder.paymentLabel(o.paymentTerms), AppTheme.warning),
                if (o.deliveryAddress.isNotEmpty) _miniTag(Icons.location_on, '已填地址', AppTheme.success),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _miniTag(IconData icon, String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 10),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: c, fontSize: 9)),
      ]),
    );
  }

  // 订单详情弹窗
  void _showOrderDetail(SalesOrder o) {
    final c = _orderColor(o.status);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Expanded(child: Text('订单详情', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(SalesOrder.statusLabel(o.status), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate, size: 18), onPressed: () => Navigator.pop(ctx)),
          ])),
          Flexible(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            _detailRow('订单编号', o.id.substring(0, 8).toUpperCase()),
            _detailRow('客户', o.contactName),
            if (o.contactCompany.isNotEmpty) _detailRow('公司', o.contactCompany),
            if (o.contactPhone.isNotEmpty) _detailRow('电话', o.contactPhone),
            _detailRow('价格类型', SalesOrder.priceTypeLabel(o.priceType)),
            if (o.dealStage.isNotEmpty) _detailRow('交易阶段', o.dealStage),
            _detailRow('创建日期', Formatters.dateShort(o.createdAt)),
            if (o.shippingMethod.isNotEmpty) _detailRow('配送方式', SalesOrder.shippingLabel(o.shippingMethod)),
            if (o.paymentTerms.isNotEmpty) _detailRow('付款条件', SalesOrder.paymentLabel(o.paymentTerms)),
            if (o.deliveryAddress.isNotEmpty) _detailRow('配送地址', o.deliveryAddress),
            if (o.expectedDeliveryDate != null) _detailRow('预计交付', Formatters.dateShort(o.expectedDeliveryDate!)),
            if (o.notes.isNotEmpty) _detailRow('备注', o.notes),
            const SizedBox(height: 12),
            const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('产品明细', style: TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.w600))),
            ...o.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.productName, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('单价: ${Formatters.currency(item.unitPrice)} | 数量: ${item.quantity}', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
                ])),
                Text(Formatters.currency(item.subtotal), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
            const Divider(color: AppTheme.steel, height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('合计: ', style: TextStyle(color: AppTheme.slate, fontSize: 14)),
              Text(Formatters.currency(o.totalAmount), style: const TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
          ])),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 11))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12))),
      ]),
    );
  }

  Widget _finKpi(String label, String val, Color c) => Expanded(child: Column(children: [
    FittedBox(child: Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13))),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
  ]));

  // ====== TAB 5: 员工业绩 ======
  Widget _staffSalesTab(CrmProvider crm) {
    final members = crm.teamMembers;
    final memberSales = <String, Map<String, dynamic>>{};
    for (final m in members) {
      memberSales[m.id] = {'name': m.name, 'role': m.role, 'dealCount': 0, 'totalAmount': 0.0, 'closedAmount': 0.0, 'orderCount': 0};
    }
    for (final a in crm.assignments) {
      final ms = memberSales[a.memberId];
      if (ms == null) continue;
      final deals = crm.getDealsByContact(a.contactId);
      ms['dealCount'] = (ms['dealCount'] as int) + deals.length;
      for (final d in deals) {
        ms['totalAmount'] = (ms['totalAmount'] as double) + d.amount;
        if (d.stage == DealStage.completed) { ms['closedAmount'] = (ms['closedAmount'] as double) + d.amount; }
      }
      final orders = crm.getOrdersByContact(a.contactId);
      ms['orderCount'] = (ms['orderCount'] as int) + orders.length;
    }
    if (crm.assignments.isEmpty && members.isNotEmpty) {
      for (final d in crm.deals) {
        final ms = memberSales[members.first.id]!;
        ms['dealCount'] = (ms['dealCount'] as int) + 1;
        ms['totalAmount'] = (ms['totalAmount'] as double) + d.amount;
        if (d.stage == DealStage.completed) { ms['closedAmount'] = (ms['closedAmount'] as double) + d.amount; }
      }
    }

    final sorted = memberSales.entries.toList()..sort((a, b) => (b.value['totalAmount'] as double).compareTo(a.value['totalAmount'] as double));
    double maxAmount = 1;
    for (final e in sorted) { final a = e.value['totalAmount'] as double; if (a > maxAmount) maxAmount = a; }

    return ListView(padding: const EdgeInsets.all(12), children: [
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('员工销售额统计', style: TextStyle(color: AppTheme.offWhite, fontSize: 14, fontWeight: FontWeight.w600))),
      ...sorted.map((e) {
        final s = e.value;
        final ratio = (s['totalAmount'] as double) / maxAmount;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text((s['name'] as String).isNotEmpty ? (s['name'] as String)[0] : '?', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] as String, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${TeamMember.roleLabel(s['role'] as String)} | ${s['dealCount']}笔交易 | ${s['orderCount']}笔订单', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Formatters.currency(s['totalAmount'] as double), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('成交${Formatters.currency(s['closedAmount'] as double)}', style: const TextStyle(color: AppTheme.success, fontSize: 9)),
              ]),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: ratio.clamp(0.02, 1.0), backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation(AppTheme.gold), minHeight: 3)),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // ====== Deal Card - 阶段切换后立即更新 ======
  Widget _dealCard(BuildContext context, CrmProvider crm, Deal deal) {
    final c = _color(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: deal.isStarred ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.steel.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(deal.stage.label, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          if (deal.isStarred) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: AppTheme.gold, size: 14)),
          Expanded(child: Text(deal.title, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
          PopupMenuButton<DealStage>(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.slate, size: 16),
            color: AppTheme.navyMid,
            onSelected: (s) async {
              // 立即更新本地UI
              await crm.moveDealStage(deal.id, s);
              setState(() {}); // 强制刷新当前页面
            },
            itemBuilder: (_) => DealStage.values.where((s) => s != deal.stage).map((s) => PopupMenuItem(value: s,
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(s.label, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12)),
              ]))).toList(),
          ),
        ]),
        Text(deal.contactName, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
        if (deal.description.isNotEmpty) Text(deal.description, style: const TextStyle(color: AppTheme.slate, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          if (deal.tags.isNotEmpty) ...deal.tags.take(2).map((t) => Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: AppTheme.steel.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
            child: Text(t, style: const TextStyle(color: AppTheme.slate, fontSize: 8)),
          )),
          Text('${deal.probability.toInt()}%', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: deal.probability / 100, backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(c), minHeight: 2)),
      ]),
    );
  }

  Widget _miniDealCard(CrmProvider crm, Deal deal) {
    final c = _color(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        if (deal.isStarred) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: AppTheme.gold, size: 12)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(deal.title, style: const TextStyle(color: AppTheme.offWhite, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          Text(deal.contactName, style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
        ])),
        Text(Formatters.currency(deal.amount), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  void _drillStageDeals(DealStage stage, List<Deal> deals) {
    final crm = context.read<CrmProvider>();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _color(stage), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('${stage.label} (${deals.length})', style: const TextStyle(color: AppTheme.offWhite, fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate, size: 18), onPressed: () => Navigator.pop(ctx)),
          ])),
          Flexible(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12),
            children: deals.map((d) => _dealCard(ctx, crm, d)).toList())),
        ]),
      ),
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

  // ========== New Order Sheet - 增强版 ==========
  void _showNewOrderSheet(BuildContext context, CrmProvider crm) {
    String? selectedContactId;
    String selectedContactName = '';
    String selectedContactCompany = '';
    String selectedContactPhone = '';
    final contacts = crm.allContacts;
    final products = crm.products;
    final selectedProducts = <String, int>{};
    String priceType = 'retail';
    String selectedStage = 'ordered';
    String shippingMethod = '';
    String paymentTerms = '';
    DateTime? expectedDate;
    final qtyControllers = <String, TextEditingController>{};
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

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
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('新增订单', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 6),
              Flexible(child: ListView(shrinkWrap: true, children: [
                // 选择客户
                DropdownButtonFormField<String>(
                  value: selectedContactId,
                  decoration: const InputDecoration(labelText: '选择客户', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  items: contacts.map((c) {
                    final relLabel = c.myRelation.isMedChannel ? ' [${c.myRelation.label}]' : '';
                    return DropdownMenuItem(value: c.id, child: Text('${c.name}$relLabel - ${c.company}', style: const TextStyle(fontSize: 11)));
                  }).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedContactId = v;
                      final contact = contacts.firstWhere((c) => c.id == v);
                      selectedContactName = contact.name;
                      selectedContactCompany = contact.company;
                      selectedContactPhone = contact.phone;
                      // 根据业务关系自动匹配价格
                      if (contact.myRelation == MyRelationType.agent) priceType = 'agent';
                      else if (contact.myRelation == MyRelationType.clinic) priceType = 'clinic';
                      else if (contact.myRelation == MyRelationType.retailer) priceType = 'retail';
                    });
                  },
                ),
                const SizedBox(height: 8),

                // 业务关系 → 价格类型 (自动匹配但可手动修改)
                const Text('价格类型', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: ['agent', 'clinic', 'retail'].map((pt) {
                  final labels = {'agent': '代理', 'clinic': '诊所', 'retail': '零售'};
                  final sel = priceType == pt;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                    label: Text(labels[pt]!, style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => priceType = pt),
                    selectedColor: AppTheme.gold, backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                  ));
                }).toList()),
                const SizedBox(height: 8),

                // 交易阶段选择
                const Text('交易阶段', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: DealStage.values.where((s) => s != DealStage.lost).map((s) {
                  final sel = selectedStage == s.name;
                  return ChoiceChip(
                    label: Text(s.label, style: TextStyle(fontSize: 9, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => selectedStage = s.name),
                    selectedColor: _color(s), backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                  );
                }).toList()),
                const SizedBox(height: 8),

                // 产品列表
                const Text('选择产品', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                ...products.map((p) {
                  final qty = selectedProducts[p.id] ?? 0;
                  double up;
                  switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
                  final stock = crm.getProductStock(p.id);
                  qtyControllers.putIfAbsent(p.id, () => TextEditingController(text: qty > 0 ? '$qty' : ''));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: qty > 0 ? AppTheme.gold.withValues(alpha: 0.06) : AppTheme.navyMid,
                      borderRadius: BorderRadius.circular(6),
                      border: qty > 0 ? Border.all(color: AppTheme.gold.withValues(alpha: 0.3)) : null,
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: const TextStyle(color: AppTheme.offWhite, fontSize: 11, fontWeight: FontWeight.w500)),
                        Row(children: [
                          Text(Formatters.currency(up), style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text('库存:$stock', style: TextStyle(color: stock <= 0 ? AppTheme.danger : AppTheme.slate, fontSize: 9)),
                        ]),
                      ])),
                      SizedBox(width: 52, height: 30, child: TextField(
                        controller: qtyControllers[p.id], keyboardType: TextInputType.number, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(hintText: '0', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          filled: true, fillColor: AppTheme.navyLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                        onChanged: (v) { final n = int.tryParse(v) ?? 0; set(() { if (n > 0) selectedProducts[p.id] = n; else selectedProducts.remove(p.id); }); },
                      )),
                    ]),
                  );
                }),
                const SizedBox(height: 8),

                // 配送方式
                const Text('配送方式', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: ['express', 'sea', 'air', 'pickup'].map((s) {
                  final sel = shippingMethod == s;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                    label: Text(SalesOrder.shippingLabel(s), style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => shippingMethod = s),
                    selectedColor: AppTheme.info, backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                  ));
                }).toList()),
                const SizedBox(height: 8),

                // 付款条件
                const Text('付款条件', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: ['prepaid', 'cod', 'net30', 'net60'].map((p) {
                  final sel = paymentTerms == p;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                    label: Text(SalesOrder.paymentLabel(p), style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => paymentTerms = p),
                    selectedColor: AppTheme.warning, backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                  ));
                }).toList()),
                const SizedBox(height: 8),

                // 预计交付日期
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) set(() => expectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: AppTheme.slate, size: 16),
                      const SizedBox(width: 8),
                      Text(expectedDate != null ? '预计交付: ${Formatters.dateShort(expectedDate!)}' : '选择预计交付日期', style: TextStyle(color: expectedDate != null ? AppTheme.offWhite : AppTheme.slate, fontSize: 11)),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),

                // 配送地址
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: '配送地址', labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true, fillColor: AppTheme.navyMid,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 6),

                // 备注
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: '备注', labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true, fillColor: AppTheme.navyMid,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                ),
              ])),
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
                  final dealStage = DealStage.values.firstWhere((s) => s.name == selectedStage, orElse: () => DealStage.ordered);
                  crm.createOrderWithDeal(SalesOrder(
                    id: crm.generateId(),
                    contactId: selectedContactId!,
                    contactName: selectedContactName,
                    contactCompany: selectedContactCompany,
                    contactPhone: selectedContactPhone,
                    items: items,
                    totalAmount: total,
                    priceType: priceType,
                    dealStage: dealStage.label,
                    shippingMethod: shippingMethod,
                    paymentTerms: paymentTerms,
                    deliveryAddress: addressCtrl.text,
                    notes: notesCtrl.text,
                    expectedDeliveryDate: expectedDate,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('创建订单'),
              )),
              const SizedBox(height: 12),
            ]),
          ),
        );
      }),
    );
  }
}
