import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';
import '../providers/crm_provider.dart';
import '../models/contact.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Row(children: [
              Icon(Icons.build_circle, color: AppTheme.primaryPurple, size: 24),
              SizedBox(width: 10),
              Text('工具箱', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
          _sectionTitle('AI 助手'),
          _toolCard(context, Icons.auto_awesome, 'Gemini AI', '打开Google Gemini进行AI对话', AppTheme.primaryPurple, () => _openGemini(context)),
          const SizedBox(height: 20),
          _sectionTitle('数据导出'),
          _toolCard(context, Icons.people_alt, '导出联系人', '导出所有联系人为CSV/Excel', const Color(0xFF00B894), () => _exportContacts(context)),
          const SizedBox(height: 8),
          _toolCard(context, Icons.receipt_long, '导出交易', '导出所有交易记录为CSV/Excel', const Color(0xFF0984E3), () => _exportDeals(context)),
          const SizedBox(height: 8),
          _toolCard(context, Icons.shopping_cart, '导出订单', '导出所有销售订单为CSV/Excel', AppTheme.accentGold, () => _exportOrders(context)),
          const SizedBox(height: 8),
          _toolCard(context, Icons.inventory, '导出产品', '导出产品目录和价格为CSV/Excel', const Color(0xFFE17055), () => _exportProducts(context)),
          const SizedBox(height: 20),
          _sectionTitle('快捷通讯'),
          Consumer<CrmProvider>(builder: (context, crm, _) {
            final recentContacts = crm.allContacts.take(5).toList();
            if (recentContacts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('暂无联系人', style: TextStyle(color: AppTheme.textSecondary))),
              );
            }
            return Column(children: recentContacts.map((c) => _contactQuickAction(context, c)).toList());
          }),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  Widget _toolCard(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ]),
      ),
    );
  }

  Widget _contactQuickAction(BuildContext context, Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: contact.industry.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(contact.name.isNotEmpty ? contact.name[0] : '?', style: TextStyle(color: contact.industry.color, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contact.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(contact.company, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        if (contact.phone.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.phone, color: AppTheme.success, size: 20),
            onPressed: () => _makeCall(context, contact.phone),
            tooltip: '拨打电话',
          ),
          IconButton(
            icon: const Icon(Icons.sms, color: AppTheme.primaryBlue, size: 20),
            onPressed: () => _sendSms(context, contact.phone),
            tooltip: '发送短信',
          ),
        ],
        if (contact.email.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.email, color: AppTheme.primaryPurple, size: 20),
            onPressed: () => _sendEmail(context, contact.email, contact.name),
            tooltip: '发送邮件',
          ),
      ]),
    );
  }

  // ========== Actions ==========

  void _openGemini(BuildContext context) async {
    final uri = Uri.parse('https://gemini.google.com/');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法打开 Gemini'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _makeCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法拨打 $phone'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _sendSms(BuildContext context, String phone) async {
    final uri = Uri.parse('sms:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法发送短信到 $phone'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _sendEmail(BuildContext context, String email, String name) async {
    final uri = Uri.parse('mailto:$email?subject=Re: $name&body=Dear $name,%0A%0A');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法发送邮件到 $email'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _exportContacts(BuildContext context) {
    final crm = context.read<CrmProvider>();
    final contacts = crm.allContacts;
    final rows = <List<String>>[
      ['姓名', '公司', '职位', '电话', '邮箱', '地址', '行业', '关系', '强度', '备注', '创建日期'],
      ...contacts.map((c) => [
        c.name, c.company, c.position, c.phone, c.email, c.address,
        c.industry.label, c.myRelation.label, c.strength.label, c.notes,
        Formatters.dateFull(c.createdAt),
      ]),
    ];
    _downloadCsv(context, rows, 'contacts_${DateTime.now().millisecondsSinceEpoch}.csv', '联系人');
  }

  void _exportDeals(BuildContext context) {
    final crm = context.read<CrmProvider>();
    final deals = crm.deals;
    final rows = <List<String>>[
      ['标题', '客户', '阶段', '金额', '概率', '描述', '预计成交日期', '创建日期'],
      ...deals.map((d) => [
        d.title, d.contactName, d.stage.label, d.amount.toString(), '${d.probability}%',
        d.description, Formatters.dateFull(d.expectedCloseDate), Formatters.dateFull(d.createdAt),
      ]),
    ];
    _downloadCsv(context, rows, 'deals_${DateTime.now().millisecondsSinceEpoch}.csv', '交易');
  }

  void _exportOrders(BuildContext context) {
    final crm = context.read<CrmProvider>();
    final orders = crm.orders;
    final rows = <List<String>>[
      ['客户', '状态', '产品', '数量', '单价', '小计', '总计', '创建日期'],
      ...orders.expand((o) => o.items.map((item) => [
        o.contactName, SalesOrder.statusLabel(o.status), item.productName,
        item.quantity.toString(), item.unitPrice.toString(), item.subtotal.toString(),
        o.totalAmount.toString(), Formatters.dateFull(o.createdAt),
      ])),
    ];
    _downloadCsv(context, rows, 'orders_${DateTime.now().millisecondsSinceEpoch}.csv', '订单');
  }

  void _exportProducts(BuildContext context) {
    final crm = context.read<CrmProvider>();
    final products = crm.products;
    final rows = <List<String>>[
      ['编号', '名称', '类别', '规格', '代理价', '诊所价', '零售价', '代理整箱', '诊所整箱', '零售整箱', '每箱数量'],
      ...products.map((p) => [
        p.code, p.name, ProductCategory.label(p.category), p.specification,
        p.agentPrice.toString(), p.clinicPrice.toString(), p.retailPrice.toString(),
        p.agentTotalPrice.toString(), p.clinicTotalPrice.toString(), p.retailTotalPrice.toString(),
        p.unitsPerBox.toString(),
      ]),
    ];
    _downloadCsv(context, rows, 'products_${DateTime.now().millisecondsSinceEpoch}.csv', '产品');
  }

  void _downloadCsv(BuildContext context, List<List<String>> rows, String filename, String label) {
    try {
      // Add BOM for Excel to recognize UTF-8
      final csvString = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode('\uFEFF$csvString');
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = filename
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label导出成功: $filename'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }
}
