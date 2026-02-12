import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/product.dart';
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildOverviewTab(crm),
              _buildProductionTab(crm),
              _buildInventoryTab(crm),
              _buildSalesTab(crm),
              _buildTeamTab(crm),
              _buildContactsTab(crm),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        Icon(Icons.analytics_rounded, color: AppTheme.accentGold, size: 24),
        SizedBox(width: 10),
        Text('综合统计', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicator: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: '总览', height: 32),
          Tab(text: '生产', height: 32),
          Tab(text: '库存', height: 32),
          Tab(text: '销售', height: 32),
          Tab(text: '团队', height: 32),
          Tab(text: '人脉', height: 32),
        ],
      ),
    );
  }

  // ========== 通用 Drilldown Sheet ==========
  void _showDrilldown(BuildContext context, String title, Color color, IconData icon, List<Widget> children) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          if (children.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Text('无数据', style: TextStyle(color: AppTheme.textSecondary)))
          else
            Flexible(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [...children, const SizedBox(height: 16)])),
        ]),
      ),
    );
  }

  Widget _drilldownItem(String title, String subtitle, Color color, {String? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Container(
            width: 6, height: 30,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ])),
          if (trailing != null)
            Text(trailing, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 16)],
        ]),
      ),
    );
  }

  // ========== TAB 1: 总览 ==========
  Widget _buildOverviewTab(CrmProvider crm) {
    final stats = crm.stats;
    final prodStats = crm.productionStats;
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      _sectionTitle('核心指标'),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1,
        children: [
          _kpiCard('人脉总数', '${stats['totalContacts']}', Icons.people, AppTheme.primaryBlue, () {
            _showDrilldown(context, '人脉总数 (${stats['totalContacts']})', AppTheme.primaryBlue, Icons.people,
              crm.allContacts.map((c) => _drilldownItem(c.name, '${c.company} | ${c.industry.label} | ${c.strength.label}', c.myRelation.color,
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
          }),
          _kpiCard('活跃交易', '${stats['activeDeals']}', Icons.handshake, AppTheme.warning, () {
            final active = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost).toList();
            _showDrilldown(context, '活跃交易 (${active.length})', AppTheme.warning, Icons.handshake,
              active.map((d) => _drilldownItem(d.title, '${d.contactName} | ${d.stage.label}', _stageColor(d.stage), trailing: Formatters.currency(d.amount))).toList());
          }),
          _kpiCard('管线总额', Formatters.currency(stats['pipelineValue'] as double), Icons.trending_up, AppTheme.accentGold, () {
            final active = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost).toList()
              ..sort((a, b) => b.amount.compareTo(a.amount));
            _showDrilldown(context, '管线总额明细', AppTheme.accentGold, Icons.trending_up,
              active.map((d) => _drilldownItem(d.title, '${d.contactName} | ${d.stage.label} | 概率${d.probability.toInt()}%', _stageColor(d.stage), trailing: Formatters.currency(d.amount))).toList());
          }),
          _kpiCard('成交率', '${(stats['winRate'] as double).toStringAsFixed(1)}%', Icons.pie_chart, AppTheme.success, () {
            final completed = crm.deals.where((d) => d.stage == DealStage.completed).toList();
            final lost = crm.deals.where((d) => d.stage == DealStage.lost).toList();
            _showDrilldown(context, '成交率明细', AppTheme.success, Icons.pie_chart, [
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('已成交 (${completed.length})', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13))),
              ...completed.map((d) => _drilldownItem(d.title, d.contactName, AppTheme.success, trailing: Formatters.currency(d.amount))),
              if (lost.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('已流失 (${lost.length})', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13))),
                ...lost.map((d) => _drilldownItem(d.title, d.contactName, AppTheme.danger, trailing: Formatters.currency(d.amount))),
              ],
            ]);
          }),
          _kpiCard('产品数', '${stats['totalProducts']}', Icons.science, AppTheme.primaryPurple, () {
            _showDrilldown(context, '产品列表 (${crm.products.length})', AppTheme.primaryPurple, Icons.science,
              crm.products.map((p) => _drilldownItem(p.name, '${ProductCategory.label(p.category)} | ${p.specification}', AppTheme.primaryPurple, trailing: Formatters.currency(p.retailPrice))).toList());
          }),
          _kpiCard('订单数', '${stats['totalOrders']}', Icons.receipt_long, const Color(0xFF00CEC9), () {
            _showDrilldown(context, '订单列表 (${crm.orders.length})', const Color(0xFF00CEC9), Icons.receipt_long,
              crm.orders.map((o) => _drilldownItem(o.id.substring(0, 8), '${o.contactName} | ${SalesOrder.statusLabel(o.status)}', const Color(0xFF00CEC9), trailing: Formatters.currency(o.totalAmount))).toList());
          }),
        ],
      ),
      const SizedBox(height: 16),
      _sectionTitle('人脉行业分布'),
      _buildIndustryPie(stats),
      const SizedBox(height: 16),
      _sectionTitle('管线阶段分布'),
      _buildPipelineBar(stats, crm),
      const SizedBox(height: 16),
      _sectionTitle('生产概况'),
      Row(children: [
        Expanded(child: _miniKpiTap('进行中', '${prodStats['activeOrders']}', const Color(0xFF00CEC9), () {
          final active = crm.productionOrders.where((o) => o.status != 'completed' && o.status != 'cancelled').toList();
          _showDrilldown(context, '进行中生产单 (${active.length})', const Color(0xFF00CEC9), Icons.precision_manufacturing,
            active.map((o) => _drilldownItem(o.productName, '${o.factoryName} | ${o.status} | 数量${o.quantity}', const Color(0xFF00CEC9))).toList());
        })),
        const SizedBox(width: 8),
        Expanded(child: _miniKpiTap('计划量', '${prodStats['totalPlannedQty']}', AppTheme.warning, () {
          _showDrilldown(context, '生产计划总量', AppTheme.warning, Icons.inventory,
            crm.productionOrders.map((o) => _drilldownItem(o.productName, '${o.factoryName} | ${o.status}', AppTheme.warning, trailing: '${o.quantity}')).toList());
        })),
        const SizedBox(width: 8),
        Expanded(child: _miniKpiTap('已完工', '${prodStats['completedOrders']}', AppTheme.success, () {
          final done = crm.productionOrders.where((o) => o.status == 'completed').toList();
          _showDrilldown(context, '已完工 (${done.length})', AppTheme.success, Icons.check_circle,
            done.map((o) => _drilldownItem(o.productName, '${o.factoryName} | 数量${o.quantity}', AppTheme.success)).toList());
        })),
        const SizedBox(width: 8),
        Expanded(child: _miniKpiTap('工厂数', '${prodStats['factoryCount']}', AppTheme.primaryPurple, () {
          _showDrilldown(context, '工厂列表 (${crm.factories.length})', AppTheme.primaryPurple, Icons.factory,
            crm.factories.map((f) => _drilldownItem(f.name, '${f.address} | ${f.representative}', AppTheme.primaryPurple)).toList());
        })),
      ]),
      const SizedBox(height: 30),
    ]);
  }

  // ========== TAB 2: 生产统计 ==========
  Widget _buildProductionTab(CrmProvider crm) {
    final prodStats = crm.productionStats;
    final orders = crm.productionOrders;
    final factories = crm.factories;

    final factoryStats = <String, Map<String, dynamic>>{};
    for (final f in factories) {
      final fOrders = orders.where((o) => o.factoryId == f.id).toList();
      int totalQty = 0, completedQty = 0;
      for (final o in fOrders) {
        totalQty += o.quantity;
        if (o.status == 'completed') completedQty += o.quantity;
      }
      factoryStats[f.id] = {
        'name': f.name, 'total': fOrders.length,
        'completed': fOrders.where((o) => o.status == 'completed').length,
        'active': fOrders.where((o) => o.status != 'completed' && o.status != 'cancelled').length,
        'totalQty': totalQty, 'completedQty': completedQty, 'orders': fOrders,
      };
    }

    final statusCounts = <String, int>{};
    for (final o in orders) { statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1; }

    final memberProdStats = <String, Map<String, dynamic>>{};
    for (final o in orders) {
      if (o.assigneeId.isEmpty) continue;
      memberProdStats.putIfAbsent(o.assigneeId, () => {'name': o.assigneeName, 'total': 0, 'active': 0, 'completed': 0, 'totalQty': 0});
      memberProdStats[o.assigneeId]!['total'] = (memberProdStats[o.assigneeId]!['total'] as int) + 1;
      memberProdStats[o.assigneeId]!['totalQty'] = (memberProdStats[o.assigneeId]!['totalQty'] as int) + o.quantity;
      if (o.status == 'completed') {
        memberProdStats[o.assigneeId]!['completed'] = (memberProdStats[o.assigneeId]!['completed'] as int) + 1;
      } else if (o.status != 'cancelled') {
        memberProdStats[o.assigneeId]!['active'] = (memberProdStats[o.assigneeId]!['active'] as int) + 1;
      }
    }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00CEC9), Color(0xFF0984E3)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _whiteKpiTap('生产单', '${orders.length}', () {
            _showDrilldown(context, '全部生产单 (${orders.length})', const Color(0xFF00CEC9), Icons.precision_manufacturing,
              orders.map((o) => _drilldownItem(o.productName, '${o.factoryName} | ${o.status} | 数量${o.quantity}', const Color(0xFF00CEC9))).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('进行中', '${prodStats['activeOrders']}', () {
            final active = orders.where((o) => o.status != 'completed' && o.status != 'cancelled').toList();
            _showDrilldown(context, '进行中 (${active.length})', AppTheme.warning, Icons.autorenew,
              active.map((o) => _drilldownItem(o.productName, '${o.factoryName} | ${o.status}', AppTheme.warning, trailing: '${o.quantity}')).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('已完工', '${prodStats['completedOrders']}', () {
            final done = orders.where((o) => o.status == 'completed').toList();
            _showDrilldown(context, '已完工 (${done.length})', AppTheme.success, Icons.check_circle,
              done.map((o) => _drilldownItem(o.productName, '${o.factoryName} | 数量${o.quantity}', AppTheme.success)).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('完成量', '${prodStats['totalCompletedQty']}', () {
            final done = orders.where((o) => o.status == 'completed').toList();
            _showDrilldown(context, '已完成产量明细', AppTheme.success, Icons.inventory,
              done.map((o) => _drilldownItem(o.productName, o.factoryName, AppTheme.success, trailing: '${o.quantity}')).toList());
          })),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionTitle('生产状态分布'),
      _buildStatusDistribution(statusCounts, orders),
      const SizedBox(height: 16),
      _sectionTitle('工厂产能统计'),
      ...factoryStats.entries.map((e) => _factoryStatCard(e.value)),
      if (memberProdStats.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionTitle('成员生产跟进'),
        ...memberProdStats.entries.map((e) => _memberProdCard(e.value)),
      ],
      const SizedBox(height: 30),
    ]);
  }

  Widget _memberProdCard(Map<String, dynamic> ps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text((ps['name'] as String).isNotEmpty ? (ps['name'] as String)[0] : '?',
            style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ps['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Row(children: [
            _tinyKpi('总单', '${ps['total']}', AppTheme.primaryBlue),
            const SizedBox(width: 6),
            _tinyKpi('进行', '${ps['active']}', AppTheme.warning),
            const SizedBox(width: 6),
            _tinyKpi('完成', '${ps['completed']}', AppTheme.success),
            const SizedBox(width: 6),
            _tinyKpi('总量', '${ps['totalQty']}', AppTheme.primaryPurple),
          ]),
        ])),
      ]),
    );
  }

  Widget _tinyKpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatusDistribution(Map<String, int> statusCounts, List<dynamic> orders) {
    final statusLabels = {'planned': '计划中', 'materials': '备料', 'producing': '生产中', 'quality': '质检', 'completed': '已完成', 'cancelled': '已取消'};
    final statusColors = {'planned': AppTheme.textSecondary, 'materials': AppTheme.warning, 'producing': AppTheme.primaryBlue, 'quality': AppTheme.primaryPurple, 'completed': AppTheme.success, 'cancelled': AppTheme.danger};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Wrap(spacing: 8, runSpacing: 8, children: statusCounts.entries.map((e) {
        final color = statusColors[e.key] ?? AppTheme.textSecondary;
        return GestureDetector(
          onTap: () {
            final filtered = orders.where((o) => o.status == e.key).toList();
            _showDrilldown(context, '${statusLabels[e.key] ?? e.key} (${filtered.length})', color, Icons.inventory,
              filtered.map((o) => _drilldownItem(o.productName, '${o.factoryName} | 数量${o.quantity}', color)).toList());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(statusLabels[e.key] ?? e.key, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('${e.value}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              Icon(Icons.open_in_new, size: 10, color: color.withValues(alpha: 0.5)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _factoryStatCard(Map<String, dynamic> fs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.factory, color: Color(0xFF00CEC9), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(fs['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _miniKpi('总单数', '${fs['total']}', AppTheme.primaryBlue)),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('进行中', '${fs['active']}', AppTheme.warning)),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('已完成', '${fs['completed']}', AppTheme.success)),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('总产量', '${fs['totalQty']}', AppTheme.primaryPurple)),
        ]),
      ]),
    );
  }

  // ========== TAB 3: 库存统计 ==========
  Widget _buildInventoryTab(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    final records = crm.inventoryRecords;
    int totalStock = 0;
    for (final s in stocks) { totalStock += s.currentStock; }
    int totalIn = 0, totalOut = 0;
    for (final r in records) {
      if (r.type == 'in') totalIn += r.quantity;
      if (r.type == 'out') totalOut += r.quantity;
    }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _whiteKpiTap('SKU数', '${stocks.length}', () {
            _showDrilldown(context, '产品SKU (${stocks.length})', AppTheme.primaryPurple, Icons.category,
              stocks.map((s) => _drilldownItem(s.productName, '当前库存', AppTheme.primaryPurple, trailing: '${s.currentStock}')).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('总库存', '$totalStock', () {
            _showDrilldown(context, '总库存明细', AppTheme.primaryBlue, Icons.inventory,
              stocks.map((s) => _drilldownItem(s.productName, '库存量', AppTheme.primaryBlue, trailing: '${s.currentStock}')).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('总入库', '$totalIn', () {
            final inRecords = records.where((r) => r.type == 'in').toList();
            _showDrilldown(context, '入库记录 (${inRecords.length})', AppTheme.success, Icons.arrow_downward,
              inRecords.map((r) => _drilldownItem(r.productName, r.reason, AppTheme.success, trailing: '+${r.quantity}')).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('总出库', '$totalOut', () {
            final outRecords = records.where((r) => r.type == 'out').toList();
            _showDrilldown(context, '出库记录 (${outRecords.length})', AppTheme.danger, Icons.arrow_upward,
              outRecords.map((r) => _drilldownItem(r.productName, r.reason, AppTheme.danger, trailing: '-${r.quantity}')).toList());
          })),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionTitle('各产品库存'),
      ...stocks.map((s) => _stockBar(s.productName, s.currentStock, stocks.isEmpty ? 1 : stocks.map((x) => x.currentStock).fold(1, (a, b) => a > b ? a : b))),
      const SizedBox(height: 16),
      _sectionTitle('最近库存变动'),
      ...records.take(10).map((r) => _inventoryRecordItem(r)),
      const SizedBox(height: 30),
    ]);
  }

  Widget _stockBar(String name, int qty, int maxQty) {
    final ratio = maxQty > 0 ? qty / maxQty : 0.0;
    final color = qty <= 0 ? AppTheme.danger : (qty < 50 ? AppTheme.warning : AppTheme.success);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Text('$qty', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio.clamp(0.02, 1.0), backgroundColor: AppTheme.cardBgLight, valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
        ),
      ]),
    );
  }

  Widget _inventoryRecordItem(dynamic r) {
    final isIn = r.type == 'in';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: (isIn ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: isIn ? AppTheme.success : AppTheme.danger, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.productName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(r.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ])),
        Text('${isIn ? '+' : '-'}${r.quantity}', style: TextStyle(color: isIn ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  // ========== TAB 4: 销售统计 ==========
  Widget _buildSalesTab(CrmProvider crm) {
    final channelStats = crm.channelSalesStats;
    final stageStats = crm.pipelineStageStats;
    double totalSales = 0, completedSales = 0;
    int totalOrders = crm.orders.length, shippedCount = 0;
    for (final o in crm.orders) {
      totalSales += o.totalAmount;
      if (o.status == 'completed') completedSales += o.totalAmount;
      if (o.status == 'shipped') shippedCount++;
    }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6348), Color(0xFFFF9F43)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _whiteKpiTap('总订单', '$totalOrders', () {
            _showDrilldown(context, '全部订单 ($totalOrders)', AppTheme.warning, Icons.receipt_long,
              crm.orders.map((o) => _drilldownItem(o.id.substring(0, 8), '${o.contactName} | ${SalesOrder.statusLabel(o.status)}', AppTheme.warning, trailing: Formatters.currency(o.totalAmount))).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('总额', Formatters.currency(totalSales), () {
            final sorted = crm.orders.toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
            _showDrilldown(context, '订单金额排行', AppTheme.accentGold, Icons.attach_money,
              sorted.map((o) => _drilldownItem(o.id.substring(0, 8), '${o.contactName} | ${SalesOrder.statusLabel(o.status)}', AppTheme.accentGold, trailing: Formatters.currency(o.totalAmount))).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('已成交', Formatters.currency(completedSales), () {
            final done = crm.orders.where((o) => o.status == 'completed').toList();
            _showDrilldown(context, '已成交订单 (${done.length})', AppTheme.success, Icons.check_circle,
              done.map((o) => _drilldownItem(o.id.substring(0, 8), o.contactName, AppTheme.success, trailing: Formatters.currency(o.totalAmount))).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('待发', '$shippedCount', () {
            final shipped = crm.orders.where((o) => o.status == 'shipped').toList();
            _showDrilldown(context, '已发货订单 (${shipped.length})', AppTheme.primaryBlue, Icons.local_shipping,
              shipped.map((o) => _drilldownItem(o.id.substring(0, 8), o.contactName, AppTheme.primaryBlue, trailing: Formatters.currency(o.totalAmount))).toList());
          })),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionTitle('渠道销售对比'),
      _buildChannelComparison(channelStats, crm),
      const SizedBox(height: 16),
      _sectionTitle('管线金额分布'),
      _buildStageAmountBars(stageStats, crm),
      const SizedBox(height: 16),
      _sectionTitle('交易排行 TOP 5'),
      _buildTopDeals(crm),
      const SizedBox(height: 30),
    ]);
  }

  Widget _buildChannelComparison(Map<String, Map<String, dynamic>> stats, CrmProvider crm) {
    final channelColors = {'agent': const Color(0xFFFF6348), 'clinic': const Color(0xFF1ABC9C), 'retail': const Color(0xFFE056A0)};
    final channelIcons = {'agent': Icons.storefront, 'clinic': Icons.local_hospital, 'retail': Icons.shopping_bag};
    return Row(children: stats.entries.map((e) {
      final ch = e.key;
      final s = e.value;
      final color = channelColors[ch] ?? AppTheme.textSecondary;
      return Expanded(child: GestureDetector(
        onTap: () {
          final chOrders = crm.orders.where((o) => o.priceType == ch).toList();
          _showDrilldown(context, '${s['label']}渠道订单 (${chOrders.length})', color, channelIcons[ch] ?? Icons.store,
            chOrders.map((o) => _drilldownItem(o.id.substring(0, 8), '${o.contactName} | ${SalesOrder.statusLabel(o.status)}', color, trailing: Formatters.currency(o.totalAmount))).toList());
        },
        child: Container(
          margin: EdgeInsets.only(right: ch != 'retail' ? 8 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(channelIcons[ch], color: color, size: 14),
              const SizedBox(width: 4),
              Text(s['label'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              Icon(Icons.open_in_new, size: 10, color: color.withValues(alpha: 0.5)),
            ]),
            const SizedBox(height: 8),
            Text(Formatters.currency(s['amount'] as double), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text('${s['orders']}单 | 发${s['shipped']} | 成${s['completed']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _buildStageAmountBars(Map<DealStage, Map<String, dynamic>> stats, CrmProvider crm) {
    final stages = DealStage.values.where((s) => s != DealStage.lost).toList();
    final maxAmount = stats.values.fold<double>(0, (m, v) => (v['amount'] as double) > m ? (v['amount'] as double) : m);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: stages.where((s) => (stats[s]?['count'] ?? 0) > 0).map((stage) {
        final s = stats[stage]!;
        final amount = s['amount'] as double;
        final count = s['count'] as int;
        final barWidth = maxAmount > 0 ? amount / maxAmount : 0.0;
        final color = _stageColor(stage);
        return GestureDetector(
          onTap: () {
            final stageDeals = crm.deals.where((d) => d.stage == stage).toList();
            _showDrilldown(context, '${stage.label} ($count笔)', color, Icons.view_kanban,
              stageDeals.map((d) => _drilldownItem(d.title, d.contactName, color, trailing: Formatters.currency(d.amount))).toList());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(width: 60, child: Text(stage.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 20, child: Text('$count', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: barWidth.clamp(0.02, 1.0), backgroundColor: AppTheme.cardBgLight, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
              )),
              const SizedBox(width: 6),
              SizedBox(width: 55, child: Text(Formatters.currency(amount), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              Icon(Icons.open_in_new, size: 10, color: color.withValues(alpha: 0.4)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildTopDeals(CrmProvider crm) {
    final top = crm.deals.where((d) => d.stage != DealStage.lost).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return Column(children: top.take(5).toList().asMap().entries.map((entry) {
      final d = entry.value;
      final r = entry.key + 1;
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Container(width: 24, height: 24,
            decoration: BoxDecoration(color: r <= 3 ? AppTheme.accentGold.withValues(alpha: 0.2) : AppTheme.cardBgLight, borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('$r', style: TextStyle(color: r <= 3 ? AppTheme.accentGold : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${d.contactName} | ${d.stage.label}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ])),
          Text(Formatters.currency(d.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      );
    }).toList());
  }

  // ========== TAB 5: 团队工作量 ==========
  Widget _buildTeamTab(CrmProvider crm) {
    final members = crm.teamMembers;
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _whiteKpiTap('总成员', '${members.length}', () {
            _showDrilldown(context, '团队成员 (${members.length})', AppTheme.primaryPurple, Icons.group,
              members.map((m) => _drilldownItem(m.name, '${TeamMember.roleLabel(m.role)} | ${m.isActive ? "在岗" : "离岗"}', m.isActive ? AppTheme.success : AppTheme.textSecondary)).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('活跃', '${members.where((m) => m.isActive).length}', () {
            final active = members.where((m) => m.isActive).toList();
            _showDrilldown(context, '活跃成员 (${active.length})', AppTheme.success, Icons.person,
              active.map((m) => _drilldownItem(m.name, TeamMember.roleLabel(m.role), AppTheme.success)).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('总任务', '${crm.tasks.length}', () {
            _showDrilldown(context, '全部任务 (${crm.tasks.length})', AppTheme.primaryBlue, Icons.task_alt,
              crm.tasks.map((t) => _drilldownItem(t.title, '${t.assigneeName} | ${t.status} | ${t.priority}',
                t.status == 'completed' ? AppTheme.success : (t.priority == 'urgent' ? AppTheme.danger : AppTheme.warning))).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('指派数', '${crm.assignments.length}', () {
            _showDrilldown(context, '全部指派 (${crm.assignments.length})', AppTheme.primaryPurple, Icons.assignment_ind,
              crm.assignments.map((a) => _drilldownItem(a.contactName, '${a.memberName} | ${a.stage.label}', AppTheme.primaryPurple)).toList());
          })),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionTitle('成员工作量明细'),
      ...members.map((m) => _memberWorkloadCard(crm, m)),
      const SizedBox(height: 30),
    ]);
  }

  Widget _memberWorkloadCard(CrmProvider crm, dynamic member) {
    final tasks = crm.getTasksByAssignee(member.id);
    final assignments = crm.getAssignmentsByMember(member.id);
    final activeTasks = tasks.where((t) => t.status != 'completed' && t.status != 'cancelled').length;
    final completedTasks = tasks.where((t) => t.status == 'completed').length;
    final prodOrders = crm.productionOrders.where((o) => o.assigneeId == member.id).toList();
    final activeProd = prodOrders.where((o) => o.status != 'completed' && o.status != 'cancelled').length;
    double totalHours = 0;
    for (final t in tasks) { totalHours += t.actualHours > 0 ? t.actualHours : t.estimatedHours; }

    Color roleColor;
    switch (member.role) {
      case 'admin': roleColor = AppTheme.primaryPurple; break;
      case 'manager': roleColor = AppTheme.warning; break;
      default: roleColor = AppTheme.primaryBlue; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(member.name.isNotEmpty ? member.name[0] : '?', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(member.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${TeamMember.roleLabel(member.role)} | ${totalHours.toStringAsFixed(0)}h 工时', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _miniKpi('任务', '${tasks.length}', AppTheme.primaryBlue)),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('进行中', '$activeTasks', AppTheme.warning)),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('已完成', '$completedTasks', AppTheme.success)),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('跟进人脉', '${assignments.length}', AppTheme.primaryPurple)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _miniKpi('生产单', '${prodOrders.length}', const Color(0xFF00CEC9))),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('生产进行', '$activeProd', AppTheme.warning)),
          const SizedBox(width: 6),
          Expanded(child: Container()),
          const SizedBox(width: 6),
          Expanded(child: Container()),
        ]),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('跟进任务:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: tasks.take(5).map((t) {
            Color pc;
            switch (t.priority) {
              case 'urgent': pc = AppTheme.danger; break;
              case 'high': pc = AppTheme.warning; break;
              default: pc = AppTheme.primaryBlue; break;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.status == 'completed' ? AppTheme.success.withValues(alpha: 0.1) : pc.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${t.title}${t.status == 'completed' ? ' ✓' : ''}',
                style: TextStyle(color: t.status == 'completed' ? AppTheme.success : pc, fontSize: 10,
                  decoration: t.status == 'completed' ? TextDecoration.lineThrough : null),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList()),
        ],
        if (assignments.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('跟进人脉:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: assignments.take(5).map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${a.contactName} (${a.stage.label})', style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10)),
          )).toList()),
        ],
      ]),
    );
  }

  // ========== TAB 6: 人脉数据 ==========
  Widget _buildContactsTab(CrmProvider crm) {
    final contacts = crm.allContacts;
    final relations = crm.relations;
    final deals = crm.deals;

    final industryCount = <Industry, int>{};
    for (final c in contacts) { industryCount[c.industry] = (industryCount[c.industry] ?? 0) + 1; }

    final hot = contacts.where((c) => c.strength == RelationshipStrength.hot).toList();
    final warm = contacts.where((c) => c.strength == RelationshipStrength.warm).toList();
    final cool = contacts.where((c) => c.strength == RelationshipStrength.cool).toList();
    final cold = contacts.where((c) => c.strength == RelationshipStrength.cold).toList();

    final myRelationCount = <MyRelationType, int>{};
    for (final c in contacts) { myRelationCount[c.myRelation] = (myRelationCount[c.myRelation] ?? 0) + 1; }

    final relationTypeCount = <String, int>{};
    final tagCount = <String, int>{};
    for (final r in relations) {
      relationTypeCount[r.relationType] = (relationTypeCount[r.relationType] ?? 0) + 1;
      for (final tag in r.tags) { tagCount[tag] = (tagCount[tag] ?? 0) + 1; }
    }

    final contactRelationCount = <String, int>{};
    for (final r in relations) {
      contactRelationCount[r.fromContactId] = (contactRelationCount[r.fromContactId] ?? 0) + 1;
      contactRelationCount[r.toContactId] = (contactRelationCount[r.toContactId] ?? 0) + 1;
    }
    final topConnected = contactRelationCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final salesIds = crm.contactsWithSales;
    final contactDealCount = <String, int>{};
    for (final d in deals) {
      contactDealCount[d.contactId] = (contactDealCount[d.contactId] ?? 0) + 1;
    }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _whiteKpiTap('总人脉', '${contacts.length}', () {
            _showDrilldown(context, '全部人脉 (${contacts.length})', AppTheme.primaryBlue, Icons.people,
              contacts.map((c) => _drilldownItem(c.name, '${c.company} | ${c.industry.label}', c.myRelation.color,
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('关系网', '${relations.length}', () {
            _showDrilldown(context, '关系网络 (${relations.length})', AppTheme.primaryPurple, Icons.hub,
              relations.map((r) => _drilldownItem('${r.fromName} → ${r.toName}', '${r.relationType} | ${r.tags.join(", ")}', AppTheme.primaryPurple)).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('销售线索', '${salesIds.length}', () {
            final salesContacts = contacts.where((c) => salesIds.contains(c.id)).toList();
            _showDrilldown(context, '有销售线索的人脉 (${salesContacts.length})', AppTheme.accentGold, Icons.monetization_on,
              salesContacts.map((c) => _drilldownItem(c.name, '${c.company} | ${c.myRelation.label}', AppTheme.accentGold,
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
          })),
          _vDivider(),
          Expanded(child: _whiteKpiTap('交易关联', '${contactDealCount.length}', () {
            final dealContacts = contacts.where((c) => contactDealCount.containsKey(c.id)).toList();
            _showDrilldown(context, '有交易的人脉 (${dealContacts.length})', const Color(0xFF00CEC9), Icons.handshake,
              dealContacts.map((c) => _drilldownItem(c.name, '${c.company} | ${contactDealCount[c.id]}笔交易', const Color(0xFF00CEC9),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
          })),
        ]),
      ),
      const SizedBox(height: 16),

      // 热度分布 - 可点击
      _sectionTitle('人脉热度分布'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Row(children: [
            Expanded(child: _miniKpiTap('核心', '${hot.length}', AppTheme.danger, () {
              _showDrilldown(context, '核心人脉 (${hot.length})', AppTheme.danger, Icons.star,
                hot.map((c) => _drilldownItem(c.name, '${c.company} | ${c.myRelation.label}', AppTheme.danger,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
            })),
            const SizedBox(width: 6),
            Expanded(child: _miniKpiTap('密切', '${warm.length}', AppTheme.warning, () {
              _showDrilldown(context, '密切人脉 (${warm.length})', AppTheme.warning, Icons.whatshot,
                warm.map((c) => _drilldownItem(c.name, '${c.company} | ${c.myRelation.label}', AppTheme.warning,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
            })),
            const SizedBox(width: 6),
            Expanded(child: _miniKpiTap('一般', '${cool.length}', AppTheme.primaryBlue, () {
              _showDrilldown(context, '一般人脉 (${cool.length})', AppTheme.primaryBlue, Icons.person,
                cool.map((c) => _drilldownItem(c.name, '${c.company} | ${c.myRelation.label}', AppTheme.primaryBlue,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
            })),
            const SizedBox(width: 6),
            Expanded(child: _miniKpiTap('浅交', '${cold.length}', AppTheme.textSecondary, () {
              _showDrilldown(context, '浅交人脉 (${cold.length})', AppTheme.textSecondary, Icons.person_outline,
                cold.map((c) => _drilldownItem(c.name, '${c.company} | ${c.myRelation.label}', AppTheme.textSecondary,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
            })),
          ]),
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(height: 12, child: Row(children: [
                if (hot.isNotEmpty) Expanded(flex: hot.length, child: Container(color: AppTheme.danger)),
                if (warm.isNotEmpty) Expanded(flex: warm.length, child: Container(color: AppTheme.warning)),
                if (cool.isNotEmpty) Expanded(flex: cool.length, child: Container(color: AppTheme.primaryBlue)),
                if (cold.isNotEmpty) Expanded(flex: cold.length, child: Container(color: AppTheme.textSecondary)),
              ])),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // 关系类型分布
      _sectionTitle('关系类型分布'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Wrap(spacing: 6, runSpacing: 6, children: (myRelationCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) {
          return GestureDetector(
            onTap: () {
              final filtered = contacts.where((c) => c.myRelation == e.key).toList();
              _showDrilldown(context, '${e.key.label} (${filtered.length})', e.key.color, Icons.category,
                filtered.map((c) => _drilldownItem(c.name, '${c.company} | ${c.strength.label}', e.key.color,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))); })).toList());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: e.key.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: e.key.color.withValues(alpha: 0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${e.key.label} ${e.value}', style: TextStyle(color: e.key.color, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                Icon(Icons.open_in_new, size: 8, color: e.key.color.withValues(alpha: 0.5)),
              ]),
            ),
          );
        }).toList()),
      ),
      const SizedBox(height: 16),

      _sectionTitle('行业分布'),
      _buildIndustryPie({'industryCount': industryCount}),
      const SizedBox(height: 16),

      if (relations.isNotEmpty) ...[
        _sectionTitle('第三方关系统计'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('关系类型', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: (relationTypeCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFF6348).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${e.key} (${e.value})', style: const TextStyle(color: Color(0xFFFF6348), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ).toList()),
            if (tagCount.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('关系标签', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: (tagCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) {
                final c = ContactRelation.tagColor(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.3))),
                  child: Text('${e.key} (${e.value})', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
                );
              }).toList()),
            ],
          ]),
        ),
        const SizedBox(height: 16),
      ],

      if (topConnected.isNotEmpty) ...[
        _sectionTitle('关系网络 TOP 5 (连接最多)'),
        ...topConnected.take(5).toList().asMap().entries.map((entry) {
          final contactId = entry.value.key;
          final count = entry.value.value;
          final rank = entry.key + 1;
          final contact = crm.getContact(contactId);
          if (contact == null) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contactId))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(width: 24, height: 24,
                  decoration: BoxDecoration(color: rank <= 3 ? AppTheme.primaryPurple.withValues(alpha: 0.2) : AppTheme.cardBgLight, borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('$rank', style: TextStyle(color: rank <= 3 ? AppTheme.primaryPurple : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${contact.company} | ${contact.myRelation.label}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('$count 连接', style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],

      _sectionTitle('交易金额 TOP 5 人脉'),
      _buildTopDealContacts(crm),
      const SizedBox(height: 30),
    ]);
  }

  Widget _buildTopDealContacts(CrmProvider crm) {
    final contactAmounts = <String, double>{};
    final contactNames = <String, String>{};
    for (final d in crm.deals) {
      if (d.stage == DealStage.lost) continue;
      contactAmounts[d.contactId] = (contactAmounts[d.contactId] ?? 0) + d.amount;
      contactNames[d.contactId] = d.contactName;
    }
    final sorted = contactAmounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(children: sorted.take(5).toList().asMap().entries.map((entry) {
      final contactId = entry.value.key;
      final amount = entry.value.value;
      final rank = entry.key + 1;
      final name = contactNames[contactId] ?? '未知';
      final contact = crm.getContact(contactId);

      return GestureDetector(
        onTap: contact != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contactId))) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(width: 24, height: 24,
              decoration: BoxDecoration(color: rank <= 3 ? AppTheme.accentGold.withValues(alpha: 0.2) : AppTheme.cardBgLight, borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('$rank', style: TextStyle(color: rank <= 3 ? AppTheme.accentGold : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              if (contact != null) Text('${contact.company} | ${contact.myRelation.label}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ])),
            Text(Formatters.currency(amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
      );
    }).toList());
  }

  // ========== 共用组件 ==========
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            const SizedBox(width: 2),
            Icon(Icons.open_in_new, size: 8, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ]),
        ]),
      ),
    );
  }

  Widget _miniKpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _miniKpiTap(String label, String value, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
            const SizedBox(width: 2),
            Icon(Icons.open_in_new, size: 7, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ]),
        ]),
      ),
    );
  }

  Widget _whiteKpiTap(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
          const SizedBox(width: 2),
          Icon(Icons.open_in_new, size: 8, color: Colors.white.withValues(alpha: 0.4)),
        ]),
      ]),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white30);

  Widget _buildIndustryPie(Map<String, dynamic> stats) {
    final Map<Industry, int> ic = stats['industryCount'] as Map<Industry, int>;
    if (ic.isEmpty) return const SizedBox.shrink();
    final total = ic.values.fold(0, (a, b) => a + b);
    final entries = ic.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: SizedBox(height: 180, child: Row(children: [
        Expanded(flex: 3, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 28,
          sections: entries.map((e) => PieChartSectionData(
            value: e.value.toDouble(), title: '${(e.value / total * 100).toStringAsFixed(0)}%',
            color: e.key.color, radius: 45,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          )).toList()))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.take(6).map((e) => Padding(padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Expanded(child: Text('${e.key.label} (${e.value})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
            ]))).toList())),
      ])),
    );
  }

  Widget _buildPipelineBar(Map<String, dynamic> stats, CrmProvider crm) {
    final Map<DealStage, int> sc = stats['stageCount'] as Map<DealStage, int>;
    if (sc.isEmpty) return const SizedBox.shrink();
    final stages = DealStage.values.where((s) => s != DealStage.lost && (sc[s] ?? 0) > 0).toList();
    final maxVal = sc.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: SizedBox(height: 150, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: maxVal + 1,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event.isInterestedForInteractions && response?.spot != null) {
              final idx = response!.spot!.touchedBarGroupIndex;
              if (idx >= 0 && idx < stages.length) {
                final stage = stages[idx];
                final stageDeals = crm.deals.where((d) => d.stage == stage).toList();
                _showDrilldown(context, '${stage.label} (${stageDeals.length}笔)', _stageColor(stage), Icons.view_kanban,
                  stageDeals.map((d) => _drilldownItem(d.title, d.contactName, _stageColor(stage), trailing: Formatters.currency(d.amount))).toList());
              }
            }
          },
        ),
        titlesData: FlTitlesData(show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) { final i = v.toInt(); if (i < 0 || i >= stages.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 4), child: Text(stages[i].label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9))); })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        borderData: FlBorderData(show: false), gridData: const FlGridData(show: false),
        barGroups: stages.asMap().entries.map((e) => BarChartGroupData(x: e.key,
          barRods: [BarChartRodData(toY: (sc[e.value] ?? 0).toDouble(), color: _stageColor(e.value), width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])).toList()))),
    );
  }

  Color _stageColor(DealStage s) {
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
}
