import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'add_deal_screen.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});
  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _stages = [DealStage.lead, DealStage.contacted, DealStage.proposal, DealStage.negotiation, DealStage.closed, DealStage.lost];

  @override
  void initState() { super.initState(); _tabController = TabController(length: _stages.length, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _buildHeader(context),
        _buildSummary(crm),
        _buildTabs(),
        Expanded(child: _buildTabView(crm)),
      ]));
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Text('交易管线', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: Colors.white, size: 20)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDealScreen())),
        ),
      ]),
    );
  }

  Widget _buildSummary(CrmProvider crm) {
    final active = crm.deals.where((d) => d.stage != DealStage.closed && d.stage != DealStage.lost);
    double total = 0, weighted = 0;
    for (final d in active) { total += d.amount; weighted += d.amount * d.probability / 100; }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('管线总额', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(Formatters.currency(total), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ])),
          Container(width: 1, height: 40, color: Colors.white30),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('加权期望值', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(Formatters.currency(weighted), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(controller: _tabController, isScrollable: true, indicatorColor: AppTheme.primaryPurple, indicatorWeight: 3,
      labelColor: AppTheme.primaryPurple, unselectedLabelColor: AppTheme.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), tabAlignment: TabAlignment.start,
      tabs: _stages.map((s) => Tab(text: s.label)).toList());
  }

  Widget _buildTabView(CrmProvider crm) {
    return TabBarView(controller: _tabController, children: _stages.map((stage) {
      final deals = crm.getDealsByStage(stage);
      if (deals.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 48),
        const SizedBox(height: 12),
        Text('${stage.label} 暂无案件', style: const TextStyle(color: AppTheme.textSecondary)),
      ]));
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: deals.length,
        itemBuilder: (context, index) => _dealCard(context, crm, deals[index]));
    }).toList());
  }

  Widget _dealCard(BuildContext context, CrmProvider crm, Deal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _color(deal.stage).withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
          PopupMenuButton<DealStage>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18), color: AppTheme.cardBgLight,
            onSelected: (s) => crm.moveDealStage(deal.id, s),
            itemBuilder: (_) => _stages.where((s) => s != deal.stage).map((s) => PopupMenuItem(value: s,
              child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle)),
                const SizedBox(width: 8), Text('→ ${s.label}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))]))).toList()),
        ]),
        const SizedBox(height: 6),
        Text(deal.contactName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        if (deal.description.isNotEmpty) ...[const SizedBox(height: 4),
          Text(deal.description, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)],
        const SizedBox(height: 12),
        Row(children: [
          Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _color(deal.stage).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('${deal.probability.toInt()}%', style: TextStyle(color: _color(deal.stage), fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: deal.probability / 100, backgroundColor: AppTheme.cardBgLight,
            valueColor: AlwaysStoppedAnimation(_color(deal.stage)), minHeight: 4)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.calendar_today, color: AppTheme.textSecondary.withValues(alpha: 0.7), size: 12), const SizedBox(width: 4),
          Text('截止: ${Formatters.dateFull(deal.expectedCloseDate)}', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11)),
        ]),
      ]),
    );
  }

  Color _color(DealStage s) {
    switch (s) { case DealStage.lead: return AppTheme.textSecondary; case DealStage.contacted: return AppTheme.primaryBlue;
      case DealStage.proposal: return AppTheme.primaryPurple; case DealStage.negotiation: return AppTheme.warning;
      case DealStage.closed: return AppTheme.success; case DealStage.lost: return AppTheme.danger; }
  }
}
