import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class SalesStatsScreen extends StatelessWidget {
  const SalesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final channelStats = crm.channelSalesStats;
      final stageStats = crm.pipelineStageStats;

      return SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildOverallKpi(crm)),
        SliverToBoxAdapter(child: _buildChannelSection(channelStats)),
        SliverToBoxAdapter(child: _buildPipelineStageSection(stageStats)),
        SliverToBoxAdapter(child: _buildChannelBars(channelStats)),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]));
    });
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(children: [
        Icon(Icons.analytics_rounded, color: AppTheme.accentGold, size: 24),
        SizedBox(width: 10),
        Text('销售统计', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildOverallKpi(CrmProvider crm) {
    double totalSales = 0, completed = 0;
    int totalOrders = crm.orders.length;
    int shippedOrders = 0;
    for (final o in crm.orders) {
      totalSales += o.totalAmount;
      if (o.status == 'completed') completed += o.totalAmount;
      if (o.status == 'shipped') shippedOrders++;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _kpiItem('总订单', '$totalOrders', Colors.white)),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(child: _kpiItem('总额', Formatters.currency(totalSales), Colors.white)),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(child: _kpiItem('已成交', Formatters.currency(completed), Colors.white)),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(child: _kpiItem('待出货', '$shippedOrders', Colors.white)),
        ]),
      ),
    );
  }

  Widget _kpiItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
    ]);
  }

  Widget _buildChannelSection(Map<String, Map<String, dynamic>> stats) {
    final channelColors = {'agent': const Color(0xFFFF6348), 'clinic': const Color(0xFF1ABC9C), 'retail': const Color(0xFFE056A0)};
    final channelIcons = {'agent': Icons.storefront, 'clinic': Icons.local_hospital, 'retail': Icons.shopping_bag};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('渠道销售统计', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: stats.entries.map((e) {
          final ch = e.key;
          final s = e.value;
          final color = channelColors[ch] ?? AppTheme.textSecondary;
          final icon = channelIcons[ch] ?? Icons.storefront;
          return Expanded(child: Container(
            margin: EdgeInsets.only(right: ch != 'retail' ? 8 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(s['label'] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              Text(Formatters.currency((s['amount'] as double)), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text('${s['orders']}单', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Row(children: [
                _miniTag('发货${s['shipped']}', const Color(0xFF74B9FF)),
                const SizedBox(width: 4),
                _miniTag('完成${s['completed']}', AppTheme.success),
              ]),
            ]),
          ));
        }).toList()),
      ]),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPipelineStageSection(Map<DealStage, Map<String, dynamic>> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('管线阶段统计', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: DealStage.values.map((stage) {
            final s = stats[stage]!;
            final count = s['count'] as int;
            final amount = s['amount'] as double;
            if (count == 0) return const SizedBox.shrink();
            final color = _stageColor(stage);
            final maxAmount = stats.values.fold<double>(0, (m, v) => (v['amount'] as double) > m ? (v['amount'] as double) : m);
            final barWidth = maxAmount > 0 ? amount / maxAmount : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 70, child: Row(children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(stage.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                ])),
                SizedBox(width: 28, child: Text('$count', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: barWidth, backgroundColor: AppTheme.cardBgLight, valueColor: AlwaysStoppedAnimation(color), minHeight: 10),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 65, child: Text(Formatters.currency(amount), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ]),
            );
          }).toList()),
        ),
      ]),
    );
  }

  Widget _buildChannelBars(Map<String, Map<String, dynamic>> stats) {
    final channelColors = {'agent': const Color(0xFFFF6348), 'clinic': const Color(0xFF1ABC9C), 'retail': const Color(0xFFE056A0)};
    double totalAmount = 0;
    for (final s in stats.values) { totalAmount += (s['amount'] as double); }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('渠道占比', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 24,
                child: Row(children: stats.entries.map((e) {
                  final amount = e.value['amount'] as double;
                  final ratio = totalAmount > 0 ? amount / totalAmount : 0.0;
                  return Expanded(
                    flex: (ratio * 100).round().clamp(1, 100),
                    child: Container(color: channelColors[e.key]),
                  );
                }).toList()),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: stats.entries.map((e) {
              final amount = e.value['amount'] as double;
              final ratio = totalAmount > 0 ? (amount / totalAmount * 100) : 0.0;
              final color = channelColors[e.key] ?? AppTheme.textSecondary;
              return Column(children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(e.value['label'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ]),
                Text('${ratio.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ]);
            }).toList()),
          ]),
        ),
      ]),
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
