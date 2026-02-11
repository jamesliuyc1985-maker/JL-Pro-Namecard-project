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

        return SafeArea(
          child: Column(children: [
            _buildHeader(context, crm),
            if (selectedContact != null) _buildSelectedInfo(context, crm, selectedContact),
            _buildLegend(),
            Expanded(child: _buildNetworkGraph(context, crm, contacts)),
            _buildRelationsList(crm),
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 26,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _legendItem('我', AppTheme.accentGold),
            ...MyRelationType.values.take(6).map((r) => _legendItem(r.label, r.color)),
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

  Widget _buildSelectedInfo(BuildContext context, CrmProvider crm, Contact contact) {
    final relatedRelations = crm.getRelationsForContact(contact.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: contact.myRelation.color.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: contact.myRelation.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(contact.name[0], style: TextStyle(color: contact.myRelation.color, fontWeight: FontWeight.bold, fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('${contact.myRelation.label} | ${contact.company} | 关联${relatedRelations.length}人',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        IconButton(
          icon: const Icon(Icons.open_in_new, color: AppTheme.primaryPurple, size: 18),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contact.id))),
        ),
      ]),
    );
  }

  Widget _buildNetworkGraph(BuildContext context, CrmProvider crm, List<Contact> contacts) {
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
                  // Contact nodes
                  ..._buildContactNodes(contacts, size),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContactNodes(List<Contact> contacts, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final widgets = <Widget>[];

    // Group by relationship strength for ring layout
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

        widgets.add(Positioned(
          left: x, top: y,
          child: GestureDetector(
            onTap: () => setState(() => _selectedContactId = contact.id),
            child: Container(
              width: nodeSize, height: nodeSize,
              decoration: BoxDecoration(
                color: isSelected ? contact.myRelation.color : contact.myRelation.color.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.white : contact.myRelation.color, width: isSelected ? 2.5 : 1),
                boxShadow: isSelected ? [BoxShadow(color: contact.myRelation.color.withValues(alpha: 0.6), blurRadius: 10)] : null,
              ),
              child: Center(
                child: Text(
                  contact.name.length >= 2 ? contact.name.substring(contact.name.length - 2) : contact.name,
                  style: TextStyle(color: Colors.white, fontSize: nodeSize > 34 ? 11 : 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
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

  Widget _buildRelationsList(CrmProvider crm) {
    final rels = _selectedContactId != null
        ? crm.getRelationsForContact(_selectedContactId!)
        : crm.relations;

    if (rels.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 110,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              return Container(
                width: 180, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: [
                    Text(r.fromName.length >= 2 ? r.fromName.substring(r.fromName.length - 2) : r.fromName,
                        style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.sync_alt, color: AppTheme.textSecondary, size: 12)),
                    Expanded(child: Text(r.toName.length >= 2 ? r.toName.substring(r.toName.length - 2) : r.toName,
                        style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(r.relationType, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10)),
                  ),
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(r.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showAddRelationDialog(BuildContext context, CrmProvider crm) {
    Contact? from;
    Contact? to;
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final allContacts = crm.allContacts;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('添加联系人关系', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<Contact>(
                initialValue: from,
                decoration: const InputDecoration(labelText: '联系人A'),
                dropdownColor: AppTheme.cardBgLight,
                items: allContacts.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.company})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() => from = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Contact>(
                initialValue: to,
                decoration: const InputDecoration(labelText: '联系人B'),
                dropdownColor: AppTheme.cardBgLight,
                items: allContacts.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.company})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() => to = v),
              ),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: '关系类型（如：同行、合伙人、客户）')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: '关系描述')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (from != null && to != null && typeCtrl.text.isNotEmpty) {
                      crm.addRelation(ContactRelation(
                        id: crm.generateId(), fromContactId: from!.id, toContactId: to!.id,
                        fromName: from!.name, toName: to!.name,
                        relationType: typeCtrl.text, description: descCtrl.text,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('保存'),
                ),
              ),
              const SizedBox(height: 16),
            ]),
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

  _NetworkPainter({required this.contacts, required this.relations, this.selectedId, required this.centerSize});

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
    for (final c in contacts) {
      final pos = posMap[c.id];
      if (pos == null) continue;
      final paint = Paint()
        ..color = c.myRelation.color.withValues(alpha: selectedId == null || selectedId == c.id ? 0.3 : 0.08)
        ..strokeWidth = c.strength == RelationshipStrength.hot ? 2 : 1;
      canvas.drawLine(center, pos, paint);
    }

    // Draw lines between related contacts
    for (final r in relations) {
      final fromPos = posMap[r.fromContactId];
      final toPos = posMap[r.toContactId];
      if (fromPos == null || toPos == null) continue;

      final isHighlighted = selectedId == null || selectedId == r.fromContactId || selectedId == r.toContactId;
      final paint = Paint()
        ..color = AppTheme.accentGold.withValues(alpha: isHighlighted ? 0.6 : 0.1)
        ..strokeWidth = isHighlighted ? 2 : 0.8
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(fromPos.dx, fromPos.dy);
      final midX = (fromPos.dx + toPos.dx) / 2;
      final midY = (fromPos.dy + toPos.dy) / 2;
      final offset = 20.0;
      path.quadraticBezierTo(midX + offset, midY - offset, toPos.dx, toPos.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
