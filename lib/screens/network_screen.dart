import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';
import 'contact_detail_screen.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});
  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  String? _selectedContactId;
  final TransformationController _transformController = TransformationController();
  String _relationFilter = 'all'; // 'all', 'me', 'third-party'

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(
      builder: (context, crm, _) {
        final contacts = crm.allContacts;
        final selectedContact = _selectedContactId != null ? crm.getContact(_selectedContactId!) : null;
        final salesContactIds = crm.contactsWithSales;

        return SafeArea(
          child: Column(children: [
            _buildHeader(context, crm),
            _buildFilterChips(crm),
            if (selectedContact != null) _buildSelectedInfo(context, crm, selectedContact, salesContactIds),
            _buildLegend(salesContactIds.length, crm.relations.length),
            Expanded(child: _buildNetworkGraph(context, crm, contacts, salesContactIds)),
            _buildRelationsList(context, crm),
          ]),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Text('人脉图谱', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (_selectedContactId != null)
          TextButton(
            onPressed: () => setState(() => _selectedContactId = null),
            child: const Text('查看全部', style: TextStyle(fontSize: 13)),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_link, color: Colors.white, size: 20),
          ),
          onPressed: () => _showAddRelationDialog(context, crm),
        ),
      ]),
    );
  }

  Widget _buildFilterChips(CrmProvider crm) {
    // Count third-party relations (where neither from nor to is "me")
    final thirdPartyCount = crm.relations.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        _filterChip('全部', 'all', AppTheme.primaryBlue),
        const SizedBox(width: 6),
        _filterChip('我的关系', 'me', AppTheme.primaryPurple),
        const SizedBox(width: 6),
        _filterChip('第三方关系 ($thirdPartyCount)', 'third-party', AppTheme.accentGold),
      ]),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _relationFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _relationFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppTheme.textSecondary.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : AppTheme.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildLegend(int salesCount, int relationsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 26,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _legendItem('我', AppTheme.accentGold),
            ...MyRelationType.values.take(6).map((r) => _legendItem(r.label, r.color)),
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentGold, width: 2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('销售线索 ($salesCount)', style: const TextStyle(color: AppTheme.accentGold, fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 14, height: 3, decoration: BoxDecoration(color: const Color(0xFFFF6348), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('第三方关系 ($relationsCount)', style: const TextStyle(color: Color(0xFFFF6348), fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildSelectedInfo(BuildContext context, CrmProvider crm, Contact contact, Set<String> salesIds) {
    final relatedRelations = crm.getRelationsForContact(contact.id);
    final hasSales = salesIds.contains(contact.id);
    // Count tags across all relations for this contact
    final allTags = <String>{};
    for (final r in relatedRelations) {
      allTags.addAll(r.tags);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasSales ? AppTheme.accentGold : contact.myRelation.color.withValues(alpha: 0.5), width: hasSales ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: contact.myRelation.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(contact.name[0], style: TextStyle(color: contact.myRelation.color, fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              if (hasSales) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department, color: AppTheme.accentGold, size: 10),
                    SizedBox(width: 2),
                    Text('销售线索', style: TextStyle(color: AppTheme.accentGold, fontSize: 9, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
            Text('${contact.myRelation.label} | ${contact.company} | 关联${relatedRelations.length}人',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppTheme.primaryPurple, size: 18),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contact.id))),
          ),
        ]),
        // Show aggregated tags
        if (allTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 4, runSpacing: 4, children: allTags.map((tag) {
            final c = ContactRelation.tagColor(tag);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withValues(alpha: 0.3))),
              child: Text(tag, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
            );
          }).toList()),
        ],
      ]),
    );
  }

  Widget _buildNetworkGraph(BuildContext context, CrmProvider crm, List<Contact> contacts, Set<String> salesIds) {
    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.3,
      maxScale: 3.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(max(constraints.maxWidth, 400), max(constraints.maxHeight, 400));
          return CustomPaint(
            size: size,
            painter: _NetworkPainter(
              contacts: contacts,
              relations: crm.relations,
              selectedId: _selectedContactId,
              centerSize: size,
              salesContactIds: salesIds,
              relationFilter: _relationFilter,
            ),
            child: SizedBox(
              width: size.width, height: size.height,
              child: Stack(
                children: [
                  // "我" node at center
                  Positioned(
                    left: size.width / 2 - 22,
                    top: size.height / 2 - 22,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedContactId = null),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.gradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentGold, width: 2),
                          boxShadow: [BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.4), blurRadius: 12)],
                        ),
                        child: const Center(child: Text('我', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                      ),
                    ),
                  ),
                  ..._buildContactNodes(contacts, size, salesIds),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContactNodes(List<Contact> contacts, Size size, Set<String> salesIds) {
    final center = Offset(size.width / 2, size.height / 2);
    final widgets = <Widget>[];

    final hotContacts = contacts.where((c) => c.strength == RelationshipStrength.hot).toList();
    final warmContacts = contacts.where((c) => c.strength == RelationshipStrength.warm).toList();
    final otherContacts = contacts.where((c) => c.strength != RelationshipStrength.hot && c.strength != RelationshipStrength.warm).toList();

    void addRing(List<Contact> list, double radius, double nodeSize) {
      for (int i = 0; i < list.length; i++) {
        final angle = (2 * pi * i / list.length) - pi / 2;
        final x = center.dx + radius * cos(angle) - nodeSize / 2;
        final y = center.dy + radius * sin(angle) - nodeSize / 2;
        final contact = list[i];
        final isSelected = _selectedContactId == contact.id;
        final hasSales = salesIds.contains(contact.id);

        widgets.add(Positioned(
          left: x, top: y,
          child: GestureDetector(
            onTap: () => setState(() => _selectedContactId = contact.id),
            child: Container(
              width: nodeSize, height: nodeSize,
              decoration: BoxDecoration(
                color: isSelected ? contact.myRelation.color : contact.myRelation.color.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasSales
                      ? AppTheme.accentGold
                      : (isSelected ? Colors.white : contact.myRelation.color),
                  width: hasSales ? 3 : (isSelected ? 2.5 : 1),
                ),
                boxShadow: [
                  if (isSelected) BoxShadow(color: contact.myRelation.color.withValues(alpha: 0.6), blurRadius: 10),
                  if (hasSales && !isSelected) BoxShadow(color: AppTheme.accentGold.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Text(
                      contact.name.length >= 2 ? contact.name.substring(contact.name.length - 2) : contact.name,
                      style: TextStyle(color: Colors.white, fontSize: nodeSize > 34 ? 11 : 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (hasSales)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.darkBg, width: 1.5),
                        ),
                        child: const Center(child: Icon(Icons.local_fire_department, color: Colors.white, size: 8)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
      }
    }

    addRing(hotContacts, min(size.width, size.height) * 0.2, 38);
    addRing(warmContacts, min(size.width, size.height) * 0.33, 34);
    addRing(otherContacts, min(size.width, size.height) * 0.44, 30);

    return widgets;
  }

  Widget _buildRelationsList(BuildContext context, CrmProvider crm) {
    var rels = _selectedContactId != null
        ? crm.getRelationsForContact(_selectedContactId!)
        : crm.relations;

    if (rels.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 130,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(_selectedContactId != null ? '相关关系' : '全部关系 (${rels.length})',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: rels.length,
            itemBuilder: (context, index) {
              final r = rels[index];
              return GestureDetector(
                onLongPress: () => _showEditRelationDialog(context, crm, r),
                child: Container(
                  width: 200, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [
                      Flexible(child: Text(r.fromName.length >= 2 ? r.fromName.substring(r.fromName.length - 2) : r.fromName,
                          style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.sync_alt, color: AppTheme.textSecondary, size: 12)),
                      Flexible(child: Text(r.toName.length >= 2 ? r.toName.substring(r.toName.length - 2) : r.toName,
                          style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(r.relationType, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10)),
                    ),
                    if (r.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(spacing: 3, runSpacing: 2, children: r.tags.take(3).map((tag) {
                        final c = ContactRelation.tagColor(tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(tag, style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w600)),
                        );
                      }).toList()),
                    ],
                    if (r.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(r.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ========== Add Relation Dialog ==========
  void _showAddRelationDialog(BuildContext context, CrmProvider crm) {
    Contact? from;
    Contact? to;
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final allContacts = crm.allContacts;
    final selectedTags = <String>{};

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.add_link, color: AppTheme.primaryPurple, size: 22),
                const SizedBox(width: 8),
                const Text('添加人脉关系', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 4),
              const Text('支持任意两个联系人之间建立关系和标签', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              DropdownButtonFormField<Contact>(
                initialValue: from,
                decoration: const InputDecoration(labelText: '联系人A', prefixIcon: Icon(Icons.person, color: AppTheme.primaryPurple, size: 20)),
                dropdownColor: AppTheme.cardBgLight,
                items: allContacts.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.company})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() => from = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Contact>(
                initialValue: to,
                decoration: const InputDecoration(labelText: '联系人B', prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryBlue, size: 20)),
                dropdownColor: AppTheme.cardBgLight,
                items: allContacts.where((c) => c.id != from?.id).map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.company})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() => to = v),
              ),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: '关系类型（如：同行、合伙人、客户）', prefixIcon: Icon(Icons.category, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 12),
              // Tags selection
              const Text('关系标签 (可多选)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: ContactRelation.presetTags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                final c = ContactRelation.tagColor(tag);
                return GestureDetector(
                  onTap: () => setModalState(() {
                    if (isSelected) { selectedTags.remove(tag); } else { selectedTags.add(tag); }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? c.withValues(alpha: 0.25) : AppTheme.cardBgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? c : AppTheme.textSecondary.withValues(alpha: 0.2), width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isSelected) ...[
                        Icon(Icons.check_circle, color: c, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(tag, style: TextStyle(color: isSelected ? c : AppTheme.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 2,
                decoration: const InputDecoration(hintText: '关系描述（可选）', prefixIcon: Icon(Icons.notes, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('建立关系'),
                  onPressed: () {
                    if (from != null && to != null && typeCtrl.text.isNotEmpty) {
                      crm.addRelation(ContactRelation(
                        id: crm.generateId(), fromContactId: from!.id, toContactId: to!.id,
                        fromName: from!.name, toName: to!.name,
                        relationType: typeCtrl.text, description: descCtrl.text,
                        tags: selectedTags.toList(),
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已建立 ${from!.name} ↔ ${to!.name} 的关系'), backgroundColor: AppTheme.success),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ])),
          );
        });
      },
    );
  }

  // ========== Edit Relation Dialog ==========
  void _showEditRelationDialog(BuildContext context, CrmProvider crm, ContactRelation relation) {
    final typeCtrl = TextEditingController(text: relation.relationType);
    final descCtrl = TextEditingController(text: relation.description);
    final selectedTags = <String>{...relation.tags};

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.edit, color: AppTheme.primaryPurple, size: 20),
                const SizedBox(width: 8),
                const Text('编辑关系', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                  onPressed: () {
                    crm.deleteRelation(relation.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('关系已删除'), backgroundColor: AppTheme.danger),
                    );
                  },
                ),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 8),
              // Show participants
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(relation.fromName.isNotEmpty ? relation.fromName[0] : '?', style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(relation.fromName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.sync_alt, color: AppTheme.textSecondary, size: 16)),
                  Text(relation.toName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(relation.toName.isNotEmpty ? relation.toName[0] : '?', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              TextField(controller: typeCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '关系类型')),
              const SizedBox(height: 12),
              const Text('关系标签', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: ContactRelation.presetTags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                final c = ContactRelation.tagColor(tag);
                return GestureDetector(
                  onTap: () => setModalState(() {
                    if (isSelected) { selectedTags.remove(tag); } else { selectedTags.add(tag); }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? c.withValues(alpha: 0.25) : AppTheme.cardBgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? c : AppTheme.textSecondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isSelected) ...[Icon(Icons.check_circle, color: c, size: 14), const SizedBox(width: 4)],
                      Text(tag, style: TextStyle(color: isSelected ? c : AppTheme.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 2,
                decoration: const InputDecoration(labelText: '描述')),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  relation.relationType = typeCtrl.text;
                  relation.description = descCtrl.text;
                  relation.tags = selectedTags.toList();
                  crm.updateRelation(relation);
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              )),
              const SizedBox(height: 16),
            ])),
          );
        });
      },
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final List<Contact> contacts;
  final List<ContactRelation> relations;
  final String? selectedId;
  final Size centerSize;
  final Set<String> salesContactIds;
  final String relationFilter;

  _NetworkPainter({
    required this.contacts,
    required this.relations,
    this.selectedId,
    required this.centerSize,
    required this.salesContactIds,
    required this.relationFilter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Build position map
    final posMap = <String, Offset>{};
    final hot = contacts.where((c) => c.strength == RelationshipStrength.hot).toList();
    final warm = contacts.where((c) => c.strength == RelationshipStrength.warm).toList();
    final other = contacts.where((c) => c.strength != RelationshipStrength.hot && c.strength != RelationshipStrength.warm).toList();

    void mapPositions(List<Contact> list, double radius) {
      for (int i = 0; i < list.length; i++) {
        final angle = (2 * pi * i / list.length) - pi / 2;
        posMap[list[i].id] = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      }
    }

    mapPositions(hot, min(size.width, size.height) * 0.2);
    mapPositions(warm, min(size.width, size.height) * 0.33);
    mapPositions(other, min(size.width, size.height) * 0.44);

    // Draw lines from center (me) to all contacts
    if (relationFilter == 'all' || relationFilter == 'me') {
      for (final c in contacts) {
        final pos = posMap[c.id];
        if (pos == null) continue;
        final hasSales = salesContactIds.contains(c.id);
        final paint = Paint()
          ..color = hasSales
              ? const Color(0xFFD4A017).withValues(alpha: selectedId == null || selectedId == c.id ? 0.5 : 0.15)
              : c.myRelation.color.withValues(alpha: selectedId == null || selectedId == c.id ? 0.3 : 0.08)
          ..strokeWidth = hasSales ? 2.5 : (c.strength == RelationshipStrength.hot ? 2 : 1);
        canvas.drawLine(center, pos, paint);
      }
    }

    // Draw lines between related contacts (third-party)
    if (relationFilter == 'all' || relationFilter == 'third-party') {
      for (final r in relations) {
        final fromPos = posMap[r.fromContactId];
        final toPos = posMap[r.toContactId];
        if (fromPos == null || toPos == null) continue;

        final isHighlighted = selectedId == null || selectedId == r.fromContactId || selectedId == r.toContactId;

        // Use tag color if tags exist, otherwise gold
        Color lineColor;
        if (r.tags.isNotEmpty) {
          lineColor = ContactRelation.tagColor(r.tags.first);
        } else {
          lineColor = const Color(0xFFFF6348);
        }

        final paint = Paint()
          ..color = lineColor.withValues(alpha: isHighlighted ? 0.7 : 0.15)
          ..strokeWidth = isHighlighted ? 2.5 : 1
          ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(fromPos.dx, fromPos.dy);
        final midX = (fromPos.dx + toPos.dx) / 2;
        final midY = (fromPos.dy + toPos.dy) / 2;
        const offset = 20.0;
        path.quadraticBezierTo(midX + offset, midY - offset, toPos.dx, toPos.dy);
        canvas.drawPath(path, paint);

        // Draw small diamond at midpoint for third-party relations
        if (isHighlighted) {
          final diamondCenter = Offset(
            (fromPos.dx + midX + offset) / 2 + offset / 4,
            (fromPos.dy + midY - offset) / 2 - offset / 4,
          );
          final diamondPaint = Paint()..color = lineColor.withValues(alpha: 0.8)..style = PaintingStyle.fill;
          final diamondPath = Path();
          const ds = 4.0;
          diamondPath.moveTo(diamondCenter.dx, diamondCenter.dy - ds);
          diamondPath.lineTo(diamondCenter.dx + ds, diamondCenter.dy);
          diamondPath.lineTo(diamondCenter.dx, diamondCenter.dy + ds);
          diamondPath.lineTo(diamondCenter.dx - ds, diamondCenter.dy);
          diamondPath.close();
          canvas.drawPath(diamondPath, diamondPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
