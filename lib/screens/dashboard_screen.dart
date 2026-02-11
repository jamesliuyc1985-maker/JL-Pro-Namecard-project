import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'contact_detail_screen.dart';
import 'scan_card_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(
      builder: (context, crm, _) {
        final stats = crm.stats;
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildKpiCards(stats)),
              SliverToBoxAdapter(child: _buildSectionTitle('最近动态')),
              SliverToBoxAdapter(child: _buildRecentInteractions(context, crm)),
              SliverToBoxAdapter(child: _buildSectionTitle('重点案件')),
              SliverToBoxAdapter(child: _buildHotDeals(context, crm)),
              SliverToBoxAdapter(child: _buildSectionTitle('需要跟进')),
              SliverToBoxAdapter(child: _buildFollowUpContacts(context, crm)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('JL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deal Navigator', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                SizedBox(height: 2),
                Text('James Liu', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryBlue, size: 24),
            onPressed: () async {
              final crm = Provider.of<CrmProvider>(context, listen: false);
              await crm.syncFromCloud();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(crm.syncStatus ?? '同步完成'),
                    backgroundColor: crm.syncStatus?.contains('失败') == true ? Colors.red : AppTheme.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.document_scanner, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanCardScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.7,
        children: [
          _kpiCard('人脉总数', '${stats['totalContacts']}', Icons.people, AppTheme.primaryPurple),
          _kpiCard('进行中案件', '${stats['activeDeals']}', Icons.trending_up, AppTheme.primaryBlue),
          _kpiCard('管线总额', Formatters.currency(stats['pipelineValue'] as double), Icons.account_balance_wallet, AppTheme.success),
          _kpiCard('成交额', Formatters.currency(stats['closedValue'] as double), Icons.check_circle, AppTheme.accentGold),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRecentInteractions(BuildContext context, CrmProvider crm) {
    final recent = crm.interactions.take(5).toList();
    if (recent.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('暂无记录', style: TextStyle(color: AppTheme.textSecondary)));
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recent.length,
        itemBuilder: (context, index) {
          final i = recent[index];
          return Container(
            width: 220, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_interactionIcon(i.type), color: AppTheme.primaryPurple, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(i.contactName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 6),
              Text(i.title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text(Formatters.timeAgo(i.date), style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildHotDeals(BuildContext context, CrmProvider crm) {
    final hotDeals = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: hotDeals.take(4).map((deal) {
        final stageColor = _stageColor(deal.stage);
        return Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 4, height: 44, decoration: BoxDecoration(color: stageColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('${deal.contactName} | ${deal.stage.label}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${deal.probability.toInt()}%', style: TextStyle(color: stageColor, fontSize: 12)),
            ]),
          ]),
        );
      }).toList()),
    );
  }

  Widget _buildFollowUpContacts(BuildContext context, CrmProvider crm) {
    final stale = crm.allContacts.where((c) => DateTime.now().difference(c.lastContactedAt).inDays > 14).take(5).toList();
    if (stale.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text('全部已跟进！', style: TextStyle(color: AppTheme.success)));
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stale.length,
        itemBuilder: (context, index) {
          final c = stale[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))),
            child: Container(
              width: 160, margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 3),
                Text(c.company, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(Formatters.timeAgo(c.lastContactedAt), style: const TextStyle(color: AppTheme.danger, fontSize: 11)),
              ]),
            ),
          );
        },
      ),
    );
  }

  IconData _interactionIcon(InteractionType type) {
    switch (type) {
      case InteractionType.meeting: return Icons.groups;
      case InteractionType.call: return Icons.phone;
      case InteractionType.email: return Icons.email;
      case InteractionType.dinner: return Icons.restaurant;
      case InteractionType.introduction: return Icons.handshake;
      case InteractionType.other: return Icons.note;
    }
  }

  Color _stageColor(DealStage stage) {
    switch (stage) {
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
