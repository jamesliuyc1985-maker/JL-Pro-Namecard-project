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
        return SafeArea(
          child: Column(children: [
            _buildHeader(context, crm),
            _buildSearchBar(crm),
            _buildIndustryChips(crm),
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
