import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../utils/theme.dart';

/// Excel/CSV 文件导入人脉 + 图片识别上传
class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});
  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<List<dynamic>> _csvData = [];
  List<Map<String, String>> _parsedContacts = [];
  bool _isParsing = false;
  String? _error;
  // Column mapping
  int _nameCol = 0;
  int _companyCol = 1;
  int _positionCol = 2;
  int _phoneCol = 3;
  int _emailCol = 4;
  bool _hasHeader = true;

  // Image recognition
  final ImagePicker _picker = ImagePicker();
  bool _isRecognizing = false;
  String? _imagePath;
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
          tabs: const [Tab(text: 'CSV/Excel导入'), Tab(text: '图片识别')],
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
        // Instructions
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

        // Paste CSV data
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
            if (text.isNotEmpty) {
              _parseCsv(text);
            }
          },
        ),
        const SizedBox(height: 8),

        // Options
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

        // Preview parsed contacts
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

  // ====== Tab 2: Image Recognition ======
  Widget _imageRecognitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.info.withValues(alpha: 0.3))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.image_search, color: AppTheme.info, size: 16),
              SizedBox(width: 8),
              Text('图片识别说明', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            SizedBox(height: 8),
            Text('支持上传截图/照片, AI识别其中的联系人信息\n支持格式: 名片照片, 通讯录截图, 表格截图等',
              style: TextStyle(color: AppTheme.slate, fontSize: 11, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 16),

        // Upload buttons
        Row(children: [
          Expanded(child: _uploadBtn(Icons.camera_alt, '拍照识别', () => _pickImage(ImageSource.camera))),
          const SizedBox(width: 12),
          Expanded(child: _uploadBtn(Icons.photo_library, '相册选择', () => _pickImage(ImageSource.gallery))),
        ]),
        const SizedBox(height: 16),

        if (_isRecognizing)
          const Center(child: Column(children: [
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppTheme.gold),
            SizedBox(height: 12),
            Text('正在识别图片内容...', style: TextStyle(color: AppTheme.slate, fontSize: 12)),
          ])),

        if (_imagePath != null && !_isRecognizing) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('图片已上传', style: TextStyle(color: AppTheme.success, fontSize: 12))),
              TextButton(onPressed: () => setState(() { _imagePath = null; _recognizedContacts = []; }),
                child: const Text('清除', style: TextStyle(fontSize: 11))),
            ]),
          ),
        ],

        if (_recognizedContacts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [
            Text('识别到 ${_recognizedContacts.length} 条记录', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13)),
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
          border: Border.all(color: AppTheme.steel.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.gold, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    if (xfile == null) return;
    setState(() { _imagePath = xfile.path; _isRecognizing = true; _recognizedContacts = []; });

    // Simulate AI recognition (placeholder - in production use Gemini API)
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isRecognizing = false;
      // Show demo result - in production this would use google_generative_ai
      _recognizedContacts = [
        {'name': '(识别结果)', 'company': '请使用CSV导入或名片扫描', 'position': '', 'phone': '', 'email': ''},
      ];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片已上传, 请配合CSV导入功能使用'), backgroundColor: AppTheme.info));
    }
  }
}
