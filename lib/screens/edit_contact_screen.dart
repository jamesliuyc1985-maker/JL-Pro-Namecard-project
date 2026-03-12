import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class EditContactScreen extends StatefulWidget {
  final String contactId;
  const EditContactScreen({super.key, required this.contactId});
  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  // === 基本信息 ===
  late TextEditingController _nameCtrl, _readingCtrl, _companyCtrl, _positionCtrl;
  late TextEditingController _phoneCtrl, _emailCtrl, _addressCtrl, _nationalityCtrl;
  late TextEditingController _tagsCtrl;
  late Industry _industry;
  late RelationshipStrength _strength;
  late MyRelationType _myRelation;

  // === 业务画像 ===
  late TextEditingController _regionCtrl, _contactPersonCtrl, _contactPersonPhoneCtrl;
  late EntityType _entityType;
  late bool _hasUsedExosome;

  // === 合作意向 ===
  late TextEditingController _coopModeCtrl;
  late List<String> _decisionFactors;

  // === 资源与备注 ===
  late TextEditingController _industryResourcesCtrl, _otherNeedsCtrl, _notesCtrl, _referredByCtrl;
  late TextEditingController _coverageMarketsCtrl;

  // === 产品兴趣 ===
  late List<ProductInterest> _productInterests;

  bool _initialized = false;
  int _expandedSection = 0; // 0=基本信息, 1=业务画像, 2=产品需求, 3=资源备注

  static const _decisionOptions = ['价格', '效果', '合规', '品牌', '供货稳定性', '售后服务', '临床数据'];

  @override
  void dispose() {
    if (_initialized) {
      for (final c in [_nameCtrl, _readingCtrl, _companyCtrl, _positionCtrl, _phoneCtrl, _emailCtrl,
          _addressCtrl, _nationalityCtrl, _tagsCtrl, _regionCtrl, _contactPersonCtrl,
          _contactPersonPhoneCtrl, _coopModeCtrl,
          _industryResourcesCtrl, _otherNeedsCtrl, _notesCtrl, _referredByCtrl, _coverageMarketsCtrl]) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _initFromContact(Contact contact, List<Map<String, String>> allProducts) {
    if (_initialized) return;
    _nameCtrl = TextEditingController(text: contact.name);
    _readingCtrl = TextEditingController(text: contact.nameReading);
    _companyCtrl = TextEditingController(text: contact.company);
    _positionCtrl = TextEditingController(text: contact.position);
    _phoneCtrl = TextEditingController(text: contact.phone);
    _emailCtrl = TextEditingController(text: contact.email);
    _addressCtrl = TextEditingController(text: contact.address);
    _nationalityCtrl = TextEditingController(text: contact.nationality);
    _tagsCtrl = TextEditingController(text: contact.tags.join(', '));
    _industry = contact.industry;
    _strength = contact.strength;
    _myRelation = contact.myRelation;

    _regionCtrl = TextEditingController(text: contact.region);
    _entityType = contact.entityType;
    _contactPersonCtrl = TextEditingController(text: contact.contactPerson);
    _contactPersonPhoneCtrl = TextEditingController(text: contact.contactPersonPhone);
    _hasUsedExosome = contact.hasUsedExosome;

    _coopModeCtrl = TextEditingController(text: contact.coopModeStr);
    _decisionFactors = List.from(contact.decisionFactors);

    _industryResourcesCtrl = TextEditingController(text: contact.industryResources);
    _otherNeedsCtrl = TextEditingController(text: contact.otherNeeds);
    _coverageMarketsCtrl = TextEditingController(text: contact.coverageMarkets);
    _notesCtrl = TextEditingController(text: contact.notes);
    _referredByCtrl = TextEditingController(text: contact.referredBy);

    // 构建产品兴趣列表: 确保所有产品都有条目
    _productInterests = [];
    for (final prod in allProducts) {
      final existing = contact.productInterests.where((p) => p.productId == prod['id']).firstOrNull;
      _productInterests.add(existing ?? ProductInterest(productId: prod['id']!, productName: prod['name']!));
    }

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final contact = crm.getContact(widget.contactId);
      if (contact == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('未找到联系人')));

      // 获取所有产品的ID和名称
      final allProducts = crm.products.map((p) => {'id': p.id, 'name': p.name}).toList();
      _initFromContact(contact, allProducts);

      return Scaffold(
        appBar: AppBar(
          title: const Text('编辑客户档案'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(onPressed: () => _save(context, crm, contact), child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              _sectionHeader(0, Icons.person, '基本信息', AppTheme.primaryBlue),
              if (_expandedSection == 0) _buildBasicSection(),
              const SizedBox(height: 8),
              _sectionHeader(1, Icons.business_center, '业务画像', const Color(0xFFE17055)),
              if (_expandedSection == 1) _buildBusinessSection(),
              const SizedBox(height: 8),
              _sectionHeader(2, Icons.science, '产品需求', const Color(0xFF00B894)),
              if (_expandedSection == 2) _buildProductSection(crm),
              const SizedBox(height: 8),
              _sectionHeader(3, Icons.handshake, '资源 & 备注', AppTheme.accentGold),
              if (_expandedSection == 3) _buildResourceSection(),
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

  // ========== Section Header ==========
  Widget _sectionHeader(int index, IconData icon, String title, Color color) {
    final isExpanded = _expandedSection == index;
    return GestureDetector(
      onTap: () => setState(() => _expandedSection = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isExpanded ? color.withValues(alpha: 0.15) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: isExpanded ? Border.all(color: color.withValues(alpha: 0.5)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: isExpanded ? color : AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.textSecondary, size: 20),
        ]),
      ),
    );
  }

  // ========== Section 0: 基本信息 ==========
  Widget _buildBasicSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        _field(_nameCtrl, '客户名称 *', Icons.person, required: true),
        _field(_readingCtrl, '读音/拼音', Icons.text_fields),
        _field(_companyCtrl, '公司/机构 *', Icons.business, required: true),
        _field(_positionCtrl, '职位', Icons.badge),
        _field(_phoneCtrl, '电话', Icons.phone, keyboard: TextInputType.phone),
        _field(_emailCtrl, '邮箱', Icons.email, keyboard: TextInputType.emailAddress),
        _field(_addressCtrl, '地址', Icons.location_on),
        _field(_nationalityCtrl, '国籍', Icons.flag),
        _field(_coverageMarketsCtrl, '覆盖市场 (日本/中国/东南亚等)', Icons.public),
        const SizedBox(height: 8),
        _chipSection('与我的关系', MyRelationType.values.map((r) =>
          _choiceChip(r.label, _myRelation == r, r.color, () => setState(() => _myRelation = r))
        ).toList()),
        const SizedBox(height: 8),
        _chipSection('关系强度', RelationshipStrength.values.map((s) =>
          _choiceChip(s.label, _strength == s, s.color, () => setState(() => _strength = s))
        ).toList()),
        const SizedBox(height: 8),
        _chipSection('行业', Industry.values.map((ind) =>
          _choiceChip(ind.label, _industry == ind, ind.color, () => setState(() => _industry = ind))
        ).toList()),
        _field(_tagsCtrl, '标签 (逗号分隔)', Icons.tag),
      ]),
    );
  }

  // ========== Section 1: 业务画像 ==========
  Widget _buildBusinessSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        _field(_regionCtrl, '所在地区', Icons.map),
        const SizedBox(height: 8),
        _chipSection('主体类型', EntityType.values.map((e) =>
          _choiceChip(e.label, _entityType == e, e.color, () => setState(() => _entityType = e))
        ).toList()),
        const SizedBox(height: 8),
        _field(_contactPersonCtrl, '负责人', Icons.person_outline),
        _field(_contactPersonPhoneCtrl, '负责人联系方式', Icons.phone_android, keyboard: TextInputType.phone),
        const SizedBox(height: 8),
        _switchRow('是否使用过外泌体/NAD+等同类产品', _hasUsedExosome, (v) => setState(() => _hasUsedExosome = v)),
      ]),
    );
  }

  // ========== Section 2: 产品需求 ==========
  Widget _buildProductSection(CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        // 合作模式
        _chipSection('意向合作模式', CoopMode.values.map((m) {
          final selected = _coopModeCtrl.text.contains(m.label);
          return _choiceChip(m.label, selected, m.color, () {
            setState(() {
              final modes = _coopModeCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              if (selected) { modes.remove(m.label); } else { modes.add(m.label); }
              _coopModeCtrl.text = modes.join(', ');
            });
          });
        }).toList()),
        const SizedBox(height: 8),
        // 采购决策重点
        _chipSection('采购决策重点 (可多选)', _decisionOptions.map((d) {
          final selected = _decisionFactors.contains(d);
          return _choiceChip(d, selected, selected ? AppTheme.primaryPurple : AppTheme.textSecondary, () {
            setState(() { if (selected) { _decisionFactors.remove(d); } else { _decisionFactors.add(d); } });
          });
        }).toList()),
        const SizedBox(height: 12),
        // 逐产品兴趣
        Row(children: [
          const Icon(Icons.science, color: Color(0xFF00B894), size: 16),
          const SizedBox(width: 6),
          const Text('各产品需求明细', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text('${_productInterests.where((p) => p.interested).length}/${_productInterests.length} 感兴趣',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        ..._productInterests.asMap().entries.map((entry) {
          final idx = entry.key;
          final pi = entry.value;
          final product = crm.products.where((p) => p.id == pi.productId).firstOrNull;
          final catColor = _categoryColor(product?.category ?? '');
          return _productInterestCard(idx, pi, catColor, product);
        }),
      ]),
    );
  }

  Widget _productInterestCard(int idx, ProductInterest pi, Color catColor, dynamic product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pi.interested ? catColor.withValues(alpha: 0.08) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: pi.interested ? Border.all(color: catColor.withValues(alpha: 0.4)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => pi.interested = !pi.interested),
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: pi.interested ? catColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: pi.interested ? catColor : AppTheme.textSecondary),
              ),
              child: pi.interested ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pi.productName, style: TextStyle(
              color: pi.interested ? catColor : AppTheme.textSecondary,
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
            if (product != null) Text(
              '${Formatters.currency(product.agentPrice)}~${Formatters.currency(product.retailPrice)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
          ])),
        ]),
        if (pi.interested) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _miniField('现用品牌', pi.currentBrand,
              (v) => pi.currentBrand = v, TextInputType.text)),
            const SizedBox(width: 8),
            Expanded(child: _miniField('现有月均量', pi.currentMonthlyVolume,
              (v) => pi.currentMonthlyVolume = v, TextInputType.text)),
            const SizedBox(width: 8),
            Expanded(child: _miniField('现有单价(¥)', '${pi.currentUnitPrice > 0 ? pi.currentUnitPrice.toStringAsFixed(0) : ''}',
              (v) => pi.currentUnitPrice = double.tryParse(v) ?? 0, TextInputType.number)),
          ]),
          const SizedBox(height: 6),
          _miniField('期望主要功效', pi.desiredEffects,
            (v) => pi.desiredEffects = v, TextInputType.text),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _miniField('月采购量(瓶)', '${pi.monthlyQty > 0 ? pi.monthlyQty : ''}',
              (v) => pi.monthlyQty = int.tryParse(v) ?? 0, TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: _miniField('目标单价(¥)', '${pi.budgetUnit > 0 ? pi.budgetUnit.toStringAsFixed(0) : ''}',
              (v) => pi.budgetUnit = double.tryParse(v) ?? 0, TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: _miniField('月度预算(¥)', '${pi.budgetMonthly > 0 ? pi.budgetMonthly.toStringAsFixed(0) : ''}',
              (v) => pi.budgetMonthly = double.tryParse(v) ?? 0, TextInputType.number)),
          ]),
          const SizedBox(height: 6),
          _miniField('备注', pi.notes, (v) => pi.notes = v, TextInputType.text),
        ],
      ]),
    );
  }

  Widget _miniField(String label, String initial, Function(String) onChanged, TextInputType keyboard) {
    return TextFormField(
      initialValue: initial,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      keyboardType: keyboard,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true, fillColor: AppTheme.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      ),
    );
  }

  // ========== Section 3: 资源 & 备注 ==========
  Widget _buildResourceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        _field(_industryResourcesCtrl, '可对接的行业资源', Icons.hub, maxLines: 2),
        _field(_otherNeedsCtrl, '其他需求', Icons.request_page, maxLines: 2),
        _field(_referredByCtrl, '引荐人', Icons.handshake),
        _field(_notesCtrl, '备注', Icons.note, maxLines: 3),
      ]),
    );
  }

  // ========== Shared Widgets ==========
  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _chipSection(String title, List<Widget> chips) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: chips),
    ]);
  }

  Widget _choiceChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: color) : null,
        ),
        child: Text(label, style: TextStyle(
          color: selected ? color : AppTheme.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        )),
      ),
    );
  }

  Widget _switchRow(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF00B894)),
      ]),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'exosome': return const Color(0xFF00B894);
      case 'nad': return const Color(0xFFE17055);
      case 'nmn': return const Color(0xFF0984E3);
      default: return AppTheme.primaryPurple;
    }
  }

  // ========== Save ==========
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
      contact.tags = _tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      // 业务画像
      contact.region = _regionCtrl.text;
      contact.entityType = _entityType;
      contact.contactPerson = _contactPersonCtrl.text;
      contact.contactPersonPhone = _contactPersonPhoneCtrl.text;
      contact.hasUsedExosome = _hasUsedExosome;

      // 合作意向
      contact.coopModeStr = _coopModeCtrl.text;
      contact.decisionFactors = _decisionFactors;

      // 资源备注
      contact.industryResources = _industryResourcesCtrl.text;
      contact.otherNeeds = _otherNeedsCtrl.text;
      contact.coverageMarkets = _coverageMarketsCtrl.text;
      contact.notes = _notesCtrl.text;
      contact.referredBy = _referredByCtrl.text;

      // 产品兴趣
      contact.productInterests = _productInterests;

      crm.updateContact(contact);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.name} 已更新'), backgroundColor: AppTheme.success),
      );
    }
  }
}
