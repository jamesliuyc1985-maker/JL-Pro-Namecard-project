import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

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

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, crm, contact)),
              SliverToBoxAdapter(child: _buildRelationBadges(contact)),
              SliverToBoxAdapter(child: _buildInfoCards(context, contact)),
              SliverToBoxAdapter(child: _buildActionButtons(context, crm, contact)),
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

  // ========== Communication ==========
  void _makeCall(BuildContext context, String phone) async {
    if (phone.isEmpty) { _showSnack(context, '无电话号码'); return; }
    try { await launchUrl(Uri.parse('tel:$phone')); } catch (_) { if (context.mounted) _showSnack(context, '无法拨打 $phone'); }
  }

  void _sendSms(BuildContext context, String phone) async {
    if (phone.isEmpty) { _showSnack(context, '无电话号码'); return; }
    try { await launchUrl(Uri.parse('sms:$phone')); } catch (_) { if (context.mounted) _showSnack(context, '无法发送短信'); }
  }

  void _sendEmail(BuildContext context, String email, String name) async {
    if (email.isEmpty) { _showSnack(context, '无邮箱地址'); return; }
    try { await launchUrl(Uri.parse('mailto:$email?subject=Re: $name')); } catch (_) { if (context.mounted) _showSnack(context, '无法发送邮件'); }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.danger, duration: const Duration(seconds: 2)));
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
        const Text('关联案件', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
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
