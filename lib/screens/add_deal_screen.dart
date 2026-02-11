import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../utils/theme.dart';

class AddDealScreen extends StatefulWidget {
  const AddDealScreen({super.key});
  @override
  State<AddDealScreen> createState() => _AddDealScreenState();
}

class _AddDealScreenState extends State<AddDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DealStage _stage = DealStage.lead;
  Contact? _selectedContact;
  double _probability = 10;

  @override
  void dispose() { for (final c in [_titleCtrl, _descCtrl, _amountCtrl, _notesCtrl]) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('新增案件'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
      body: SafeArea(child: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
        TextFormField(controller: _titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          validator: (v) => (v == null || v.isEmpty) ? '请填写' : null,
          decoration: const InputDecoration(labelText: '案件名称 *', prefixIcon: Icon(Icons.work, color: AppTheme.textSecondary, size: 20))),
        const SizedBox(height: 12),
        DropdownButtonFormField<Contact>(
          initialValue: _selectedContact,
          decoration: const InputDecoration(labelText: '关联方 *', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 20)),
          dropdownColor: AppTheme.cardBgLight, validator: (v) => v == null ? '请选择' : null,
          items: crm.contacts.map((c) => DropdownMenuItem(value: c,
            child: Text('${c.name} (${c.company})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)))).toList(),
          onChanged: (v) => setState(() => _selectedContact = v)),
        const SizedBox(height: 12),
        TextFormField(controller: _descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 2,
          decoration: const InputDecoration(labelText: '概要', prefixIcon: Icon(Icons.description, color: AppTheme.textSecondary, size: 20))),
        const SizedBox(height: 12),
        TextFormField(controller: _amountCtrl, style: const TextStyle(color: AppTheme.textPrimary), keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '金额 (日元)', prefixIcon: Icon(Icons.currency_yen, color: AppTheme.textSecondary, size: 20))),
        const SizedBox(height: 16),
        const Text('阶段', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: DealStage.values.map((s) {
          final sel = _stage == s;
          return ChoiceChip(label: Text(s.label), selected: sel, onSelected: (_) => setState(() { _stage = s; _probability = _defProb(s); }),
            selectedColor: AppTheme.primaryPurple, backgroundColor: AppTheme.cardBgLight,
            labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.textPrimary, fontSize: 11),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact);
        }).toList()),
        const SizedBox(height: 16),
        Row(children: [
          const Text('成交概率: ', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          Text('${_probability.toInt()}%', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        Slider(value: _probability, min: 0, max: 100, divisions: 20, activeColor: AppTheme.primaryPurple, inactiveColor: AppTheme.cardBgLight,
          onChanged: (v) => setState(() => _probability = v)),
        const SizedBox(height: 12),
        TextFormField(controller: _notesCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 3,
          decoration: const InputDecoration(labelText: '备注', prefixIcon: Icon(Icons.note, color: AppTheme.textSecondary, size: 20))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ]))),
    );
  }

  double _defProb(DealStage s) { switch (s) { case DealStage.lead: return 10; case DealStage.contacted: return 25; case DealStage.proposal: return 40; case DealStage.negotiation: return 60; case DealStage.ordered: return 70; case DealStage.paid: return 80; case DealStage.shipped: return 85; case DealStage.inTransit: return 90; case DealStage.received: return 95; case DealStage.completed: return 100; case DealStage.lost: return 0; } }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedContact != null) {
      final crm = context.read<CrmProvider>();
      crm.addDeal(Deal(id: crm.generateId(), title: _titleCtrl.text, description: _descCtrl.text,
        contactId: _selectedContact!.id, contactName: _selectedContact!.name, stage: _stage,
        amount: double.tryParse(_amountCtrl.text) ?? 0, probability: _probability, notes: _notesCtrl.text));
      Navigator.pop(context);
    }
  }
}
