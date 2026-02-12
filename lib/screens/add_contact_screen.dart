import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});
  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _readingCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  Industry _industry = Industry.other;
  RelationshipStrength _strength = RelationshipStrength.cool;
  MyRelationType _myRelation = MyRelationType.other;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _readingCtrl, _companyCtrl, _positionCtrl, _phoneCtrl, _emailCtrl, _addressCtrl, _notesCtrl, _nationalityCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增联系人'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
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
              return ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(ind.icon, size: 14, color: s ? Colors.white : ind.color), const SizedBox(width: 4), Text(ind.label)]),
                selected: s, onSelected: (_) => setState(() => _industry = ind), selectedColor: ind.color, backgroundColor: AppTheme.cardBgLight,
                labelStyle: TextStyle(color: s ? Colors.white : AppTheme.textPrimary, fontSize: 12));
            }).toList()),
            const SizedBox(height: 16),
            const Text('与我的关系', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: MyRelationType.values.map((rel) {
              final s = _myRelation == rel;
              return ChoiceChip(label: Text(rel.label), selected: s, onSelected: (_) => setState(() => _myRelation = rel),
                selectedColor: rel.color, backgroundColor: AppTheme.cardBgLight,
                labelStyle: TextStyle(color: s ? Colors.white : AppTheme.textPrimary, fontSize: 12));
            }).toList()),
            const SizedBox(height: 16),
            const Text('关系强度', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: RelationshipStrength.values.map((str) {
              final s = _strength == str;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _strength = str),
                child: Container(
                  margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: s ? str.color.withValues(alpha: 0.3) : AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10),
                    border: s ? Border.all(color: str.color, width: 2) : null),
                  child: Column(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: str.color, shape: BoxShape.circle)),
                    const SizedBox(height: 4),
                    Text(str.label, style: TextStyle(color: s ? str.color : AppTheme.textSecondary, fontSize: 11)),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 16),
            _field(_notesCtrl, '备注', Icons.note, maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool required = false, TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(controller: ctrl, style: const TextStyle(color: AppTheme.textPrimary), keyboardType: keyboard, maxLines: maxLines,
        validator: required ? (v) => (v == null || v.isEmpty) ? '请填写' : null : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20))),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final crm = context.read<CrmProvider>();
      crm.addContact(Contact(id: crm.generateId(), name: _nameCtrl.text, nameReading: _readingCtrl.text, company: _companyCtrl.text,
        position: _positionCtrl.text, phone: _phoneCtrl.text, email: _emailCtrl.text, address: _addressCtrl.text,
        industry: _industry, strength: _strength, myRelation: _myRelation, notes: _notesCtrl.text, nationality: _nationalityCtrl.text));
      Navigator.pop(context);
    }
  }
}
