import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../models/product.dart';
import '../models/contact_assignment.dart';
import '../models/team.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'edit_contact_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(
      builder: (context, crm, _) {
        final contact = crm.getContact(contactId);
        if (contact == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('未找到联系人')));
        final deals = crm.getDealsByContact(contactId);
        final interactions = crm.getInteractionsByContact(contactId);
        final relations = crm.getRelationsForContact(contactId);
        final assignments = crm.getAssignmentsByContact(contactId);
        final salesStats = crm.getContactSalesStats(contactId);

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, crm, contact)),
              SliverToBoxAdapter(child: _buildRelationBadges(contact)),
              SliverToBoxAdapter(child: _buildInfoCards(context, contact)),
              SliverToBoxAdapter(child: _buildActionButtons(context, crm, contact)),
              // === 销售统计板块 (新增) ===
              SliverToBoxAdapter(child: _buildSalesStatsSection(salesStats)),
              // === 合作历史/订单板块 (新增) ===
              SliverToBoxAdapter(child: _buildOrderHistorySection(crm, salesStats)),
              SliverToBoxAdapter(child: _buildAssignmentSection(context, crm, contact, assignments)),
              if (relations.isNotEmpty) SliverToBoxAdapter(child: _buildRelationsSection(relations)),
              if (deals.isNotEmpty) SliverToBoxAdapter(child: _buildDealsSection(deals)),
              SliverToBoxAdapter(child: _buildInteractionsSection(context, crm, contact, interactions)),
              if (contact.notes.isNotEmpty) SliverToBoxAdapter(child: _buildNotesSection(contact)),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm, Contact contact) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [contact.industry.color.withValues(alpha: 0.3), AppTheme.darkBg], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryPurple, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditContactScreen(contactId: contact.id))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 22),
            onPressed: () => _confirmDelete(context, crm, contact),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [contact.industry.color, contact.industry.color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(22)),
          child: Center(child: Text(contact.name.isNotEmpty ? contact.name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 12),
        Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        if (contact.nameReading.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(contact.nameReading, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
        const SizedBox(height: 6),
        Text('${contact.company} | ${contact.position}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, CrmProvider crm, Contact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('删除联系人', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('确定删除 ${contact.name}？\n相关的互动记录和关系也将被删除。', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              crm.deleteContact(contact.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${contact.name} 已删除'), backgroundColor: AppTheme.danger),
              );
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationBadges(Contact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _badge(contact.industry.label, contact.industry.color, contact.industry.icon),
        const SizedBox(width: 8),
        _badge('与我：${contact.myRelation.label}', contact.myRelation.color, Icons.link),
        const SizedBox(width: 8),
        _badge(contact.strength.label, contact.strength.color, Icons.circle, iconSize: 8),
      ]),
    );
  }

  Widget _badge(String text, Color color, IconData icon, {double iconSize = 14}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildInfoCards(BuildContext context, Contact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        if (contact.phone.isNotEmpty) _infoRowTappable(Icons.phone, contact.phone, AppTheme.primaryBlue, () => _makeCall(context, contact.phone)),
        if (contact.email.isNotEmpty) _infoRowTappable(Icons.email, contact.email, AppTheme.primaryPurple, () => _sendEmail(context, contact.email, contact.name)),
        if (contact.address.isNotEmpty) _infoRow(Icons.location_on, contact.address, AppTheme.success),
        if (contact.nationality.isNotEmpty) _infoRow(Icons.flag, '国籍: ${contact.nationality}', AppTheme.info),
        if (contact.referredBy.isNotEmpty) _infoRow(Icons.handshake, '引荐人: ${contact.referredBy}', AppTheme.warning),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)))]),
    );
  }

  Widget _infoRowTappable(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: color, size: 18), const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, decoration: TextDecoration.underline))),
          Icon(Icons.open_in_new, color: color.withValues(alpha: 0.6), size: 14),
        ]),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CrmProvider crm, Contact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _actionBtn(Icons.phone, '电话', AppTheme.primaryBlue, () => _makeCall(context, contact.phone))),
        const SizedBox(width: 8),
        Expanded(child: _actionBtn(Icons.sms, '短信', AppTheme.success, () => _sendSms(context, contact.phone))),
        const SizedBox(width: 8),
        Expanded(child: _actionBtn(Icons.email, '邮件', AppTheme.primaryPurple, () => _sendEmail(context, contact.email, contact.name))),
        const SizedBox(width: 8),
        Expanded(child: _actionBtn(Icons.note_add, '记录', AppTheme.warning, () => _showAddInteractionDialog(context, crm, contact))),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  // ========== 销售统计板块 (新增) ==========
  Widget _buildSalesStatsSection(Map<String, dynamic> stats) {
    final int totalOrders = stats['totalOrders'] ?? 0;
    final double totalAmount = (stats['totalAmount'] ?? 0).toDouble();
    final int completedOrders = stats['completedOrders'] ?? 0;
    final double completedAmount = (stats['completedAmount'] ?? 0).toDouble();
    final int activeDeals = stats['activeDeals'] ?? 0;
    final double pipelineValue = (stats['pipelineValue'] ?? 0).toDouble();

    if (totalOrders == 0 && activeDeals == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.analytics, color: AppTheme.accentGold, size: 18),
            const SizedBox(width: 6),
            const Text('销售统计', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('暂无销售记录', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          ),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.analytics, color: AppTheme.accentGold, size: 18),
          const SizedBox(width: 6),
          const Text('销售统计', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        // KPI row
        Row(children: [
          Expanded(child: _statCard('总订单', '$totalOrders', AppTheme.primaryPurple, Icons.receipt_long)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('订单总额', Formatters.currency(totalAmount), AppTheme.accentGold, Icons.monetization_on)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _statCard('已完成', '$completedOrders 单', AppTheme.success, Icons.check_circle)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('成交额', Formatters.currency(completedAmount), AppTheme.success, Icons.paid)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _statCard('进行中', '$activeDeals 案件', AppTheme.primaryBlue, Icons.trending_up)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('管线价值', Formatters.currency(pipelineValue), AppTheme.warning, Icons.account_balance_wallet)),
        ]),
      ]),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ])),
      ]),
    );
  }

  // ========== 合作历史/订单板块 (新增) ==========
  Widget _buildOrderHistorySection(CrmProvider crm, Map<String, dynamic> stats) {
    final List<SalesOrder> contactOrders = (stats['orders'] as List<SalesOrder>?) ?? [];
    if (contactOrders.isEmpty) return const SizedBox.shrink();

    // 按时间倒序
    final sorted = List<SalesOrder>.from(contactOrders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(width: 6),
          Text('合作历史 (${sorted.length}单)', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ...sorted.map((order) {
          final statusColor = _orderStatusColor(order.status);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.receipt, color: statusColor, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  '订单 ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(SalesOrder.statusLabel(order.status), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 6),
              // 产品明细
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 2),
                child: Row(children: [
                  const Icon(Icons.circle, color: AppTheme.textSecondary, size: 4),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${item.productName} x${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                  Text(Formatters.currency(item.subtotal), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ]),
              )),
              const SizedBox(height: 4),
              Row(children: [
                Text(Formatters.dateShort(order.createdAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                const Spacer(),
                Text(Formatters.currency(order.totalAmount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'draft': return AppTheme.textSecondary;
      case 'confirmed': return AppTheme.warning;
      case 'shipped': return const Color(0xFF74B9FF);
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  // ========== Communication ==========
  void _makeCall(BuildContext context, String phone) async {
    if (phone.isEmpty) { _showSnack(context, '无电话号码'); return; }
    final uri = Uri.parse('tel:$phone');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) { _showSnack(context, '无法拨打 $phone（请在手机上试）'); }
    } catch (_) { if (context.mounted) { _showSnack(context, '无法拨打 $phone'); } }
  }

  void _sendSms(BuildContext context, String phone) async {
    if (phone.isEmpty) { _showSnack(context, '无电话号码'); return; }
    final uri = Uri.parse('sms:$phone');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) { _showSnack(context, '无法发送短信（请在手机上试）'); }
    } catch (_) { if (context.mounted) { _showSnack(context, '无法发送短信'); } }
  }

  void _sendEmail(BuildContext context, String email, String name) async {
    if (email.isEmpty) { _showSnack(context, '无邮箱地址'); return; }
    final uri = Uri.parse('mailto:$email?subject=Re: $name&body=Dear $name,%0A%0A');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) { _showSnack(context, '无法发送邮件（请在手机上试）'); }
    } catch (_) { if (context.mounted) { _showSnack(context, '无法发送邮件'); } }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.danger, duration: const Duration(seconds: 2)));
  }

  // ========== Contact Assignment (Team-Contact Work Stage) ==========
  Widget _buildAssignmentSection(BuildContext context, CrmProvider crm, Contact contact, List<ContactAssignment> assignments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('负责人 / 工作阶段', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddAssignmentDialog(context, crm, contact),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(8)),
              child: const Text('+ 指派', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (assignments.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('暂无指派（可选配置）', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          )
        else
          ...assignments.map((a) {
            final stageColor = _workStageColor(a.stage);
            return Container(
              margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: stageColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(a.memberName.isNotEmpty ? a.memberName[0] : '?',
                    style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.memberName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  if (a.notes.isNotEmpty) Text(a.notes, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: stageColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(a.stage.label, style: TextStyle(color: stageColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 16),
                  color: AppTheme.cardBgLight,
                  onSelected: (action) {
                    if (action == 'delete') {
                      crm.deleteAssignment(a.id);
                    } else {
                      final newStage = ContactWorkStage.values.firstWhere((s) => s.name == action);
                      a.stage = newStage;
                      a.updatedAt = DateTime.now();
                      crm.updateAssignment(a);
                    }
                  },
                  itemBuilder: (_) => [
                    ...ContactWorkStage.values.where((s) => s != a.stage).map((s) => PopupMenuItem(
                      value: s.name,
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _workStageColor(s), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(s.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                      ]),
                    )),
                    const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: AppTheme.danger, fontSize: 12))),
                  ],
                ),
              ]),
            );
          }),
      ]),
    );
  }

  Color _workStageColor(ContactWorkStage stage) {
    switch (stage) {
      case ContactWorkStage.lead: return AppTheme.textSecondary;
      case ContactWorkStage.contacted: return AppTheme.primaryBlue;
      case ContactWorkStage.ongoing: return AppTheme.warning;
      case ContactWorkStage.negotiation: return AppTheme.primaryPurple;
      case ContactWorkStage.ordered: return const Color(0xFF00CEC9);
      case ContactWorkStage.closed: return AppTheme.success;
    }
  }

  void _showAddAssignmentDialog(BuildContext context, CrmProvider crm, Contact contact) {
    String? selectedMemberId;
    String selectedMemberName = '';
    ContactWorkStage selectedStage = ContactWorkStage.lead;
    final notesCtrl = TextEditingController();
    final members = crm.teamMembers;

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在团队板块中添加成员'), backgroundColor: AppTheme.warning));
      return;
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('指派成员负责 ${contact.name}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedMemberId,
                decoration: const InputDecoration(labelText: '选择团队成员', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 20)),
                dropdownColor: AppTheme.cardBgLight,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: members.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${TeamMember.roleLabel(m.role)})', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() {
                  selectedMemberId = v;
                  selectedMemberName = members.firstWhere((m) => m.id == v).name;
                }),
              ),
              const SizedBox(height: 12),
              const Text('工作阶段', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: ContactWorkStage.values.map((stage) {
                final color = _workStageColor(stage);
                return ChoiceChip(
                  label: Text(stage.label), selected: selectedStage == stage,
                  onSelected: (_) => setModalState(() => selectedStage = stage),
                  selectedColor: color, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: selectedStage == stage ? Colors.white : AppTheme.textPrimary, fontSize: 11),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                );
              }).toList()),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: selectedMemberId == null ? null : () {
                  crm.addAssignment(ContactAssignment(
                    id: crm.generateId(),
                    memberId: selectedMemberId!,
                    memberName: selectedMemberName,
                    contactId: contact.id,
                    contactName: contact.name,
                    stage: selectedStage,
                    notes: notesCtrl.text,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$selectedMemberName 已被指派负责 ${contact.name}'), backgroundColor: AppTheme.success));
                },
                child: const Text('确认指派'),
              )),
              const SizedBox(height: 16),
            ]),
          );
        });
      },
    );
  }

  // ========== Sections ==========
  Widget _buildRelationsSection(List<ContactRelation> relations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('人脉关联', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...relations.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.link, color: AppTheme.accentGold, size: 16), const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.fromName} ↔ ${r.toName}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              if (r.description.isNotEmpty) Text(r.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(r.relationType, style: const TextStyle(color: AppTheme.accentGold, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildDealsSection(List<Deal> deals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('销售管线', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...deals.map((deal) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deal.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 3),
              Text(deal.stage.label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildInteractionsSection(BuildContext context, CrmProvider crm, Contact contact, List<Interaction> interactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('互动记录', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddInteractionDialog(context, crm, contact),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(8)),
              child: const Text('+ 新增', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (interactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('暂无记录', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ...interactions.map((i) => Container(
            margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(_typeIcon(i.type), color: AppTheme.primaryPurple, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                if (i.notes.isNotEmpty) ...[const SizedBox(height: 3), Text(i.notes, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)],
              ])),
              Text(Formatters.dateShort(i.date), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          )),
      ]),
    );
  }

  Widget _buildNotesSection(Contact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('备注', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Text(contact.notes, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  IconData _typeIcon(InteractionType type) {
    switch (type) {
      case InteractionType.meeting: return Icons.groups;
      case InteractionType.call: return Icons.phone;
      case InteractionType.email: return Icons.email;
      case InteractionType.dinner: return Icons.restaurant;
      case InteractionType.introduction: return Icons.handshake;
      case InteractionType.other: return Icons.note;
    }
  }

  void _showAddInteractionDialog(BuildContext context, CrmProvider crm, Contact contact) {
    InteractionType selectedType = InteractionType.meeting;
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('记录互动', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: InteractionType.values.map((type) {
                final isSelected = selectedType == type;
                return ChoiceChip(label: Text(type.label), selected: isSelected, onSelected: (_) => setModalState(() => selectedType = type),
                  selectedColor: AppTheme.primaryPurple, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12));
              }).toList()),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: '标题')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 3, decoration: const InputDecoration(hintText: '备注')),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    crm.addInteraction(Interaction(id: crm.generateId(), contactId: contact.id, contactName: contact.name, type: selectedType, title: titleCtrl.text, notes: notesCtrl.text));
                    Navigator.pop(ctx);
                  }
                }, child: const Text('保存'))),
              const SizedBox(height: 16),
            ]),
          );
        });
      },
    );
  }
}
