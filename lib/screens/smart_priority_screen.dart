import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../models/contact.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'contact_detail_screen.dart';

/// 智能跟进优先级看板
class SmartPriorityScreen extends StatefulWidget {
  const SmartPriorityScreen({super.key});
  @override
  State<SmartPriorityScreen> createState() => _SmartPriorityScreenState();
}

class _SmartPriorityScreenState extends State<SmartPriorityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final dealScores = _scoreDealPriority(crm);
      final contactScores = _scoreContactPriority(crm);
      final starredDeals = crm.starredDeals;

      return SafeArea(child: Column(children: [
        _buildHeader(dealScores, contactScores, starredDeals),
        _buildSummaryCards(dealScores, contactScores, crm),
        TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, size: 14),
              const SizedBox(width: 4),
              Text('重点 (${starredDeals.length})'),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.trending_up, size: 14),
              const SizedBox(width: 4),
              Text('项目 (${dealScores.length})'),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_search, size: 14),
              const SizedBox(width: 4),
              Text('人脉 (${contactScores.length})'),
            ])),
          ],
        ),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildStarredTab(crm, starredDeals),
          _buildDealPriorityList(crm, dealScores),
          _buildContactPriorityList(crm, contactScores),
        ])),
      ]));
    });
  }

  Widget _buildHeader(List<_DealScore> deals, List<_ContactScore> contacts, List<Deal> starred) {
    final urgentDeals = deals.where((d) => d.signal == _Signal.red).length;
    final urgentContacts = contacts.where((c) => c.signal == _Signal.red).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 24),
        const SizedBox(width: 10),
        const Expanded(child: Text('智能跟进', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold))),
        if (starred.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: AppTheme.accentGold, size: 14),
              Text(' ${starred.length}', style: const TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        if (urgentDeals + urgentContacts > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.priority_high, color: AppTheme.danger, size: 14),
              Text(' ${urgentDeals + urgentContacts}', style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildSummaryCards(List<_DealScore> deals, List<_ContactScore> contacts, CrmProvider crm) {
    double totalWeighted = 0;
    for (final d in deals) { totalWeighted += d.weightedValue; }
    final redDealsList = deals.where((d) => d.signal == _Signal.red).toList();
    final yellowDealsList = deals.where((d) => d.signal == _Signal.yellow).toList();
    final coldContactsList = contacts.where((c) => c.daysSinceLastContact > 14).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _card('加权期望', Formatters.currency(totalWeighted), AppTheme.accentGold, () {
          _showDrilldownDeals(context, '加权期望明细', deals, AppTheme.accentGold);
        })),
        const SizedBox(width: 6),
        Expanded(child: _card('紧急项目', '${redDealsList.length}', AppTheme.danger, () {
          _showDrilldownDeals(context, '紧急项目', redDealsList, AppTheme.danger);
        })),
        const SizedBox(width: 6),
        Expanded(child: _card('需关注', '${yellowDealsList.length}', AppTheme.warning, () {
          _showDrilldownDeals(context, '需关注项目', yellowDealsList, AppTheme.warning);
        })),
        const SizedBox(width: 6),
        Expanded(child: _card('冷却人脉', '${coldContactsList.length}', const Color(0xFF74B9FF), () {
          _showDrilldownContacts(context, '冷却人脉 (>14天未联系)', coldContactsList, const Color(0xFF74B9FF));
        })),
      ]),
    );
  }

  Widget _card(String label, String value, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
            const SizedBox(width: 2),
            Icon(Icons.open_in_new, size: 8, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ]),
        ]),
      ),
    );
  }

  // ========== Drilldown Dialogs ==========
  void _showDrilldownDeals(BuildContext context, String title, List<_DealScore> deals, Color color) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.trending_up, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('$title (${deals.length})', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          if (deals.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Text('无数据', style: TextStyle(color: AppTheme.textSecondary)))
          else
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: deals.length,
              itemBuilder: (_, i) {
                final ds = deals[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ds.signal.color.withValues(alpha: 0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: ds.signal.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(ds.urgencyLabel, style: TextStyle(color: ds.signal.color, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ds.deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      _drilldownMetric('联系人', ds.deal.contactName, AppTheme.primaryBlue),
                      _drilldownMetric('金额', Formatters.currency(ds.deal.amount), AppTheme.accentGold),
                      _drilldownMetric('概率', '${ds.deal.probability.toInt()}%', AppTheme.primaryPurple),
                      _drilldownMetric('剩余', ds.daysToClose <= 0 ? '已过期' : '${ds.daysToClose}天', ds.daysToClose <= 7 ? AppTheme.danger : AppTheme.success),
                    ]),
                    if (ds.suggestedAction.isNotEmpty) ...[const SizedBox(height: 6),
                      Text(ds.suggestedAction, style: TextStyle(color: ds.signal.color, fontSize: 10))],
                  ]),
                );
              },
            )),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _showDrilldownContacts(BuildContext context, String title, List<_ContactScore> contacts, Color color) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.person_search, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('$title (${contacts.length})', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          if (contacts.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Text('无数据', style: TextStyle(color: AppTheme.textSecondary)))
          else
            Flexible(child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: contacts.length,
              itemBuilder: (_, i) {
                final cs = contacts[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: cs.contact.id)));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.signal.color.withValues(alpha: 0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: cs.contact.myRelation.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(cs.contact.name[0], style: TextStyle(color: cs.contact.myRelation.color, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cs.contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${cs.contact.company} | ${cs.contact.strength.label}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: cs.signal.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text(cs.urgencyLabel, style: TextStyle(color: cs.signal.color, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        _drilldownMetric('最后联系', cs.daysSinceLastContact == 0 ? '今天' : '${cs.daysSinceLastContact}天前', cs.daysSinceLastContact > 14 ? AppTheme.danger : AppTheme.success),
                        _drilldownMetric('Deal', '${cs.dealCount}笔', AppTheme.primaryPurple),
                        _drilldownMetric('管线', Formatters.currency(cs.pipelineValue), AppTheme.accentGold),
                        _drilldownMetric('关联', '${cs.relationCount}人', AppTheme.primaryBlue),
                      ]),
                      if (cs.suggestedAction.isNotEmpty) ...[const SizedBox(height: 6),
                        Text(cs.suggestedAction, style: TextStyle(color: cs.signal.color, fontSize: 10))],
                    ]),
                  ),
                );
              },
            )),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _drilldownMetric(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
    ]));
  }

  // ========== Starred Key Projects Tab ==========
  Widget _buildStarredTab(CrmProvider crm, List<Deal> starred) {
    if (starred.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.star_border, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无重点标记项目', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        SizedBox(height: 4),
        Text('在项目列表中点击星标添加重点项目', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]));
    }
    final sorted = List<Deal>.from(starred)..sort((a, b) => b.amount.compareTo(a.amount));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) => _starredDealCard(crm, sorted[i]),
    );
  }

  Widget _starredDealCard(CrmProvider crm, Deal deal) {
    final c = _stageColor(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => crm.toggleDealStar(deal.id),
            child: const Icon(Icons.star, color: AppTheme.accentGold, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(deal.contactName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(deal.stage.label, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Text('${deal.probability.toInt()}%', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Text('${deal.expectedCloseDate.difference(DateTime.now()).inDays}天', style: TextStyle(
            color: deal.expectedCloseDate.difference(DateTime.now()).inDays <= 7 ? AppTheme.danger : AppTheme.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: deal.probability / 100, backgroundColor: AppTheme.cardBgLight,
            valueColor: AlwaysStoppedAnimation(c), minHeight: 2)),
        if (deal.tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 4, children: deal.tags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: AppTheme.steel.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
            child: Text(t, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
          )).toList()),
        ],
      ]),
    );
  }

  Color _stageColor(DealStage s) {
    switch (s) {
      case DealStage.lead: return AppTheme.textSecondary;
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

  // ========== Deal Priority ==========
  Widget _buildDealPriorityList(CrmProvider crm, List<_DealScore> scores) {
    if (scores.isEmpty) {
      return const Center(child: Text('暂无活跃项目', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: scores.length,
      itemBuilder: (context, index) => _dealPriorityCard(crm, scores[index], index + 1),
    );
  }

  Widget _dealPriorityCard(CrmProvider crm, _DealScore ds, int rank) {
    final signalColor = ds.signal.color;
    final urgencyLabel = ds.urgencyLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ds.deal.isStarred ? AppTheme.accentGold.withValues(alpha: 0.5) : signalColor.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 排名 + 信号灯 + 标题 + 星标
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('#$rank', style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ds.deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(ds.deal.contactName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
          GestureDetector(
            onTap: () => crm.toggleDealStar(ds.deal.id),
            child: Icon(ds.deal.isStarred ? Icons.star : Icons.star_border,
              color: ds.deal.isStarred ? AppTheme.accentGold : AppTheme.textSecondary, size: 22),
          ),
          const SizedBox(width: 6),
          // 信号灯
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(urgencyLabel, style: TextStyle(color: signalColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        // 数据行
        Row(children: [
          _dealMetric('金额', Formatters.currency(ds.deal.amount), AppTheme.accentGold),
          _dealMetric('概率', '${ds.deal.probability.toInt()}%', AppTheme.primaryPurple),
          _dealMetric('加权值', Formatters.currency(ds.weightedValue), AppTheme.primaryBlue),
          _dealMetric('剩余天数', ds.daysToClose <= 0 ? '已过期!' : '${ds.daysToClose}天', ds.daysToClose <= 7 ? AppTheme.danger : AppTheme.success),
        ]),
        const SizedBox(height: 8),
        // 优先级分数条
        Row(children: [
          const Text('优先级: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (ds.score / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.cardBgLight,
              valueColor: AlwaysStoppedAnimation(signalColor),
              minHeight: 4,
            ),
          )),
          const SizedBox(width: 8),
          Text('${ds.score.toStringAsFixed(0)}分', style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 11)),
        ]),
        // 建议行动
        if (ds.suggestedAction.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lightbulb_outline, color: signalColor, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(ds.suggestedAction, style: TextStyle(color: signalColor, fontSize: 11))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _dealMetric(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
    ]));
  }

  // ========== Contact Priority ==========
  Widget _buildContactPriorityList(CrmProvider crm, List<_ContactScore> scores) {
    if (scores.isEmpty) {
      return const Center(child: Text('暂无需跟进的联系人', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: scores.length,
      itemBuilder: (context, index) => _contactPriorityCard(context, crm, scores[index], index + 1),
    );
  }

  Widget _contactPriorityCard(BuildContext context, CrmProvider crm, _ContactScore cs, int rank) {
    final signalColor = cs.signal.color;
    final contact = cs.contact;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contact.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: signalColor.withValues(alpha: 0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // 排名
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('#$rank', style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(width: 10),
            // 头像
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: contact.myRelation.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(contact.name[0], style: TextStyle(color: contact.myRelation.color, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: contact.myRelation.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(contact.myRelation.label, style: TextStyle(color: contact.myRelation.color, fontSize: 9)),
                ),
              ]),
              Text('${contact.company} | ${contact.strength.label}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(cs.urgencyLabel, style: TextStyle(color: signalColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          // 数据指标
          Row(children: [
            _dealMetric('关联Deal', '${cs.dealCount}笔', AppTheme.primaryPurple),
            _dealMetric('管线金额', Formatters.currency(cs.pipelineValue), AppTheme.accentGold),
            _dealMetric('最后联系', cs.daysSinceLastContact == 0 ? '今天' : '${cs.daysSinceLastContact}天前',
              cs.daysSinceLastContact > 14 ? AppTheme.danger : (cs.daysSinceLastContact > 7 ? AppTheme.warning : AppTheme.success)),
            _dealMetric('人脉链接', '${cs.relationCount}人', AppTheme.primaryBlue),
          ]),
          const SizedBox(height: 8),
          // 分数条
          Row(children: [
            const Text('跟进优先: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (cs.score / 100).clamp(0.0, 1.0),
                backgroundColor: AppTheme.cardBgLight,
                valueColor: AlwaysStoppedAnimation(signalColor),
                minHeight: 4,
              ),
            )),
            const SizedBox(width: 8),
            Text('${cs.score.toStringAsFixed(0)}分', style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
          // 建议
          if (cs.suggestedAction.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: signalColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lightbulb_outline, color: signalColor, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(cs.suggestedAction, style: TextStyle(color: signalColor, fontSize: 11))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // ========== Scoring Algorithms ==========

  /// 项目优先级评分
  /// score = base_value(40%) + urgency(30%) + probability_stage(20%) + momentum(10%)
  List<_DealScore> _scoreDealPriority(CrmProvider crm) {
    final activeDeals = crm.deals.where((d) =>
      d.stage != DealStage.completed && d.stage != DealStage.lost).toList();

    if (activeDeals.isEmpty) return [];

    // Normalize amount
    double maxAmount = 0;
    for (final d in activeDeals) { if (d.amount > maxAmount) maxAmount = d.amount; }
    if (maxAmount == 0) maxAmount = 1;

    final scores = <_DealScore>[];
    final now = DateTime.now();

    for (final deal in activeDeals) {
      // 1. 基础价值 (amount × probability) normalized
      final weightedValue = deal.amount * deal.probability / 100;
      final baseScore = (deal.amount / maxAmount) * 40;

      // 2. 紧急度 (距预计成交日越近 → 越高分, 已过期 → 满分)
      final daysToClose = deal.expectedCloseDate.difference(now).inDays;
      double urgencyScore;
      if (daysToClose <= 0) {
        urgencyScore = 30; // 已过期，最紧急
      } else if (daysToClose <= 7) {
        urgencyScore = 25;
      } else if (daysToClose <= 30) {
        urgencyScore = 20 - (daysToClose - 7) * 0.3;
      } else {
        urgencyScore = max(5, 15 - daysToClose * 0.1);
      }

      // 3. 阶段 × 概率 (越接近成交 → 越值得推)
      final stageWeight = deal.stage.order / 10;
      final probScore = (deal.probability / 100) * 15 + stageWeight * 5;

      // 4. 动量 (最近更新过 → 加分)
      final daysSinceUpdate = now.difference(deal.updatedAt).inDays;
      final momentumScore = daysSinceUpdate <= 3 ? 10 : (daysSinceUpdate <= 7 ? 7 : (daysSinceUpdate <= 14 ? 4 : 1));

      final totalScore = baseScore + urgencyScore + probScore + momentumScore;

      // 信号灯
      _Signal signal;
      if (daysToClose <= 0 || (totalScore >= 70 && daysToClose <= 14)) {
        signal = _Signal.red;
      } else if (totalScore >= 50 || daysToClose <= 30) {
        signal = _Signal.yellow;
      } else {
        signal = _Signal.green;
      }

      // 建议行动
      String action = '';
      if (daysToClose <= 0) {
        action = '⚠️ 已过预计成交日! 立即联系${deal.contactName}确认项目状态';
      } else if (daysToClose <= 7) {
        action = '🔥 ${daysToClose}天后到期, 概率${deal.probability.toInt()}%, 建议本周内推进到下一阶段';
      } else if (deal.probability >= 70 && deal.stage.order < 4) {
        action = '💰 高概率项目但阶段偏低, 建议加速推进到${DealStage.values[min(deal.stage.order + 1, 10)].label}';
      } else if (daysSinceUpdate > 14) {
        action = '⏰ 超过${daysSinceUpdate}天未更新, 建议联系${deal.contactName}获取最新进展';
      } else if (deal.amount >= maxAmount * 0.5 && deal.probability < 50) {
        action = '📊 大额项目但成交概率偏低(${deal.probability.toInt()}%), 重点分析阻碍因素';
      }

      scores.add(_DealScore(
        deal: deal, score: totalScore, weightedValue: weightedValue,
        daysToClose: daysToClose, signal: signal, suggestedAction: action,
      ));
    }

    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }

  /// 联系人跟进优先级评分
  /// score = deal_value(35%) + cooling(30%) + relationship(20%) + network(15%)
  List<_ContactScore> _scoreContactPriority(CrmProvider crm) {
    final contacts = crm.allContacts;
    if (contacts.isEmpty) return [];

    final now = DateTime.now();
    final scores = <_ContactScore>[];

    // Max pipeline value for normalization
    double maxPipeline = 0;
    for (final c in contacts) {
      double cv = 0;
      for (final d in crm.deals.where((d) =>
        d.contactId == c.id && d.stage != DealStage.completed && d.stage != DealStage.lost)) {
        cv += d.amount;
      }
      if (cv > maxPipeline) maxPipeline = cv;
    }
    if (maxPipeline == 0) maxPipeline = 1;

    for (final contact in contacts) {
      final activeDeals = crm.deals.where((d) =>
        d.contactId == contact.id && d.stage != DealStage.completed && d.stage != DealStage.lost).toList();
      double pipelineValue = 0;
      for (final d in activeDeals) { pipelineValue += d.amount; }

      final daysSinceLastContact = now.difference(contact.lastContactedAt).inDays;
      final relationCount = crm.getRelationsForContact(contact.id).length;

      // 1. Deal价值 (35%)
      final dealValueScore = (pipelineValue / maxPipeline) * 35;

      // 2. 冷却衰减 (30%): 越久没联系 → 分数越高 → 越需要跟
      double coolingScore;
      if (daysSinceLastContact <= 3) {
        coolingScore = 5; // 刚联系过，不急
      } else if (daysSinceLastContact <= 7) {
        coolingScore = 12;
      } else if (daysSinceLastContact <= 14) {
        coolingScore = 20;
      } else if (daysSinceLastContact <= 30) {
        coolingScore = 28;
      } else {
        coolingScore = 30; // 一个月没联系，最紧急
      }

      // 3. 关系维度 (20%): 核心关系 + 角色重要性
      double relScore = contact.strength.value * 5.0; // hot=15, warm=10, cool=5, cold=0
      if (contact.myRelation.isMedChannel) relScore += 5; // 医疗渠道加分

      // 4. 人脉网络 (15%): 关联关系越多 → 越是关键节点
      final networkScore = min(15.0, relationCount * 3.0);

      final totalScore = dealValueScore + coolingScore + relScore + networkScore;

      // 信号灯
      _Signal signal;
      if ((daysSinceLastContact > 14 && pipelineValue > 0) || totalScore >= 70) {
        signal = _Signal.red;
      } else if (daysSinceLastContact > 7 || totalScore >= 45) {
        signal = _Signal.yellow;
      } else {
        signal = _Signal.green;
      }

      // 建议
      String action = '';
      if (daysSinceLastContact > 30 && pipelineValue > 0) {
        action = '🚨 超过一个月未联系! 管线金额${Formatters.currency(pipelineValue)}, 立即安排沟通';
      } else if (daysSinceLastContact > 14 && pipelineValue > 0) {
        action = '⏰ ${daysSinceLastContact}天未联系, 有${activeDeals.length}笔活跃Deal, 建议本周跟进';
      } else if (contact.strength == RelationshipStrength.hot && daysSinceLastContact > 7) {
        action = '⭐ 核心人脉${daysSinceLastContact}天未联系, 建议维护关系';
      } else if (relationCount >= 3) {
        action = '🔗 关键节点人脉(关联${relationCount}人), 注意维护以扩大影响力';
      } else if (activeDeals.isNotEmpty && activeDeals.any((d) => d.probability >= 60)) {
        action = '💰 有高概率项目, 保持密切沟通推进成交';
      }

      // Only include contacts that have deals, or haven't been contacted recently, or are hot relationships
      if (pipelineValue > 0 || daysSinceLastContact > 7 || contact.strength == RelationshipStrength.hot || relationCount >= 2) {
        scores.add(_ContactScore(
          contact: contact, score: totalScore, pipelineValue: pipelineValue,
          dealCount: activeDeals.length, daysSinceLastContact: daysSinceLastContact,
          relationCount: relationCount, signal: signal, suggestedAction: action,
        ));
      }
    }

    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }
}

// ========== Data Classes ==========

enum _Signal {
  red(Color(0xFFFF6348)),
  yellow(Color(0xFFFFA502)),
  green(Color(0xFF2ED573));

  final Color color;
  const _Signal(this.color);
}

class _DealScore {
  final Deal deal;
  final double score;
  final double weightedValue;
  final int daysToClose;
  final _Signal signal;
  final String suggestedAction;

  _DealScore({
    required this.deal, required this.score, required this.weightedValue,
    required this.daysToClose, required this.signal, this.suggestedAction = '',
  });

  String get urgencyLabel {
    switch (signal) {
      case _Signal.red: return '紧急';
      case _Signal.yellow: return '关注';
      case _Signal.green: return '正常';
    }
  }
}

class _ContactScore {
  final Contact contact;
  final double score;
  final double pipelineValue;
  final int dealCount;
  final int daysSinceLastContact;
  final int relationCount;
  final _Signal signal;
  final String suggestedAction;

  _ContactScore({
    required this.contact, required this.score, required this.pipelineValue,
    required this.dealCount, required this.daysSinceLastContact,
    required this.relationCount, required this.signal, this.suggestedAction = '',
  });

  String get urgencyLabel {
    switch (signal) {
      case _Signal.red: return '紧急跟进';
      case _Signal.yellow: return '需关注';
      case _Signal.green: return '正常';
    }
  }
}
