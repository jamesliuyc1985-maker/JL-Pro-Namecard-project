import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

class EditContactScreen extends StatefulWidget {
  final String contactId;
  const EditContactScreen({super.key, required this.contactId});
  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _readingCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _positionCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagsCtrl;
  late TextEditingController _nationalityCtrl;
  late Industry _industry;
  late RelationshipStrength _strength;
  late MyRelationType _myRelation;
  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) {
      for (final c in [_nameCtrl, _readingCtrl, _companyCtrl, _positionCtrl, _phoneCtrl, _emailCtrl, _addressCtrl, _notesCtrl, _tagsCtrl, _nationalityCtrl]) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _initFromContact(Contact contact) {
    if (_initialized) { return; }
    _nameCtrl = TextEditingController(text: contact.name);
    _readingCtrl = TextEditingController(text: contact.nameReading);
    _companyCtrl = TextEditingController(text: contact.company);
    _positionCtrl = TextEditingController(text: contact.position);
    _phoneCtrl = TextEditingController(text: contact.phone);
    _emailCtrl = TextEditingController(text: contact.email);
    _addressCtrl = TextEditingController(text: contact.address);
    _notesCtrl = TextEditingController(text: contact.notes);
    _tagsCtrl = TextEditingController(text: contact.tags.join(', '));
    _nationalityCtrl = TextEditingController(text: contact.nationality);
    _industry = contact.industry;
    _strength = contact.strength;
    _myRelation = contact.myRelation;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final contact = crm.getContact(widget.contactId);
      if (contact == null) {
        return Scaffold(appBar: AppBar(), body: const Center(child: Text('未找到联系人')));
      }
      _initFromContact(contact);

      return Scaffold(
        appBar: AppBar(
          title: const Text('编辑联系人'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(
              onPressed: () => _save(context, crm, contact),
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              // Avatar with initial
              Center(child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_industry.color, _industry.color.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(child: Text(
                  _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                )),
              )),
              const SizedBox(height: 20),
              _field(_nameCtrl, '姓名 *', Icons.person, required: true),
              _field(_readingCtrl, '读音/拼音', Icons.text_fields),
              _field(_companyCtrl, '公司 *', Icons.business, required: true),
              _field(_positionCtrl, '职位', Icons.badge),
              _field(_phoneCtrl, '电话', Icons.phone, keyboard: TextInputType.phone),
              _field(_emailCtrl, '邮箱', Icons.email, keyboard: TextInputType.emailAddress),
              _field(_addressCtrl, '地址', Icons.location_on),
              _field(_nationalityCtrl, '国籍', Icons.flag),
              const SizedBox(height: 16),
              const Text('行业', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: Industry.values.map((ind) {
                final s = _industry == ind;
                return ChoiceChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(ind.icon, size: 14, color: s ? Colors.white : ind.color),
                    const SizedBox(width: 4),
                    Text(ind.label),
                  ]),
                  selected: s,
                  onSelected: (_) => setState(() => _industry = ind),
                  selectedColor: ind.color, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: s ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                );
              }).toList()),
              const SizedBox(height: 16),
              const Text('与我的关系', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: MyRelationType.values.map((rel) {
                final s = _myRelation == rel;
                return ChoiceChip(
                  label: Text(rel.label), selected: s,
                  onSelected: (_) => setState(() => _myRelation = rel),
                  selectedColor: rel.color, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: s ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                );
              }).toList()),
              const SizedBox(height: 16),
              const Text('关系强度', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: RelationshipStrength.values.map((str) {
                final s = _strength == str;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _strength = str),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: s ? str.color.withValues(alpha: 0.3) : AppTheme.cardBgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: s ? Border.all(color: str.color, width: 2) : null,
                    ),
                    child: Column(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: str.color, shape: BoxShape.circle)),
                      const SizedBox(height: 4),
                      Text(str.label, style: TextStyle(color: s ? str.color : AppTheme.textSecondary, fontSize: 11)),
                    ]),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 16),
              _field(_tagsCtrl, '标签 (逗号分隔)', Icons.tag),
              _field(_notesCtrl, '备注', Icons.note, maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _save(context, crm, contact),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('保存修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      );
    });
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool required = false, TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary),
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: required ? (v) => (v == null || v.isEmpty) ? '请填写' : null : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20)),
      ),
    );
  }

  void _save(BuildContext context, CrmProvider crm, Contact contact) {
    if (_formKey.currentState!.validate()) {
      contact.name = _nameCtrl.text;
      contact.nameReading = _readingCtrl.text;
      contact.company = _companyCtrl.text;
      contact.position = _positionCtrl.text;
      contact.phone = _phoneCtrl.text;
      contact.email = _emailCtrl.text;
      contact.address = _addressCtrl.text;
      contact.nationality = _nationalityCtrl.text;
      contact.industry = _industry;
      contact.strength = _strength;
      contact.myRelation = _myRelation;
      contact.notes = _notesCtrl.text;
      contact.tags = _tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      crm.updateContact(contact);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.name} 已更新'), backgroundColor: AppTheme.success),
      );
    }
  }
}
