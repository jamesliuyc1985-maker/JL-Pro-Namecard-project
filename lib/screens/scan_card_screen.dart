import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

/// 名片扫描 + Gemini Vision AI识别
class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});
  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  static const _apiKey = 'AIzaSyBMTKwBDxjH2JakRFMhFRWxltXXjE-hk4A';
  bool _isScanning = false;
  bool _showResult = false;
  String? _imagePath;
  Uint8List? _imageBytes;
  String? _recognitionLog;
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Industry _industry = Industry.other;
  MyRelationType _myRelation = MyRelationType.other;
  final ImagePicker _picker = ImagePicker();

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
        title: const Text('名片扫描 (AI识别)'),
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
                if (_imageBytes != null)
                  Center(child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ))
                else if (_imagePath != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle, color: AppTheme.success, size: 64),
                        SizedBox(height: 12),
                        Text('照片已获取', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )
                else
                  Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_isScanning ? Icons.hourglass_top : Icons.document_scanner_outlined,
                          color: AppTheme.primaryPurple, size: 64),
                      const SizedBox(height: 20),
                      Text(
                        _isScanning ? '正在AI识别名片...' : '将名片放入框内',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text('Gemini Vision AI · 中/日/英/韩', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    ]),
                  ),
                if (!_isScanning && _imagePath == null) ...[
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
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(child: Column(children: [
              const SizedBox(height: 16),
              Row(children: [
                if (!kIsWeb) ...[
                  Expanded(
                    child: _actionButton(
                      icon: Icons.camera_alt,
                      label: '拍照扫描',
                      color: AppTheme.primaryPurple,
                      onTap: () => _pickAndRecognize(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: _actionButton(
                    icon: Icons.photo_library,
                    label: kIsWeb ? '选择图片(AI识别)' : '相册导入(AI识别)',
                    color: AppTheme.primaryBlue,
                    onTap: () => _pickAndRecognize(ImageSource.gallery),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('AI识别引擎', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'Gemini Vision API · 自动提取姓名、公司、职位、电话、邮箱、地址',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ]),
                  ),
                ]),
              ),
              if (_recognitionLog != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(_recognitionLog!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ],
              const SizedBox(height: 20),
            ])),
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

  /// 选择图片 + Gemini Vision AI识别
  Future<void> _pickAndRecognize(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _imagePath = image.path;
        _imageBytes = bytes;
        _isScanning = true;
        _recognitionLog = '正在调用 Gemini Vision API...';
      });

      // 调用 Gemini Vision API
      await _recognizeWithGemini(bytes, image.mimeType ?? 'image/jpeg');

    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _recognitionLog = '识别失败: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  /// Gemini Vision OCR核心
  Future<void> _recognizeWithGemini(Uint8List imageBytes, String mimeType) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
      );

      final prompt = '''请识别这张名片/图片中的联系人信息，严格返回以下JSON格式（不要markdown代码块）:
{
  "name": "姓名",
  "company": "公司名",
  "position": "职位",
  "phone": "电话号码",
  "email": "邮箱",
  "address": "地址",
  "industry": "行业(healthcare/finance/technology/trading/consulting/manufacturing/realestate/other)",
  "relation_type": "关系类型(agent/clinic/retailer/advisor/investor/partner/other)",
  "confidence": 0.95
}
如果有多个电话号码，用逗号分隔放在phone字段。如果某项无法识别，返回空字符串。''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]);

      final response = await model.generateContent([content]);
      final text = response.text ?? '';

      if (mounted) {
        setState(() => _recognitionLog = 'AI返回: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      }

      // 解析JSON
      _parseGeminiResponse(text);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _recognitionLog = 'Gemini API调用失败: $e';
        });
        // 回退到手动录入
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI识别失败, 可手动录入: $e'), backgroundColor: AppTheme.warning),
        );
        setState(() => _showResult = true);
      }
    }
  }

  void _parseGeminiResponse(String text) {
    try {
      // 清理可能的markdown代码块
      String jsonStr = text.trim();
      if (jsonStr.startsWith('```json')) jsonStr = jsonStr.substring(7);
      if (jsonStr.startsWith('```')) jsonStr = jsonStr.substring(3);
      if (jsonStr.endsWith('```')) jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      jsonStr = jsonStr.trim();

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      _nameCtrl.text = data['name'] as String? ?? '';
      _companyCtrl.text = data['company'] as String? ?? '';
      _positionCtrl.text = data['position'] as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
      _emailCtrl.text = data['email'] as String? ?? '';
      _addressCtrl.text = data['address'] as String? ?? '';

      // 自动匹配行业
      final industryStr = data['industry'] as String? ?? 'other';
      _industry = _matchIndustry(industryStr);

      // 自动匹配关系类型
      final relStr = data['relation_type'] as String? ?? 'other';
      _myRelation = _matchRelation(relStr);

      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0;

      setState(() {
        _isScanning = false;
        _showResult = true;
        _recognitionLog = '识别成功! 置信度: ${(confidence * 100).toStringAsFixed(0)}%';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI识别成功! ${_nameCtrl.text.isNotEmpty ? _nameCtrl.text : "请确认信息"} | 置信度${(confidence * 100).toStringAsFixed(0)}%'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      // JSON解析失败，尝试模糊提取
      setState(() {
        _isScanning = false;
        _showResult = true;
        _recognitionLog = 'JSON解析失败, 已展示手动录入: $e';
      });
    }
  }

  Industry _matchIndustry(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('health') || lower.contains('医')) return Industry.healthcare;
    if (lower.contains('finance') || lower.contains('金融')) return Industry.finance;
    if (lower.contains('tech')) return Industry.technology;
    if (lower.contains('trad') || lower.contains('贸易')) return Industry.trading;
    if (lower.contains('consult') || lower.contains('咨询')) return Industry.consulting;
    if (lower.contains('manuf') || lower.contains('建设') || lower.contains('制造')) return Industry.construction;
    if (lower.contains('real') || lower.contains('不动产') || lower.contains('地产')) return Industry.realEstate;
    return Industry.other;
  }

  MyRelationType _matchRelation(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('agent') || lower.contains('代理')) return MyRelationType.agent;
    if (lower.contains('clinic') || lower.contains('诊所')) return MyRelationType.clinic;
    if (lower.contains('retail') || lower.contains('零售')) return MyRelationType.retailer;
    if (lower.contains('advis') || lower.contains('顾问')) return MyRelationType.advisor;
    if (lower.contains('invest') || lower.contains('投资')) return MyRelationType.investor;
    if (lower.contains('partner') || lower.contains('合作')) return MyRelationType.partner;
    return MyRelationType.other;
  }

  Widget _buildResultForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(_imageBytes != null ? Icons.auto_awesome : _imagePath != null ? Icons.photo_camera : Icons.edit_note, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_imageBytes != null ? 'AI识别结果' : _imagePath != null ? '照片已获取' : '手动录入', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_recognitionLog ?? '请填写并确认信息后保存', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
        // 预览缩略图
        if (_imageBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover),
          ),
        ],
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
            label: Text(ind.label), selected: isSelected,
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
            label: Text(rel.label), selected: isSelected,
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
                _imagePath = null;
                _imageBytes = null;
                _recognitionLog = null;
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
      SnackBar(content: Text('${_nameCtrl.text} 已添加到人脉库'), backgroundColor: AppTheme.success),
    );
    Navigator.pop(context);
  }
}
