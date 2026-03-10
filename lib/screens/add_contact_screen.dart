import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});
  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  // === 基本信息 ===
  final _nameCtrl = TextEditingController();
  final _readingCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _coverageMarketsCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  Industry _industry = Industry.other;
  RelationshipStrength _strength = RelationshipStrength.cool;
  MyRelationType _myRelation = MyRelationType.other;

  // === 业务画像 ===
  final _regionCtrl = TextEditingController();
  EntityType _entityType = EntityType.other;
  final _contactPersonCtrl = TextEditingController();
  final _contactPersonPhoneCtrl = TextEditingController();
  bool _hasUsedExosome = false;
  final _currentBrandsCtrl = TextEditingController();
  final _currentMonthlyVolumeCtrl = TextEditingController();
  final _currentUnitPriceCtrl = TextEditingController();
  final _desiredEffectsCtrl = TextEditingController();

  // === 合作意向 ===
  final _coopModeCtrl = TextEditingController();
  List<String> _decisionFactors = [];

  // === 资源与备注 ===
  final _industryResourcesCtrl = TextEditingController();
  final _otherNeedsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _referredByCtrl = TextEditingController();

  // === 产品兴趣 ===
  List<ProductInterest> _productInterests = [];
  bool _productsInitialized = false;

  int _expandedSection = 0;

  static const _decisionOptions = ['价格', '效果', '合规', '品牌', '供货稳定性', '售后服务', '临床数据'];

  @override
  void dispose() {
    for (final c in [_nameCtrl, _readingCtrl, _companyCtrl, _positionCtrl, _phoneCtrl, _emailCtrl,
        _addressCtrl, _nationalityCtrl, _coverageMarketsCtrl, _tagsCtrl, _regionCtrl, _contactPersonCtrl,
        _contactPersonPhoneCtrl, _currentBrandsCtrl, _currentMonthlyVolumeCtrl,
        _currentUnitPriceCtrl, _desiredEffectsCtrl, _coopModeCtrl,
        _industryResourcesCtrl, _otherNeedsCtrl, _notesCtrl, _referredByCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      // 初始化产品兴趣列表
      if (!_productsInitialized) {
        _productInterests = crm.products.map((p) =>
          ProductInterest(productId: p.id, productName: p.name)
        ).toList();
        _productsInitialized = true;
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('新增客户'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(onPressed: () => _save(context, crm), child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold))),
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
                onPressed: () => _save(context, crm),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('保存新客户', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 8),
        _field(_currentBrandsCtrl, '目前在用产品品牌', Icons.branding_watermark),
        _field(_currentMonthlyVolumeCtrl, '现有月均采购/使用量', Icons.data_usage),
        _field(_currentUnitPriceCtrl, '现有采购单价 (日元)', Icons.price_change, keyboard: TextInputType.number),
        _field(_desiredEffectsCtrl, '期望外泌体主要功效', Icons.auto_awesome, maxLines: 2),
      ]),
    );
  }

  // ========== Section 2: 产品需求 ==========
  Widget _buildProductSection(CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
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
        _chipSection('采购决策重点 (可多选)', _decisionOptions.map((d) {
          final selected = _decisionFactors.contains(d);
          return _choiceChip(d, selected, selected ? AppTheme.primaryPurple : AppTheme.textSecondary, () {
            setState(() { if (selected) { _decisionFactors.remove(d); } else { _decisionFactors.add(d); } });
          });
        }).toList()),
        const SizedBox(height: 12),
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
  void _save(BuildContext context, CrmProvider crm) {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: crm.generateId(),
        name: _nameCtrl.text,
        nameReading: _readingCtrl.text,
        company: _companyCtrl.text,
        position: _positionCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        address: _addressCtrl.text,
        nationality: _nationalityCtrl.text,
        coverageMarkets: _coverageMarketsCtrl.text,
        industry: _industry,
        strength: _strength,
        myRelation: _myRelation,
        tags: _tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
        // 业务画像
        region: _regionCtrl.text,
        entityType: _entityType,
        contactPerson: _contactPersonCtrl.text,
        contactPersonPhone: _contactPersonPhoneCtrl.text,
        hasUsedExosome: _hasUsedExosome,
        currentBrands: _currentBrandsCtrl.text,
        currentMonthlyVolume: _currentMonthlyVolumeCtrl.text,
        currentUnitPrice: double.tryParse(_currentUnitPriceCtrl.text) ?? 0,
        desiredEffects: _desiredEffectsCtrl.text,
        // 合作意向
        coopModeStr: _coopModeCtrl.text,
        decisionFactors: _decisionFactors,
        // 资源
        industryResources: _industryResourcesCtrl.text,
        otherNeeds: _otherNeedsCtrl.text,
        notes: _notesCtrl.text,
        referredBy: _referredByCtrl.text,
        // 产品兴趣
        productInterests: _productInterests,
      );

      crm.addContact(contact);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.name} 已添加'), backgroundColor: AppTheme.success),
      );
    }
  }
}
