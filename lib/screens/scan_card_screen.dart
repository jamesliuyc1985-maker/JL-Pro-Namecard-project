import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});
  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  bool _isScanning = false;
  bool _showResult = false;
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Industry _industry = Industry.other;
  MyRelationType _myRelation = MyRelationType.other;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('名片扫描'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _showResult ? _buildResultForm() : _buildScanView(),
      ),
    );
  }

  Widget _buildScanView() {
    return Column(
      children: [
        // Camera preview area (simulated)
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.5), width: 2),
            ),
            child: Stack(
              children: [
                // Camera frame
                Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_isScanning ? Icons.hourglass_top : Icons.document_scanner_outlined,
                        color: AppTheme.primaryPurple, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      _isScanning ? '正在识别名片...' : '将名片放入框内',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('支持中文/日文/英文名片', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ]),
                ),
                // Scan corners
                if (!_isScanning) ...[
                  _scanCorner(Alignment.topLeft),
                  _scanCorner(Alignment.topRight),
                  _scanCorner(Alignment.bottomLeft),
                  _scanCorner(Alignment.bottomRight),
                ],
                if (_isScanning)
                  Center(child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator(color: AppTheme.primaryPurple, strokeWidth: 3))),
              ],
            ),
          ),
        ),
        // Action buttons
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.camera_alt,
                    label: '拍照扫描',
                    color: AppTheme.primaryPurple,
                    onTap: () => _simulateScan(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    icon: Icons.photo_library,
                    label: '相册导入',
                    color: AppTheme.primaryBlue,
                    onTap: () => _simulateScan(),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _actionButton(
                icon: Icons.edit_note,
                label: '手动录入',
                color: AppTheme.success,
                onTap: () => setState(() => _showResult = true),
              ),
              const SizedBox(height: 20),
              // Recent scans
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('扫描提示', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('保持名片平整，光线均匀\nOCR自动识别姓名、公司、电话、邮箱',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _scanCorner(Alignment alignment) {
    return Positioned(
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 16 : null,
      right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 16 : null,
      top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 16 : null,
      bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 16 : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: AppTheme.primaryPurple, width: 3) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: AppTheme.primaryPurple, width: 3) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: AppTheme.primaryPurple, width: 3) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: AppTheme.primaryPurple, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }

  void _simulateScan() {
    setState(() => _isScanning = true);
    // Simulate OCR processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _showResult = true;
          // Simulated OCR result
          _nameCtrl.text = '新田雅之';
          _companyCtrl.text = '三菱商事株式会社';
          _positionCtrl.text = '经营企划部 课长';
          _phoneCtrl.text = '03-3210-2121';
          _emailCtrl.text = 'm.nitta@mitsubishicorp.com';
          _addressCtrl.text = '东京都千代田区丸之内2-3-1';
          _industry = Industry.trading;
          _myRelation = MyRelationType.client;
        });
      }
    });
  }

  Widget _buildResultForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('识别完成', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('请确认并修正信息后保存', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        _field(_nameCtrl, '姓名', Icons.person),
        _field(_companyCtrl, '公司', Icons.business),
        _field(_positionCtrl, '职位', Icons.badge),
        _field(_phoneCtrl, '电话', Icons.phone, keyboard: TextInputType.phone),
        _field(_emailCtrl, '邮箱', Icons.email, keyboard: TextInputType.emailAddress),
        _field(_addressCtrl, '地址', Icons.location_on),
        const SizedBox(height: 16),
        const Text('行业', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: Industry.values.map((ind) {
          final isSelected = _industry == ind;
          return ChoiceChip(
            label: Text(ind.label),
            selected: isSelected,
            onSelected: (_) => setState(() => _industry = ind),
            selectedColor: ind.color, backgroundColor: AppTheme.cardBgLight,
            labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12),
          );
        }).toList()),
        const SizedBox(height: 16),
        const Text('与我的关系', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: MyRelationType.values.map((rel) {
          final isSelected = _myRelation == rel;
          return ChoiceChip(
            label: Text(rel.label),
            selected: isSelected,
            onSelected: (_) => setState(() => _myRelation = rel),
            selectedColor: rel.color, backgroundColor: AppTheme.cardBgLight,
            labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12),
          );
        }).toList()),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() {
                _showResult = false;
                _clearFields();
              }),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.textSecondary),
              ),
              child: const Text('重新扫描', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('保存联系人', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary),
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20)),
      ),
    );
  }

  void _clearFields() {
    _nameCtrl.clear();
    _companyCtrl.clear();
    _positionCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    _addressCtrl.clear();
    _industry = Industry.other;
    _myRelation = MyRelationType.other;
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
      company: _companyCtrl.text,
      position: _positionCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      address: _addressCtrl.text,
      industry: _industry,
      myRelation: _myRelation,
      strength: RelationshipStrength.cool,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nameCtrl.text} 已添加到人脉库'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context);
  }
}
