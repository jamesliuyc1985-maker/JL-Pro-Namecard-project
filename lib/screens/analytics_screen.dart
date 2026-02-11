import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final stats = crm.stats;
      return SafeArea(child: CustomScrollView(slivers: [
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('业务分析', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)))),
        SliverToBoxAdapter(child: _buildOverviewCards(stats)),
        SliverToBoxAdapter(child: _buildIndustryChart(stats)),
        SliverToBoxAdapter(child: _buildPipelineChart(stats)),
        SliverToBoxAdapter(child: _buildDealFunnel(crm)),
        SliverToBoxAdapter(child: _buildTopDeals(crm)),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]));
    });
  }

  Widget _buildOverviewCards(Map<String, dynamic> stats) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.95,
        children: [
          _miniCard('成交率', '${(stats['winRate'] as double).toStringAsFixed(1)}%', Icons.pie_chart, AppTheme.success),
          _miniCard('核心人脉', '${stats['hotContacts']}人', Icons.whatshot, AppTheme.danger),
          _miniCard('已成交', '${stats['closedDeals']}笔', Icons.check_circle, AppTheme.accentGold),
        ]));
  }

  Widget _miniCard(String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 24), const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]));
  }

  Widget _buildIndustryChart(Map<String, dynamic> stats) {
    final Map<Industry, int> ic = stats['industryCount'] as Map<Industry, int>;
    if (ic.isEmpty) return const SizedBox.shrink();
    final total = ic.values.fold(0, (a, b) => a + b);
    final entries = ic.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('行业分布', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: Row(children: [
            Expanded(flex: 3, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 30,
              sections: entries.map((e) => PieChartSectionData(value: e.value.toDouble(),
                title: '${(e.value / total * 100).toStringAsFixed(0)}%', color: e.key.color, radius: 50,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))).toList()))),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.take(6).map((e) => Padding(padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.key.color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${e.key.label} (${e.value})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                ]))).toList())),
          ])),
        ])));
  }

  Widget _buildPipelineChart(Map<String, dynamic> stats) {
    final Map<DealStage, int> sc = stats['stageCount'] as Map<DealStage, int>;
    if (sc.isEmpty) return const SizedBox.shrink();
    final stages = [DealStage.lead, DealStage.contacted, DealStage.proposal, DealStage.negotiation, DealStage.closed];
    final maxVal = sc.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('阶段分布', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround, maxY: maxVal + 1,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                getTitlesWidget: (v, _) { final i = v.toInt(); if (i < 0 || i >= stages.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6), child: Text(stages[i].label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))); })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false), gridData: const FlGridData(show: false),
            barGroups: stages.asMap().entries.map((e) => BarChartGroupData(x: e.key,
              barRods: [BarChartRodData(toY: (sc[e.value] ?? 0).toDouble(), color: _sColor(e.value), width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])).toList()))),
        ])));
  }

  Widget _buildDealFunnel(CrmProvider crm) {
    final deals = crm.deals;
    final stages = [DealStage.lead, DealStage.contacted, DealStage.proposal, DealStage.negotiation, DealStage.closed];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('交易漏斗', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...stages.map((stage) {
            final sd = deals.where((d) => d.stage == stage).toList();
            double sa = 0; for (final d in sd) sa += d.amount;
            final ma = deals.isEmpty ? 1.0 : deals.map((d) => d.amount).fold(0.0, (a, b) => a > b ? a : b);
            final ratio = sa / (ma * stages.length).clamp(1, double.infinity);
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _sColor(stage), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(stage.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${sd.length}笔 | ${Formatters.currency(sa)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: ratio.clamp(0.05, 1.0), backgroundColor: AppTheme.cardBgLight,
                  valueColor: AlwaysStoppedAnimation(_sColor(stage)), minHeight: 8)),
            ]));
          }),
        ])));
  }

  Widget _buildTopDeals(CrmProvider crm) {
    final top = crm.deals.where((d) => d.stage != DealStage.lost).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('案件排行', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...top.take(5).toList().asMap().entries.map((entry) {
            final d = entry.value; final r = entry.key + 1;
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: r <= 3 ? AppTheme.accentGold.withValues(alpha: 0.2) : AppTheme.cardBg, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('$r', style: TextStyle(color: r <= 3 ? AppTheme.accentGold : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(d.contactName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ])),
                Text(Formatters.currency(d.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
              ]));
          }),
        ])));
  }

  Color _sColor(DealStage s) {
    switch (s) { case DealStage.lead: return AppTheme.textSecondary; case DealStage.contacted: return AppTheme.primaryBlue;
      case DealStage.proposal: return AppTheme.primaryPurple; case DealStage.negotiation: return AppTheme.warning;
      case DealStage.closed: return AppTheme.success; case DealStage.lost: return AppTheme.danger; }
  }
}
