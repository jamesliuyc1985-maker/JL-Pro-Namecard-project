import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final product = crm.getProduct(productId);
      if (product == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('产品未找到')));

      Color catColor;
      IconData catIcon;
      switch (product.category) {
        case 'exosome': catColor = const Color(0xFF00B894); catIcon = Icons.bubble_chart; break;
        case 'nad': catColor = const Color(0xFFE17055); catIcon = Icons.flash_on; break;
        case 'nmn': catColor = const Color(0xFF0984E3); catIcon = Icons.medication; break;
        default: catColor = AppTheme.primaryPurple; catIcon = Icons.science; break;
      }

      return Scaffold(
        body: SafeArea(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, product, catColor, catIcon)),
            SliverToBoxAdapter(child: _buildPricingTable(product, catColor)),
            SliverToBoxAdapter(child: _buildInfo(product)),
            SliverToBoxAdapter(child: _buildDescription(product)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateOrderDialog(context, crm, product),
          icon: const Icon(Icons.shopping_cart),
          label: const Text('创建订单'),
          backgroundColor: catColor,
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, Product product, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.3), AppTheme.darkBg], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
          const Spacer(),
        ]),
        const SizedBox(height: 12),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 16),
        Text(product.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(product.nameJa, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _badge(ProductCategory.label(product.category), color),
          const SizedBox(width: 8),
          _badge(product.code, AppTheme.primaryBlue),
          const SizedBox(width: 8),
          _badge(product.specification, AppTheme.warning),
        ]),
      ]),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPricingTable(Product product, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.price_change, color: color, size: 20),
            const SizedBox(width: 8),
            const Text('价格体系', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          _priceRow('代理价 (单瓶)', Formatters.currency(product.agentPrice), '折扣30%', const Color(0xFF00B894)),
          _priceRow('诊所价 (单瓶)', Formatters.currency(product.clinicPrice), '折扣40%', const Color(0xFF0984E3)),
          _priceRow('零售价 (单瓶)', Formatters.currency(product.retailPrice), '建议零售', AppTheme.accentGold),
          const Divider(color: AppTheme.cardBgLight, height: 20),
          Text('整箱价 (${product.unitsPerBox}瓶/箱)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          _priceRow('代理整箱', Formatters.currency(product.agentTotalPrice), '', const Color(0xFF00B894)),
          _priceRow('诊所整箱', Formatters.currency(product.clinicTotalPrice), '', const Color(0xFF0984E3)),
          _priceRow('零售整箱', Formatters.currency(product.retailTotalPrice), '', AppTheme.accentGold),
        ]),
      ),
    );
  }

  Widget _priceRow(String label, String price, String note, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        Expanded(flex: 2, child: Text(price, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right)),
        if (note.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(note, style: TextStyle(color: color, fontSize: 9)),
          ),
        ],
      ]),
    );
  }

  Widget _buildInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('产品信息', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoItem(Icons.thermostat, '保存方法', product.storageMethod),
          _infoItem(Icons.schedule, '有效期', product.shelfLife),
          _infoItem(Icons.medical_services, '使用方法', product.usage),
          if (product.notes.isNotEmpty) _infoItem(Icons.info, '备注', product.notes),
        ]),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ]),
      ]),
    );
  }

  Widget _buildDescription(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('产品介绍', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(product.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.business, color: AppTheme.primaryPurple, size: 16),
              SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('能道再生株式会社', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('東京都千代田区神田佐久間町3丁目28', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                Text('info@noudosaisei.com', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11)),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showCreateOrderDialog(BuildContext context, CrmProvider crm, Product product) {
    int quantity = 1;
    String priceType = 'retail';
    final contacts = crm.allContacts;
    String? selectedContactId;
    String selectedContactName = '';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          double unitPrice;
          switch (priceType) {
            case 'agent': unitPrice = product.agentPrice; break;
            case 'clinic': unitPrice = product.clinicPrice; break;
            default: unitPrice = product.retailPrice; break;
          }
          final total = unitPrice * quantity;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('快速下单', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedContactId,
                decoration: const InputDecoration(labelText: '选择客户', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary)),
                dropdownColor: AppTheme.cardBgLight,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: contacts.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.company}'))).toList(),
                onChanged: (v) => setModalState(() {
                  selectedContactId = v;
                  final c = contacts.firstWhere((c) => c.id == v);
                  selectedContactName = c.name;
                }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('价格类型: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ...[
                  {'key': 'agent', 'label': '代理'},
                  {'key': 'clinic', 'label': '诊所'},
                  {'key': 'retail', 'label': '零售'},
                ].map((pt) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(pt['label']!), selected: priceType == pt['key'],
                    onSelected: (_) => setModalState(() => priceType = pt['key']!),
                    selectedColor: AppTheme.primaryPurple, backgroundColor: AppTheme.cardBgLight,
                    labelStyle: TextStyle(color: priceType == pt['key'] ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('数量: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.textSecondary), onPressed: () { if (quantity > 1) setModalState(() => quantity--); }),
                Text('$quantity', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryPurple), onPressed: () => setModalState(() => quantity++)),
                const Spacer(),
                Text(Formatters.currency(total), style: const TextStyle(color: AppTheme.accentGold, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: selectedContactId == null ? null : () {
                  final order = SalesOrder(
                    id: crm.generateId(),
                    contactId: selectedContactId!,
                    contactName: selectedContactName,
                    status: 'draft',
                    items: [OrderItem(
                      productId: product.id,
                      productName: product.name,
                      productCode: product.code,
                      quantity: quantity,
                      unitPrice: unitPrice,
                      subtotal: total,
                    )],
                    totalAmount: total,
                  );
                  crm.addOrder(order);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('订单已创建: $selectedContactName - ${Formatters.currency(total)}'), backgroundColor: AppTheme.success),
                  );
                },
                child: const Text('确认下单'),
              )),
              const SizedBox(height: 16),
            ]),
          );
        });
      },
    );
  }
}
