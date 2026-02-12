import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/team.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'contact_detail_screen.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});
  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 6, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _header(),
        if (_showSearch) _searchBarWidget(),
        _tabBar(),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _overviewTab(crm),
          _productionTab(crm),
          _inventoryTab(crm),
          _salesTab(crm),
          _teamTab(crm),
          _contactsTab(crm),
        ])),
      ]));
    });
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('综合统计', style: TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Analytics Dashboard', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
        ])),
        IconButton(
          icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: AppTheme.gold, size: 20),
          onPressed: () => setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); } }),
        ),
      ]),
    );
  }

  Widget _searchBarWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索产品/工厂/客户/团队...', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: AppTheme.slate, size: 18),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: AppTheme.slate), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
          filled: true, fillColor: AppTheme.navyLight, contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.gold,
        indicatorWeight: 2,
        labelColor: AppTheme.offWhite,
        unselectedLabelColor: AppTheme.slate,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        dividerColor: AppTheme.steel.withValues(alpha: 0.2),
        tabs: const [Tab(text: '总览', height: 30), Tab(text: '生产', height: 30), Tab(text: '库存', height: 30), Tab(text: '销售', height: 30), Tab(text: '团队', height: 30), Tab(text: '人脉', height: 30)],
      ),
    );
  }

  // === Shared widgets ===
  void _drill(String title, IconData icon, List<Widget> items) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(icon, color: AppTheme.gold, size: 18), const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: AppTheme.offWhite, fontSize: 15, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate, size: 18), onPressed: () => Navigator.pop(ctx)),
          ])),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Text('无数据', style: TextStyle(color: AppTheme.slate)))
          else Flexible(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [...items, const SizedBox(height: 16)])),
        ]),
      ),
    );
  }

  Widget _dItem(String title, String sub, {String? trail, Color tc = AppTheme.gold, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
        ])),
        if (trail != null) Text(trail, style: TextStyle(color: tc, fontWeight: FontWeight.bold, fontSize: 13)),
        if (onTap != null) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.chevron_right, color: AppTheme.slate, size: 14)),
      ]),
    ));
  }

  Widget _sec(String t) => Padding(padding: const EdgeInsets.only(bottom: 6, top: 4), child: Text(t, style: const TextStyle(color: AppTheme.offWhite, fontSize: 14, fontWeight: FontWeight.w600)));

  Widget _kpi(String label, String val, Color c, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(child: Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
      ]),
    ));
  }

  Widget _miniKpi(String l, String v, Color c) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
    child: Column(children: [
      Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
    ]),
  );

  Widget _summaryRow(List<_KpiData> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: Row(children: items.map((k) {
        final isLast = k == items.last;
        return Expanded(child: GestureDetector(
          onTap: k.onTap,
          child: Row(children: [
            Expanded(child: Column(children: [
              Text(k.value, style: TextStyle(color: k.color, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(k.label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
            ])),
            if (!isLast) Container(width: 1, height: 28, color: AppTheme.steel.withValues(alpha: 0.15)),
          ]),
        ));
      }).toList()),
    );
  }

  Color _stageColor(DealStage s) {
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

  // === TAB 1: Overview ===
  Widget _overviewTab(CrmProvider crm) {
    final stats = crm.stats;
    final prodStats = crm.productionStats;
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _sec('核心指标'),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.2,
        children: [
          _kpi('人脉总数', '${stats['totalContacts']}', AppTheme.info, () {}),
          _kpi('活跃交易', '${stats['activeDeals']}', AppTheme.warning, () {}),
          _kpi('管线总额', Formatters.currency(stats['pipelineValue'] as double), AppTheme.gold, () {}),
          _kpi('成交率', '${(stats['winRate'] as double).toStringAsFixed(1)}%', AppTheme.success, () {}),
          _kpi('产品数', '${stats['totalProducts']}', AppTheme.info, () {}),
          _kpi('订单数', '${stats['totalOrders']}', const Color(0xFF1ABC9C), () {}),
        ],
      ),
      const SizedBox(height: 12),
      _sec('人脉行业分布'),
      _industryPie(stats),
      const SizedBox(height: 12),
      _sec('管线阶段分布'),
      _pipelineBar(stats, crm),
      const SizedBox(height: 12),
      _sec('生产概况'),
      Row(children: [
        Expanded(child: _miniKpi('进行中', '${prodStats['activeOrders']}', AppTheme.info)),
        const SizedBox(width: 6),
        Expanded(child: _miniKpi('计划量', '${prodStats['totalPlannedQty']}', AppTheme.warning)),
        const SizedBox(width: 6),
        Expanded(child: _miniKpi('已完工', '${prodStats['completedOrders']}', AppTheme.success)),
        const SizedBox(width: 6),
        Expanded(child: _miniKpi('工厂数', '${prodStats['factoryCount']}', AppTheme.slate)),
      ]),
      const SizedBox(height: 30),
    ]);
  }

  // === TAB 2: Production ===
  Widget _productionTab(CrmProvider crm) {
    final orders = crm.productionOrders;
    final ps = crm.productionStats;
    final statusCounts = <String, int>{};
    for (final o in orders) { statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1; }
    final statusLabels = {'planned': '计划中', 'materials': '备料', 'producing': '生产中', 'quality': '质检', 'completed': '已完成', 'cancelled': '已取消'};
    final statusColors = {'planned': AppTheme.slate, 'materials': AppTheme.warning, 'producing': AppTheme.info, 'quality': const Color(0xFF9B59B6), 'completed': AppTheme.success, 'cancelled': AppTheme.danger};

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _summaryRow([
        _KpiData('生产单', '${orders.length}', AppTheme.info, () {}),
        _KpiData('进行中', '${ps['activeOrders']}', AppTheme.warning, () {}),
        _KpiData('已完工', '${ps['completedOrders']}', AppTheme.success, () {}),
        _KpiData('完成量', '${ps['totalCompletedQty']}', AppTheme.gold, () {}),
      ]),
      const SizedBox(height: 12),
      _sec('状态分布'),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
        child: Wrap(spacing: 6, runSpacing: 6, children: statusCounts.entries.map((e) {
          final c = statusColors[e.key] ?? AppTheme.slate;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('${statusLabels[e.key] ?? e.key}  ${e.value}', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
          );
        }).toList()),
      ),
      const SizedBox(height: 12),
      _sec('工厂产能'),
      ...crm.factories.map((f) {
        final fo = orders.where((o) => o.factoryId == f.id).toList();
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _miniKpi('总单', '${fo.length}', AppTheme.info)),
              const SizedBox(width: 6),
              Expanded(child: _miniKpi('进行中', '${fo.where((o) => o.status != 'completed' && o.status != 'cancelled').length}', AppTheme.warning)),
              const SizedBox(width: 6),
              Expanded(child: _miniKpi('已完成', '${fo.where((o) => o.status == 'completed').length}', AppTheme.success)),
            ]),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // === TAB 3: Inventory ===
  Widget _inventoryTab(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    final records = crm.inventoryRecords;
    int totalStock = 0, totalIn = 0, totalOut = 0;
    for (final s in stocks) totalStock += s.currentStock;
    for (final r in records) { if (r.type == 'in') totalIn += r.quantity; if (r.type == 'out') totalOut += r.quantity; }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _summaryRow([
        _KpiData('SKU', '${stocks.length}', AppTheme.info, () {}),
        _KpiData('总库存', '$totalStock', AppTheme.gold, () {}),
        _KpiData('总入库', '$totalIn', AppTheme.success, () {}),
        _KpiData('总出库', '$totalOut', AppTheme.danger, () {}),
      ]),
      const SizedBox(height: 12),
      _sec('各产品库存'),
      ...stocks.map((s) {
        final max = stocks.isEmpty ? 1 : stocks.map((x) => x.currentStock).fold(1, (a, b) => a > b ? a : b);
        final ratio = max > 0 ? s.currentStock / max : 0.0;
        final c = s.currentStock <= 0 ? AppTheme.danger : s.currentStock < 5 ? AppTheme.warning : AppTheme.success;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(6)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(s.productName, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              Text('${s.currentStock}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: ratio.clamp(0.02, 1.0), backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(c), minHeight: 4)),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // === TAB 4: Sales ===
  Widget _salesTab(CrmProvider crm) {
    final channelStats = crm.channelSalesStats;
    double totalSales = 0, completedSales = 0;
    int shippedCount = 0;
    for (final o in crm.orders) { totalSales += o.totalAmount; if (o.status == 'completed') completedSales += o.totalAmount; if (o.status == 'shipped') shippedCount++; }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _summaryRow([
        _KpiData('总订单', '${crm.orders.length}', AppTheme.info, () {}),
        _KpiData('总额', Formatters.currency(totalSales), AppTheme.gold, () {}),
        _KpiData('已成交', Formatters.currency(completedSales), AppTheme.success, () {}),
        _KpiData('待发', '$shippedCount', AppTheme.warning, () {}),
      ]),
      const SizedBox(height: 12),
      _sec('渠道销售对比'),
      Row(children: channelStats.entries.map((e) {
        final s = e.value;
        return Expanded(child: Container(
          margin: EdgeInsets.only(right: e.key != 'retail' ? 6 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['label'] as String, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Text(Formatters.currency(s['amount'] as double), style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${s['orders']}单', style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
          ]),
        ));
      }).toList()),
      const SizedBox(height: 12),
      _sec('交易排行 TOP 5'),
      ...crm.deals.where((d) => d.stage != DealStage.lost).toList().asMap().entries.where((e) => e.key < 5).map((e) {
        final d = (crm.deals.where((d) => d.stage != DealStage.lost).toList()..sort((a, b) => b.amount.compareTo(a.amount)))[e.key];
        return _dItem(d.title, '${d.contactName} | ${d.stage.label}', trail: Formatters.currency(d.amount));
      }),
      const SizedBox(height: 30),
    ]);
  }

  // === TAB 5: Team ===
  Widget _teamTab(CrmProvider crm) {
    final members = crm.teamMembers;
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _summaryRow([
        _KpiData('总成员', '${members.length}', AppTheme.info, () {}),
        _KpiData('活跃', '${members.where((m) => m.isActive).length}', AppTheme.success, () {}),
        _KpiData('总任务', '${crm.tasks.length}', AppTheme.warning, () {}),
        _KpiData('指派数', '${crm.assignments.length}', AppTheme.gold, () {}),
      ]),
      const SizedBox(height: 12),
      _sec('成员工作量'),
      ...members.map((m) {
        final tasks = crm.getTasksByAssignee(m.id);
        final assignments = crm.getAssignmentsByMember(m.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text(m.name.isNotEmpty ? m.name[0] : '?', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${TeamMember.roleLabel(m.role)} | 任务${tasks.length} | 人脉${assignments.length}', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
            ])),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // === TAB 6: Contacts ===
  Widget _contactsTab(CrmProvider crm) {
    final contacts = crm.allContacts;
    final relations = crm.relations;
    final hot = contacts.where((c) => c.strength == RelationshipStrength.hot).length;
    final warm = contacts.where((c) => c.strength == RelationshipStrength.warm).length;
    final cool = contacts.where((c) => c.strength == RelationshipStrength.cool).length;
    final cold = contacts.where((c) => c.strength == RelationshipStrength.cold).length;

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _summaryRow([
        _KpiData('总人脉', '${contacts.length}', AppTheme.info, () {}),
        _KpiData('关系网', '${relations.length}', AppTheme.gold, () {}),
        _KpiData('销售线索', '${crm.contactsWithSales.length}', AppTheme.warning, () {}),
      ]),
      const SizedBox(height: 12),
      _sec('热度分布'),
      Row(children: [
        Expanded(child: _miniKpi('核心', '$hot', AppTheme.danger)),
        const SizedBox(width: 6),
        Expanded(child: _miniKpi('密切', '$warm', AppTheme.warning)),
        const SizedBox(width: 6),
        Expanded(child: _miniKpi('一般', '$cool', AppTheme.info)),
        const SizedBox(width: 6),
        Expanded(child: _miniKpi('浅交', '$cold', AppTheme.slate)),
      ]),
      if (contacts.isNotEmpty) ...[
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: SizedBox(height: 8, child: Row(children: [
            if (hot > 0) Expanded(flex: hot, child: Container(color: AppTheme.danger)),
            if (warm > 0) Expanded(flex: warm, child: Container(color: AppTheme.warning)),
            if (cool > 0) Expanded(flex: cool, child: Container(color: AppTheme.info)),
            if (cold > 0) Expanded(flex: cold, child: Container(color: AppTheme.slate)),
          ]))),
      ],
      const SizedBox(height: 12),
      _sec('行业分布'),
      _industryPie(crm.stats),
      const SizedBox(height: 12),
      _sec('交易金额 TOP 5'),
      ..._topDealContacts(crm),
      const SizedBox(height: 30),
    ]);
  }

  List<Widget> _topDealContacts(CrmProvider crm) {
    final amounts = <String, double>{};
    final names = <String, String>{};
    for (final d in crm.deals) {
      if (d.stage == DealStage.lost) continue;
      amounts[d.contactId] = (amounts[d.contactId] ?? 0) + d.amount;
      names[d.contactId] = d.contactName;
    }
    final sorted = amounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList().asMap().entries.map((e) {
      final contact = crm.getContact(e.value.key);
      return _dItem(names[e.value.key] ?? '未知', contact != null ? '${contact.company} | ${contact.myRelation.label}' : '',
        trail: Formatters.currency(e.value.value),
        onTap: contact != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: e.value.key))) : null);
    }).toList();
  }

  // === Charts ===
  Widget _industryPie(Map<String, dynamic> stats) {
    final Map<Industry, int> ic = stats['industryCount'] as Map<Industry, int>;
    if (ic.isEmpty) return const SizedBox.shrink();
    final total = ic.values.fold(0, (a, b) => a + b);
    final entries = ic.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: SizedBox(height: 160, child: Row(children: [
        Expanded(flex: 3, child: PieChart(PieChartData(sectionsSpace: 1, centerSpaceRadius: 24,
          sections: entries.map((e) => PieChartSectionData(
            value: e.value.toDouble(), title: '${(e.value / total * 100).toStringAsFixed(0)}%',
            color: e.key.color, radius: 40,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          )).toList()))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.take(6).map((e) => Padding(padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Expanded(child: Text('${e.key.label} (${e.value})', style: const TextStyle(color: AppTheme.slate, fontSize: 10))),
            ]))).toList())),
      ])),
    );
  }

  Widget _pipelineBar(Map<String, dynamic> stats, CrmProvider crm) {
    final Map<DealStage, int> sc = stats['stageCount'] as Map<DealStage, int>;
    if (sc.isEmpty) return const SizedBox.shrink();
    final stages = DealStage.values.where((s) => s != DealStage.lost && (sc[s] ?? 0) > 0).toList();
    final maxVal = sc.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: SizedBox(height: 140, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: maxVal + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) { final i = v.toInt(); if (i < 0 || i >= stages.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 4), child: Text(stages[i].label, style: const TextStyle(color: AppTheme.slate, fontSize: 8))); })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        borderData: FlBorderData(show: false), gridData: const FlGridData(show: false),
        barGroups: stages.asMap().entries.map((e) => BarChartGroupData(x: e.key,
          barRods: [BarChartRodData(toY: (sc[e.value] ?? 0).toDouble(), color: _stageColor(e.value), width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))])).toList()))),
    );
  }
}

class _KpiData {
  final String label, value;
  final Color color;
  final VoidCallback onTap;
  _KpiData(this.label, this.value, this.color, this.onTap);
}
