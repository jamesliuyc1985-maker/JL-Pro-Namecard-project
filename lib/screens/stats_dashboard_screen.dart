import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/team.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

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
          _kpiCard('人脉总数', '${stats['totalContacts']}', Icons.people, AppTheme.primaryBlue),
          _kpiCard('活跃交易', '${stats['activeDeals']}', Icons.handshake, AppTheme.warning),
          _kpiCard('管线总额', Formatters.currency(stats['pipelineValue'] as double), Icons.trending_up, AppTheme.accentGold),
          _kpiCard('成交率', '${(stats['winRate'] as double).toStringAsFixed(1)}%', Icons.pie_chart, AppTheme.success),
          _kpiCard('产品数', '${stats['totalProducts']}', Icons.science, AppTheme.primaryPurple),
          _kpiCard('订单数', '${stats['totalOrders']}', Icons.receipt_long, const Color(0xFF00CEC9)),
        ],
      ),
      const SizedBox(height: 16),
      _sectionTitle('人脉行业分布'),
      _buildIndustryPie(stats),
      const SizedBox(height: 16),
      _sectionTitle('管线阶段分布'),
      _buildPipelineBar(stats),
      const SizedBox(height: 16),
      _sectionTitle('生产概况'),
      Row(children: [
        Expanded(child: _miniKpi('进行中', '${prodStats['activeOrders']}', const Color(0xFF00CEC9))),
        const SizedBox(width: 8),
        Expanded(child: _miniKpi('计划量', '${prodStats['totalPlannedQty']}', AppTheme.warning)),
        const SizedBox(width: 8),
        Expanded(child: _miniKpi('已完工', '${prodStats['completedOrders']}', AppTheme.success)),
        const SizedBox(width: 8),
        Expanded(child: _miniKpi('工厂数', '${prodStats['factoryCount']}', AppTheme.primaryPurple)),
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
        'totalQty': totalQty, 'completedQty': completedQty,
      };
    }

    final statusCounts = <String, int>{};
    for (final o in orders) { statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1; }

    // 按成员统计生产单
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
          Expanded(child: _whiteKpi('生产单', '${orders.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('进行中', '${prodStats['activeOrders']}')),
          _vDivider(),
          Expanded(child: _whiteKpi('已完工', '${prodStats['completedOrders']}')),
          _vDivider(),
          Expanded(child: _whiteKpi('完成量', '${prodStats['totalCompletedQty']}')),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionTitle('生产状态分布'),
      _buildStatusDistribution(statusCounts),
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

  Widget _buildStatusDistribution(Map<String, int> statusCounts) {
    final statusLabels = {'planned': '计划中', 'materials': '备料', 'producing': '生产中', 'quality': '质检', 'completed': '已完成', 'cancelled': '已取消'};
    final statusColors = {'planned': AppTheme.textSecondary, 'materials': AppTheme.warning, 'producing': AppTheme.primaryBlue, 'quality': AppTheme.primaryPurple, 'completed': AppTheme.success, 'cancelled': AppTheme.danger};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Wrap(spacing: 8, runSpacing: 8, children: statusCounts.entries.map((e) {
        final color = statusColors[e.key] ?? AppTheme.textSecondary;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(statusLabels[e.key] ?? e.key, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text('${e.value}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
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
          Expanded(child: _whiteKpi('SKU数', '${stocks.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('总库存', '$totalStock')),
          _vDivider(),
          Expanded(child: _whiteKpi('总入库', '$totalIn')),
          _vDivider(),
          Expanded(child: _whiteKpi('总出库', '$totalOut')),
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
          Expanded(child: _whiteKpi('总订单', '$totalOrders')),
          _vDivider(),
          Expanded(child: _whiteKpi('总额', Formatters.currency(totalSales))),
          _vDivider(),
          Expanded(child: _whiteKpi('已成交', Formatters.currency(completedSales))),
          _vDivider(),
          Expanded(child: _whiteKpi('待发', '$shippedCount')),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionTitle('渠道销售对比'),
      _buildChannelComparison(channelStats),
      const SizedBox(height: 16),
      _sectionTitle('管线金额分布'),
      _buildStageAmountBars(stageStats),
      const SizedBox(height: 16),
      _sectionTitle('交易排行 TOP 5'),
      _buildTopDeals(crm),
      const SizedBox(height: 30),
    ]);
  }

  Widget _buildChannelComparison(Map<String, Map<String, dynamic>> stats) {
    final channelColors = {'agent': const Color(0xFFFF6348), 'clinic': const Color(0xFF1ABC9C), 'retail': const Color(0xFFE056A0)};
    final channelIcons = {'agent': Icons.storefront, 'clinic': Icons.local_hospital, 'retail': Icons.shopping_bag};
    return Row(children: stats.entries.map((e) {
      final ch = e.key;
      final s = e.value;
      final color = channelColors[ch] ?? AppTheme.textSecondary;
      return Expanded(child: Container(
        margin: EdgeInsets.only(right: ch != 'retail' ? 8 : 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(channelIcons[ch], color: color, size: 14),
            const SizedBox(width: 4),
            Text(s['label'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(Formatters.currency(s['amount'] as double), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text('${s['orders']}单 | 发${s['shipped']} | 成${s['completed']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ]),
      ));
    }).toList());
  }

  Widget _buildStageAmountBars(Map<DealStage, Map<String, dynamic>> stats) {
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
        return Padding(
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
          ]),
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
          Expanded(child: _whiteKpi('总成员', '${members.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('活跃', '${members.where((m) => m.isActive).length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('总任务', '${crm.tasks.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('指派数', '${crm.assignments.length}')),
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
    // 统计该成员跟进的生产单
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
        // 任务统计行
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
        // 生产跟进行
        Row(children: [
          Expanded(child: _miniKpi('生产单', '${prodOrders.length}', const Color(0xFF00CEC9))),
          const SizedBox(width: 6),
          Expanded(child: _miniKpi('生产进行', '$activeProd', AppTheme.warning)),
          const SizedBox(width: 6),
          Expanded(child: Container()), // placeholder
          const SizedBox(width: 6),
          Expanded(child: Container()), // placeholder
        ]),
        // 跟进任务详情
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
        // 跟进人脉标签
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

    // 行业分布
    final industryCount = <Industry, int>{};
    for (final c in contacts) { industryCount[c.industry] = (industryCount[c.industry] ?? 0) + 1; }

    // 热度统计
    final hot = contacts.where((c) => c.strength == RelationshipStrength.hot).length;
    final warm = contacts.where((c) => c.strength == RelationshipStrength.warm).length;
    final cool = contacts.where((c) => c.strength == RelationshipStrength.cool).length;
    final cold = contacts.where((c) => c.strength == RelationshipStrength.cold).length;

    // 关系类型分布
    final myRelationCount = <MyRelationType, int>{};
    for (final c in contacts) { myRelationCount[c.myRelation] = (myRelationCount[c.myRelation] ?? 0) + 1; }

    // 第三方关系统计
    final relationTypeCount = <String, int>{};
    final tagCount = <String, int>{};
    for (final r in relations) {
      relationTypeCount[r.relationType] = (relationTypeCount[r.relationType] ?? 0) + 1;
      for (final tag in r.tags) { tagCount[tag] = (tagCount[tag] ?? 0) + 1; }
    }

    // 每人关联数排行
    final contactRelationCount = <String, int>{};
    for (final r in relations) {
      contactRelationCount[r.fromContactId] = (contactRelationCount[r.fromContactId] ?? 0) + 1;
      contactRelationCount[r.toContactId] = (contactRelationCount[r.toContactId] ?? 0) + 1;
    }
    final topConnected = contactRelationCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 销售线索
    final salesIds = crm.contactsWithSales;

    // 有交易的人脉统计
    final contactDealCount = <String, int>{};
    for (final d in deals) {
      contactDealCount[d.contactId] = (contactDealCount[d.contactId] ?? 0) + 1;
    }

    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      const SizedBox(height: 8),
      // 人脉总览
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _whiteKpi('总人脉', '${contacts.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('关系网', '${relations.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('销售线索', '${salesIds.length}')),
          _vDivider(),
          Expanded(child: _whiteKpi('交易关联', '${contactDealCount.length}')),
        ]),
      ),
      const SizedBox(height: 16),

      // 热度分布
      _sectionTitle('人脉热度分布'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Row(children: [
            Expanded(child: _miniKpi('核心', '$hot', AppTheme.danger)),
            const SizedBox(width: 6),
            Expanded(child: _miniKpi('密切', '$warm', AppTheme.warning)),
            const SizedBox(width: 6),
            Expanded(child: _miniKpi('一般', '$cool', AppTheme.primaryBlue)),
            const SizedBox(width: 6),
            Expanded(child: _miniKpi('浅交', '$cold', AppTheme.textSecondary)),
          ]),
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 热度比例条
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(height: 12, child: Row(children: [
                if (hot > 0) Expanded(flex: hot, child: Container(color: AppTheme.danger)),
                if (warm > 0) Expanded(flex: warm, child: Container(color: AppTheme.warning)),
                if (cool > 0) Expanded(flex: cool, child: Container(color: AppTheme.primaryBlue)),
                if (cold > 0) Expanded(flex: cold, child: Container(color: AppTheme.textSecondary)),
              ])),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // 我的关系类型分布
      _sectionTitle('关系类型分布'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Wrap(spacing: 6, runSpacing: 6, children: (myRelationCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: e.key.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: e.key.color.withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${e.key.label} ${e.value}', style: TextStyle(color: e.key.color, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          );
        }).toList()),
      ),
      const SizedBox(height: 16),

      // 行业分布饼图
      _sectionTitle('行业分布'),
      _buildIndustryPie({'industryCount': industryCount}),
      const SizedBox(height: 16),

      // 第三方关系网络统计
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

      // 人脉关系排行
      if (topConnected.isNotEmpty) ...[
        _sectionTitle('关系网络 TOP 5 (连接最多)'),
        ...topConnected.take(5).toList().asMap().entries.map((entry) {
          final contactId = entry.value.key;
          final count = entry.value.value;
          final rank = entry.key + 1;
          final contact = crm.getContact(contactId);
          if (contact == null) return const SizedBox.shrink();
          return Container(
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
          );
        }),
        const SizedBox(height: 16),
      ],

      // 交易金额 TOP 人脉
      _sectionTitle('交易金额 TOP 5 人脉'),
      _buildTopDealContacts(crm),
      const SizedBox(height: 30),
    ]);
  }

  Widget _buildTopDealContacts(CrmProvider crm) {
    // Aggregate deal amount per contact
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

      return Container(
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

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        FittedBox(child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ]),
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

  Widget _whiteKpi(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
    ]);
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

  Widget _buildPipelineBar(Map<String, dynamic> stats) {
    final Map<DealStage, int> sc = stats['stageCount'] as Map<DealStage, int>;
    if (sc.isEmpty) return const SizedBox.shrink();
    final stages = DealStage.values.where((s) => s != DealStage.lost && (sc[s] ?? 0) > 0).toList();
    final maxVal = sc.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: SizedBox(height: 150, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: maxVal + 1,
        barTouchData: BarTouchData(enabled: false),
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
