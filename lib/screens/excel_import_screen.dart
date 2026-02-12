import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

/// 多类型文件导入: CSV/Excel + 图片AI识别 + 名片批量识别
class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});
  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> with SingleTickerProviderStateMixin {
  static const _apiKey = 'AIzaSyBMTKwBDxjH2JakRFMhFRWxltXXjE-hk4A';
  late TabController _tabCtrl;
  List<List<dynamic>> _csvData = [];
  List<Map<String, String>> _parsedContacts = [];
  bool _isParsing = false;
  String? _error;
  int _nameCol = 0;
  int _companyCol = 1;
  int _positionCol = 2;
  int _phoneCol = 3;
  int _emailCol = 4;
  bool _hasHeader = true;

  // Image recognition
  final ImagePicker _picker = ImagePicker();
  bool _isRecognizing = false;
  Uint8List? _imageBytes;
  String? _recognitionLog;
  List<Map<String, String>> _recognizedContacts = [];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入人脉', style: TextStyle(color: AppTheme.offWhite, fontSize: 16)),
        backgroundColor: AppTheme.navy,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.offWhite), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.slate,
          tabs: const [Tab(text: 'CSV/Excel导入'), Tab(text: 'AI图片识别')],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _csvImportTab(),
        _imageRecognitionTab(),
      ]),
    );
  }

  // ====== Tab 1: CSV Import ======
  Widget _csvImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.info.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.info, size: 16),
              SizedBox(width: 8),
              Text('CSV格式说明', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            const Text('支持格式: CSV (逗号分隔)\n列顺序: 姓名, 公司, 职位, 电话, 邮箱\n首行可以是标题行 (自动跳过)',
              style: TextStyle(color: AppTheme.slate, fontSize: 11, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(4)),
              child: const Text('田中太郎,三菱商事,部長,03-1234-5678,tanaka@example.com\n佐藤花子,住友不動産,課長,090-1111-2222,sato@example.com',
                style: TextStyle(color: AppTheme.gold, fontSize: 10, fontFamily: 'monospace')),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        const Text('粘贴CSV数据:', style: TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 8,
          style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: '粘贴CSV数据到此处...',
            hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 12),
            filled: true, fillColor: AppTheme.navyMid,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.steel.withValues(alpha: 0.3))),
          ),
          onChanged: (text) {
            if (text.isNotEmpty) { _parseCsv(text); }
          },
        ),
        const SizedBox(height: 8),

        Row(children: [
          Checkbox(
            value: _hasHeader,
            onChanged: (v) => setState(() => _hasHeader = v ?? true),
            activeColor: AppTheme.gold,
          ),
          const Text('首行为标题行', style: TextStyle(color: AppTheme.offWhite, fontSize: 12)),
        ]),

        if (_isParsing) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.gold))),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12))),

        if (_parsedContacts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [
            Text('识别到 ${_parsedContacts.length} 条记录', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _importContacts(_parsedContacts),
              icon: const Icon(Icons.download, size: 16),
              label: Text('导入全部 (${_parsedContacts.length})'),
            ),
          ]),
          const SizedBox(height: 8),
          ..._parsedContacts.take(5).map((c) => _previewContactCard(c)),
          if (_parsedContacts.length > 5)
            Padding(padding: const EdgeInsets.all(8),
              child: Text('...还有 ${_parsedContacts.length - 5} 条', style: const TextStyle(color: AppTheme.slate, fontSize: 11))),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  void _parseCsv(String text) {
    setState(() { _isParsing = true; _error = null; });
    try {
      final rows = const CsvToListConverter().convert(text, eol: '\n');
      final startIdx = _hasHeader ? 1 : 0;
      final contacts = <Map<String, String>>[];
      for (int i = startIdx; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) continue;
        contacts.add({
          'name': row.length > _nameCol ? row[_nameCol].toString().trim() : '',
          'company': row.length > _companyCol ? row[_companyCol].toString().trim() : '',
          'position': row.length > _positionCol ? row[_positionCol].toString().trim() : '',
          'phone': row.length > _phoneCol ? row[_phoneCol].toString().trim() : '',
          'email': row.length > _emailCol ? row[_emailCol].toString().trim() : '',
        });
      }
      setState(() { _parsedContacts = contacts.where((c) => c['name']!.isNotEmpty).toList(); _csvData = rows; });
    } catch (e) {
      setState(() => _error = '解析失败: $e');
    }
    setState(() => _isParsing = false);
  }

  void _importContacts(List<Map<String, String>> contacts) async {
    final crm = context.read<CrmProvider>();
    int imported = 0;
    for (final c in contacts) {
      if (c['name']?.isEmpty ?? true) continue;
      await crm.addContact(Contact(
        id: crm.generateId(),
        name: c['name'] ?? '',
        company: c['company'] ?? '',
        position: c['position'] ?? '',
        phone: c['phone'] ?? '',
        email: c['email'] ?? '',
      ));
      imported++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $imported 条人脉'), backgroundColor: AppTheme.success));
      Navigator.pop(context);
    }
  }

  Widget _previewContactCard(Map<String, String> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text((c['name'] ?? '?')[0], style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['name'] ?? '', style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 12)),
          Text('${c['company']} | ${c['position']}', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
        ])),
        if ((c['phone'] ?? '').isNotEmpty) const Icon(Icons.phone, color: AppTheme.slate, size: 12),
        if ((c['email'] ?? '').isNotEmpty) ...[const SizedBox(width: 4), const Icon(Icons.email, color: AppTheme.slate, size: 12)],
      ]),
    );
  }

  // ====== Tab 2: AI Image Recognition (Gemini Vision) ======
  Widget _imageRecognitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, color: AppTheme.gold, size: 16),
              SizedBox(width: 8),
              Text('Gemini Vision AI识别', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            SizedBox(height: 8),
            Text('支持上传以下类型图片, AI自动提取联系人信息:\n'
                '- 名片照片 (中/日/英/韩多语言)\n'
                '- 通讯录截图\n'
                '- Excel/表格截图\n'
                '- 名单列表照片',
              style: TextStyle(color: AppTheme.slate, fontSize: 11, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 16),

        Row(children: [
          if (!kIsWeb) ...[
            Expanded(child: _uploadBtn(Icons.camera_alt, '拍照识别', () => _pickAndRecognizeImage(ImageSource.camera))),
            const SizedBox(width: 12),
          ],
          Expanded(child: _uploadBtn(Icons.photo_library, kIsWeb ? '上传图片识别' : '相册选择识别', () => _pickAndRecognizeImage(ImageSource.gallery))),
        ]),
        const SizedBox(height: 16),

        if (_isRecognizing)
          Center(child: Column(children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppTheme.gold),
            const SizedBox(height: 12),
            Text(_recognitionLog ?? '正在AI识别...', style: const TextStyle(color: AppTheme.slate, fontSize: 12)),
          ])),

        if (_imageBytes != null && !_isRecognizing) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_imageBytes!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_recognitionLog ?? '识别完成', style: const TextStyle(color: AppTheme.success, fontSize: 12))),
                TextButton(onPressed: () => setState(() { _imageBytes = null; _recognizedContacts = []; _recognitionLog = null; }),
                  child: const Text('清除', style: TextStyle(fontSize: 11))),
              ]),
            ]),
          ),
        ],

        if (_recognizedContacts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [
            Text('AI识别到 ${_recognizedContacts.length} 条记录', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _importContacts(_recognizedContacts),
              icon: const Icon(Icons.download, size: 16),
              label: Text('导入 (${_recognizedContacts.length})'),
            ),
          ]),
          const SizedBox(height: 8),
          ..._recognizedContacts.map((c) => _previewContactCard(c)),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _uploadBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.navyLight, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.gold, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  /// 选择图片 + Gemini Vision AI批量识别
  Future<void> _pickAndRecognizeImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isRecognizing = true;
        _recognizedContacts = [];
        _recognitionLog = '正在调用 Gemini Vision API...';
      });

      // Gemini Vision 批量识别
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
      );

      final prompt = '''请识别这张图片中所有的联系人信息。图片可能是名片、通讯录截图、Excel表格截图或名单列表。
严格返回JSON数组格式（不要markdown代码块）:
[
  {"name": "姓名", "company": "公司名", "position": "职位", "phone": "电话", "email": "邮箱"},
  ...
]
规则:
- 尽可能提取所有可见联系人
- 如果某项无法识别返回空字符串
- 支持中文/日文/英文/韩文
- 如果图片不含联系人信息，返回空数组 []''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart(xfile.mimeType ?? 'image/jpeg', bytes),
      ]);

      final response = await model.generateContent([content]);
      final text = response.text ?? '[]';

      // 解析JSON
      String jsonStr = text.trim();
      if (jsonStr.startsWith('```json')) jsonStr = jsonStr.substring(7);
      if (jsonStr.startsWith('```')) jsonStr = jsonStr.substring(3);
      if (jsonStr.endsWith('```')) jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      jsonStr = jsonStr.trim();

      final decoded = jsonDecode(jsonStr);
      List<Map<String, String>> contacts = [];

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final name = (item['name'] ?? '').toString().trim();
            if (name.isNotEmpty) {
              contacts.add({
                'name': name,
                'company': (item['company'] ?? '').toString().trim(),
                'position': (item['position'] ?? '').toString().trim(),
                'phone': (item['phone'] ?? '').toString().trim(),
                'email': (item['email'] ?? '').toString().trim(),
              });
            }
          }
        }
      }

      setState(() {
        _isRecognizing = false;
        _recognizedContacts = contacts;
        _recognitionLog = contacts.isEmpty ? 'AI未识别到联系人信息' : '成功识别 ${contacts.length} 条联系人!';
      });

      if (mounted && contacts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI识别成功! 发现 ${contacts.length} 条联系人'), backgroundColor: AppTheme.success));
      }

    } catch (e) {
      setState(() {
        _isRecognizing = false;
        _recognitionLog = '识别失败: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI识别失败: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }
}
