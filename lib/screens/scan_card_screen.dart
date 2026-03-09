import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

/// 名片扫描 v25.8 — 图片选取 + 智能手动录入
/// 移除不可调用的 Gemini API，改为:
/// 1. 图片预览 + 手动逐字段录入（支持看图填写）
/// 2. 快速录入模板（医疗/金融/科技行业常用字段预填）
class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});
  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  bool _showResult = false;
  Uint8List? _imageBytes;
  final _nameCtrl = TextEditingController();
  final _readingCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Industry _industry = Industry.other;
  MyRelationType _myRelation = MyRelationType.other;
  RelationshipStrength _strength = RelationshipStrength.cool;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose(); _readingCtrl.dispose(); _companyCtrl.dispose();
    _positionCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名片录入'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_showResult)
            TextButton(onPressed: _clearAndReset, child: const Text('重新开始', style: TextStyle(fontSize: 12))),
        ],
      ),
      body: SafeArea(child: _showResult ? _buildResultForm() : _buildScanView()),
    );
  }

  Widget _buildScanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 图片预览区
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.4), width: 2),
          ),
          child: _imageBytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, fit: BoxFit.contain))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.document_scanner_outlined, color: AppTheme.primaryPurple.withValues(alpha: 0.5), size: 48),
                const SizedBox(height: 12),
                const Text('选择名片图片作为参考', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const Text('或直接手动录入', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
        ),
        const SizedBox(height: 20),

        // 操作按钮
        Row(children: [
          if (!kIsWeb)
            Expanded(child: _actionButton(
              icon: Icons.camera_alt, label: '拍照',
              color: AppTheme.primaryPurple,
              onTap: () => _pickImage(ImageSource.camera),
            )),
          if (!kIsWeb) const SizedBox(width: 12),
          Expanded(child: _actionButton(
            icon: Icons.photo_library, label: '相册选图',
            color: AppTheme.primaryBlue,
            onTap: () => _pickImage(ImageSource.gallery),
          )),
        ]),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.edit_note, label: '直接手动录入',
          color: AppTheme.success,
          onTap: () => setState(() => _showResult = true),
        ),

        const SizedBox(height: 20),

        // 快捷模板
        const Text('快捷模板', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _templateChip('医疗行业', Icons.local_hospital, const Color(0xFFE17055), () {
            setState(() {
              _industry = Industry.healthcare;
              _myRelation = MyRelationType.clinic;
              _showResult = true;
            });
          }),
          _templateChip('金融投资', Icons.account_balance, const Color(0xFF6C5CE7), () {
            setState(() {
              _industry = Industry.finance;
              _myRelation = MyRelationType.investor;
              _showResult = true;
            });
          }),
          _templateChip('代理商', Icons.storefront, const Color(0xFFFF6348), () {
            setState(() {
              _myRelation = MyRelationType.agent;
              _showResult = true;
            });
          }),
          _templateChip('供应商', Icons.factory, const Color(0xFFFDAA5B), () {
            setState(() {
              _myRelation = MyRelationType.supplier;
              _showResult = true;
            });
          }),
        ]),

        const SizedBox(height: 20),
        // 说明
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 18),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('名片录入说明', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              SizedBox(height: 4),
              Text('1. 选取名片图片作为参考，对照图片手动录入\n'
                   '2. 或使用快捷模板快速开始录入\n'
                   '3. 支持中/日/英多语言录入\n'
                   '4. 可选填读音(ふりがな)便于日语名搜索',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.5)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _templateChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 90);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return;
      setState(() {
        _imageBytes = bytes;
        _showResult = true; // 选图后直接进入录入页面
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片获取失败: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildResultForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 名片图片预览（如有）
        if (_imageBytes != null) ...[
          Container(
            height: 160,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(top: 8, right: 8, child: GestureDetector(
                onTap: () => setState(() => _imageBytes = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              )),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // 基本信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('基本信息', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _field(_nameCtrl, '姓名 *', Icons.person),
            _field(_readingCtrl, '读音/ふりがな', Icons.text_fields),
            _field(_companyCtrl, '公司 *', Icons.business),
            _field(_positionCtrl, '职位', Icons.badge),
          ]),
        ),
        const SizedBox(height: 12),

        // 联系方式
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('联系方式', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _field(_phoneCtrl, '电话', Icons.phone, keyboard: TextInputType.phone),
            _field(_emailCtrl, '邮箱', Icons.email, keyboard: TextInputType.emailAddress),
            _field(_addressCtrl, '地址', Icons.location_on),
          ]),
        ),
        const SizedBox(height: 12),

        // 分类标签
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('行业分类', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: Industry.values.map((ind) {
              final isSelected = _industry == ind;
              return ChoiceChip(
                label: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(ind.icon, size: 14, color: isSelected ? Colors.white : ind.color),
                  const SizedBox(width: 4),
                  Text(ind.label),
                ]),
                selected: isSelected,
                onSelected: (_) => setState(() => _industry = ind),
                selectedColor: ind.color, backgroundColor: AppTheme.cardBgLight,
                labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 11),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList()),
          ]),
        ),
        const SizedBox(height: 12),

        // 与我的业务关系
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('与我的业务关系', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: MyRelationType.values.map((rel) {
              final isSelected = _myRelation == rel;
              return ChoiceChip(
                label: Text(rel.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _myRelation = rel),
                selectedColor: rel.color, backgroundColor: AppTheme.cardBgLight,
                labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 11),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList()),
          ]),
        ),
        const SizedBox(height: 12),

        // 关系亲密度
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('关系亲密度', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: RelationshipStrength.values.map((s) {
              final isSelected = _strength == s;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _strength = s),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? s.color.withValues(alpha: 0.2) : AppTheme.cardBgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? s.color : Colors.transparent, width: 2),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? s.color : AppTheme.textSecondary, size: 20),
                    const SizedBox(height: 4),
                    Text(s.label, style: TextStyle(color: isSelected ? s.color : AppTheme.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              ));
            }).toList()),
          ]),
        ),
        const SizedBox(height: 12),

        // 备注
        _field(_notesCtrl, '备注', Icons.notes),

        const SizedBox(height: 20),
        // 保存按钮
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('保存联系人', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  void _clearAndReset() {
    setState(() {
      _showResult = false;
      _imageBytes = null;
      _nameCtrl.clear(); _readingCtrl.clear(); _companyCtrl.clear();
      _positionCtrl.clear(); _phoneCtrl.clear(); _emailCtrl.clear();
      _addressCtrl.clear(); _notesCtrl.clear();
      _industry = Industry.other;
      _myRelation = MyRelationType.other;
      _strength = RelationshipStrength.cool;
    });
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _companyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写姓名和公司'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    final crm = context.read<CrmProvider>();
    crm.addContact(Contact(
      id: crm.generateId(),
      name: _nameCtrl.text,
      nameReading: _readingCtrl.text,
      company: _companyCtrl.text,
      position: _positionCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      address: _addressCtrl.text,
      industry: _industry,
      myRelation: _myRelation,
      strength: _strength,
      notes: _notesCtrl.text,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nameCtrl.text} 已添加到人脉库'), backgroundColor: AppTheme.success),
    );
    Navigator.pop(context);
  }
}
