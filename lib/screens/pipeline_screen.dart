import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
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

  // 4 tabs: 全管线 | 按阶段 | 财务收款 | 员工业绩
  @override
  void initState() { super.initState(); _tabController = TabController(length: 4, vsync: this); }
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
    // 财务: 已收款
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
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      dividerColor: AppTheme.steel.withValues(alpha: 0.2),
      tabs: const [Tab(text: '全管线'), Tab(text: '按阶段'), Tab(text: '财务收款'), Tab(text: '员工业绩')],
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

  // ====== TAB 3: 财务收款 ======
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
      // KPI Row
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
      // 按客户应收账款
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('客户应收账款', style: const TextStyle(color: AppTheme.offWhite, fontSize: 14, fontWeight: FontWeight.w600))),
      ..._customerReceivables(crm),
      const SizedBox(height: 12),
      // 订单列表
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

  Widget _orderCard(CrmProvider crm, SalesOrder o) {
    final c = _orderColor(o.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(o.contactName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w500, fontSize: 12)),
          Text('${o.items.length}项 | ${SalesOrder.statusLabel(o.status)}', style: TextStyle(color: c, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(Formatters.currency(o.totalAmount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
          if (o.status == 'confirmed' || o.status == 'shipped')
            GestureDetector(
              onTap: () {
                if (o.status == 'confirmed') { crm.shipOrder(o.id); }
                else {
                  // Mark as completed (collected)
                  o.status = 'completed';
                  o.updatedAt = DateTime.now();
                  crm.updateOrder(o);
                }
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
    );
  }

  Widget _finKpi(String label, String val, Color c) => Expanded(child: Column(children: [
    FittedBox(child: Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13))),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
  ]));

  // ====== TAB 4: 员工业绩 ======
  Widget _staffSalesTab(CrmProvider crm) {
    final members = crm.teamMembers;
    // Calculate sales per team member (by assigned contacts → deals)
    final memberSales = <String, Map<String, dynamic>>{};
    for (final m in members) {
      memberSales[m.id] = {'name': m.name, 'role': m.role, 'dealCount': 0, 'totalAmount': 0.0, 'closedAmount': 0.0, 'orderCount': 0};
    }
    // Map: assigned contacts → deals
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
    // Also count deals by owner (if deal.contactName matches)
    // Fallback: distribute all deals proportionally if no assignments
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

  // ====== Shared ======
  Widget _dealCard(BuildContext context, CrmProvider crm, Deal deal) {
    final c = _color(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(deal.stage.label, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(deal.title, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
          PopupMenuButton<DealStage>(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.slate, size: 16),
            color: AppTheme.navyMid,
            onSelected: (s) => crm.moveDealStage(deal.id, s),
            itemBuilder: (_) => DealStage.values.where((s) => s != deal.stage).map((s) => PopupMenuItem(value: s,
              child: Text(s.label, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12)))).toList(),
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
                value: selectedContactId,
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
