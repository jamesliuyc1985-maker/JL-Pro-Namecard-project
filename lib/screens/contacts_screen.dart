import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'contact_detail_screen.dart';
import 'add_contact_screen.dart';
import 'scan_card_screen.dart';
import 'excel_import_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(
      builder: (context, crm, _) {
        final contacts = crm.contacts;
        final bizContacts = crm.allContacts.where((c) => c.myRelation.isMedChannel).toList();
        return SafeArea(
          child: Column(children: [
            _buildHeader(context, crm),
            _buildSearchBar(crm),
            _buildIndustryChips(crm),
            if (bizContacts.isNotEmpty) _buildBusinessRelBar(context, bizContacts),
            _buildContactCount(contacts.length),
            Expanded(child: _buildContactList(context, contacts)),
          ]),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 4, 4),
      child: Row(children: [
        const Text('人脉网络', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          tooltip: 'Excel导入',
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.upload_file, color: AppTheme.success, size: 20)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExcelImportScreen())),
        ),
        IconButton(
          tooltip: '名片扫描',
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.document_scanner, color: AppTheme.primaryPurple, size: 20)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanCardScreen())),
        ),
        IconButton(
          tooltip: '手动添加',
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_add, color: Colors.white, size: 20)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContactScreen())),
        ),
      ]),
    );
  }

  Widget _buildSearchBar(CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        onChanged: crm.setSearchQuery,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: '搜索姓名、公司...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: crm.searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18), onPressed: () => crm.setSearchQuery(''))
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildIndustryChips(CrmProvider crm) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        children: Industry.values.map((industry) {
          final isSelected = crm.selectedIndustry == industry;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(industry.icon, size: 14, color: isSelected ? Colors.white : industry.color),
                const SizedBox(width: 4),
                Text(industry.label),
              ]),
              onSelected: (_) => crm.setIndustryFilter(industry),
              selectedColor: industry.color, checkmarkColor: Colors.white, backgroundColor: AppTheme.cardBgLight,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBusinessRelBar(BuildContext context, List<Contact> bizContacts) {
    final agents = bizContacts.where((c) => c.myRelation == MyRelationType.agent).toList();
    final clinics = bizContacts.where((c) => c.myRelation == MyRelationType.clinic).toList();
    final retailers = bizContacts.where((c) => c.myRelation == MyRelationType.retailer).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple.withValues(alpha: 0.1), AppTheme.primaryBlue.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.storefront, color: AppTheme.accentGold, size: 16),
          SizedBox(width: 6),
          Text('\u4E1A\u52A1\u5173\u7CFB \u00B7 \u4E0B\u5355\u7528', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _bizChip('\u4EE3\u7406', agents.length, MyRelationType.agent.color),
              const SizedBox(width: 6),
              _bizChip('\u8BCA\u6240', clinics.length, MyRelationType.clinic.color),
              const SizedBox(width: 6),
              _bizChip('\u96F6\u552E', retailers.length, MyRelationType.retailer.color),
              const SizedBox(width: 12),
              ...bizContacts.take(8).map((c) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: c.id))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.myRelation.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(color: c.myRelation.color.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: Center(child: Text(c.name.isNotEmpty ? c.name[0] : '?', style: TextStyle(color: c.myRelation.color, fontSize: 10, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 4),
                      Text(c.name, style: TextStyle(color: c.myRelation.color, fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              )),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _bizChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildContactCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(children: [Text('共 $count 人', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))]),
    );
  }

  Widget _buildContactList(BuildContext context, List<Contact> contacts) {
    if (contacts.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_search, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('未找到联系人', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contacts.length,
      itemBuilder: (context, index) => _contactCard(context, contacts[index]),
    );
  }

  Widget _contactCard(BuildContext context, Contact contact) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contact.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: contact.industry.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(contact.name.isNotEmpty ? contact.name[0] : '?', style: TextStyle(color: contact.industry.color, fontWeight: FontWeight.bold, fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15))),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: contact.strength.color, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 2),
            Text('${contact.company} | ${contact.position}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: contact.industry.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(contact.industry.label, style: TextStyle(color: contact.industry.color, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: contact.myRelation.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(contact.myRelation.label, style: TextStyle(color: contact.myRelation.color, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              if (contact.nationality.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(contact.nationality, style: const TextStyle(color: AppTheme.info, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              Text(Formatters.timeAgo(contact.lastContactedAt), style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
