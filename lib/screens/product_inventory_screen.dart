import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/qc_record.dart';
import '../models/deal.dart';
import '../models/contact.dart';
import '../models/factory.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'product_detail_screen.dart';

class ProductInventoryScreen extends StatefulWidget {
  const ProductInventoryScreen({super.key});
  @override
  State<ProductInventoryScreen> createState() => _ProductInventoryScreenState();
}

class _ProductInventoryScreenState extends State<ProductInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'all';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _header(context, crm),
        _summaryBar(crm),
        _tabBar(),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _catalogTab(crm),
          _stockTab(crm),
          _qcTab(crm),
          _recordsTab(crm),
        ])),
      ]));
    });
  }

  // === Header ===
  Widget _header(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('产品 & 库存', style: TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Product & Inventory', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
        ])),
        _actionBtn(Icons.science_outlined, '送检', () => _showCreateQcSheet(context, crm)),
        _actionBtn(Icons.shopping_cart, '快捷下单', () => _showQuickOrderSheet(context, crm)),
        _actionBtn(Icons.add, '入库/出库', () => _showAddRecordSheet(context, crm)),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      tooltip: tip,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.steel.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppTheme.gold, size: 18),
      ),
      onPressed: onTap,
    );
  }

  // === Summary Bar ===
  Widget _summaryBar(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    final totalStock = stocks.fold<int>(0, (s, i) => s + i.currentStock);
    final lowStock = stocks.where((s) => s.currentStock > 0 && s.currentStock < 5).length;
    final outOfStock = stocks.where((s) => s.currentStock <= 0).length;
    final activeProd = crm.activeProductions.length;
    final activeQc = crm.activeQcRecords.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.navyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        _metric('${crm.products.length}', '产品', AppTheme.info, () => _drillProducts(crm)),
        _divider(),
        _metric('$totalStock', '总库存', AppTheme.gold, () => _drillStocks(crm, stocks)),
        _divider(),
        _metric('$lowStock', '低库存', AppTheme.warning, () => _drillLow(crm, stocks)),
        _divider(),
        _metric('$outOfStock', '缺货', AppTheme.danger, () => _drillOut(crm, stocks)),
        _divider(),
        _metric('$activeProd', '生产中', AppTheme.success, () => _drillProd(crm)),
        _divider(),
        _metric('$activeQc', '送检', AppTheme.info, () => _drillQc(crm)),
      ]),
    );
  }

  Widget _metric(String val, String label, Color c, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Column(children: [
      Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
    ])));
  }

  Widget _divider() => Container(width: 1, height: 28, color: AppTheme.steel.withValues(alpha: 0.2));

  // === Drilldowns ===
  void _drill(String title, IconData icon, List<Widget> items) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(icon, color: AppTheme.gold, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: AppTheme.offWhite, fontSize: 15, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate, size: 18), onPressed: () => Navigator.pop(ctx)),
          ])),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Text('无数据', style: TextStyle(color: AppTheme.slate)))
          else Flexible(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [...items, const SizedBox(height: 16)])),
        ]),
      ),
    );
  }

  Widget _dItem(String title, String sub, {String? trail, Color trailColor = AppTheme.gold}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.w500)),
          if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
        ])),
        if (trail != null) Text(trail, style: TextStyle(color: trailColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  void _drillProducts(CrmProvider crm) => _drill('产品列表 (${crm.products.length})', Icons.science_outlined,
    crm.products.map((p) => _dItem(p.name, '${ProductCategory.label(p.category)} | ${p.specification}', trail: Formatters.currency(p.retailPrice))).toList());
  void _drillStocks(CrmProvider crm, List<InventoryStock> stocks) => _drill('库存明细', Icons.inventory_2_outlined,
    stocks.map((s) => _dItem(s.productName, s.productCode, trail: '${s.currentStock}', trailColor: _stockColor(s.currentStock))).toList());
  void _drillLow(CrmProvider crm, List<InventoryStock> stocks) { final items = stocks.where((s) => s.currentStock > 0 && s.currentStock < 5).toList();
    _drill('低库存 (${items.length})', Icons.warning_amber_outlined, items.map((s) => _dItem(s.productName, '建议补货', trail: '${s.currentStock}', trailColor: AppTheme.warning)).toList()); }
  void _drillOut(CrmProvider crm, List<InventoryStock> stocks) { final items = stocks.where((s) => s.currentStock <= 0).toList();
    _drill('缺货 (${items.length})', Icons.error_outline, items.map((s) => _dItem(s.productName, '急需补货', trail: '0', trailColor: AppTheme.danger)).toList()); }
  void _drillProd(CrmProvider crm) => _drill('生产中 (${crm.activeProductions.length})', Icons.precision_manufacturing_outlined,
    crm.activeProductions.map((o) => _dItem(o.productName, '${o.factoryName} | x${o.quantity}')).toList());
  void _drillQc(CrmProvider crm) => _drill('送检中 (${crm.activeQcRecords.length})', Icons.science_outlined,
    crm.activeQcRecords.map((q) => _dItem(q.productName, '${QcRecord.testTypeLabel(q.testType)} | ${q.testLab}', trail: 'x${q.quantity}', trailColor: AppTheme.info)).toList());

  Color _stockColor(int qty) => qty <= 0 ? AppTheme.danger : qty < 5 ? AppTheme.warning : AppTheme.success;

  // === Tab Bar ===
  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppTheme.gold,
        indicatorWeight: 2,
        labelColor: AppTheme.offWhite,
        unselectedLabelColor: AppTheme.slate,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: AppTheme.steel.withValues(alpha: 0.2),
        tabs: const [Tab(text: '产品目录'), Tab(text: '库存总览'), Tab(text: '检测/QC'), Tab(text: '出入库')],
      ),
    );
  }

  // === Tab 1: Catalog ===
  Widget _catalogTab(CrmProvider crm) {
    final all = crm.products;
    final products = _selectedCategory == 'all' ? all : all.where((p) => p.category == _selectedCategory).toList();
    return Column(children: [
      _categoryFilter(),
      Padding(padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
        child: Row(children: [
          Text('${products.length} 款产品', style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
        ]),
      ),
      Expanded(child: products.isEmpty
        ? const Center(child: Text('暂无产品', style: TextStyle(color: AppTheme.slate)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (ctx, i) => _productCard(ctx, products[i], crm),
          )),
    ]);
  }

  Widget _categoryFilter() {
    const cats = [
      {'key': 'all', 'label': '全部'},
      {'key': 'exosome', 'label': '外泌体'},
      {'key': 'nad', 'label': 'NAD+'},
      {'key': 'nmn', 'label': 'NMN'},
    ];
    return SizedBox(height: 38, child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: cats.map((c) {
        final sel = _selectedCategory == c['key'];
        return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
          selected: sel, label: Text(c['label']!),
          onSelected: (_) => setState(() => _selectedCategory = c['key']!),
          selectedColor: AppTheme.gold,
          backgroundColor: AppTheme.navyMid,
          labelStyle: TextStyle(color: sel ? AppTheme.navy : AppTheme.offWhite, fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(color: sel ? AppTheme.gold : AppTheme.steel.withValues(alpha: 0.3)),
        ));
      }).toList(),
    ));
  }

  Widget _productCard(BuildContext context, Product product, CrmProvider crm) {
    final stock = crm.getProductStock(product.id);
    final qcPending = crm.getQcPendingQuantity(product.id);
    final reserved = crm.getReservedStock(product.id);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.navyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _fallbackThumb(product.category),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text('${product.specification} | ${product.code}', style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
              const SizedBox(height: 4),
              Row(children: [
                _tag(ProductCategory.label(product.category), AppTheme.info),
                const SizedBox(width: 6),
                _tag('库存:$stock', _stockColor(stock)),
                if (reserved > 0) ...[const SizedBox(width: 4), _tag('预留:$reserved', AppTheme.warning)],
                if (qcPending > 0) ...[const SizedBox(width: 4), _tag('送检:$qcPending', AppTheme.info)],
              ]),
            ])),
            const Icon(Icons.chevron_right, color: AppTheme.steel, size: 18),
          ]),
          const SizedBox(height: 8),
          // === 三级价格体系 ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.navyMid,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              _priceTag('代理', Formatters.currency(product.agentPrice), const Color(0xFF00B894)),
              Container(width: 1, height: 26, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppTheme.steel.withValues(alpha: 0.2)),
              _priceTag('诊所', Formatters.currency(product.clinicPrice), const Color(0xFF0984E3)),
              Container(width: 1, height: 26, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppTheme.steel.withValues(alpha: 0.2)),
              _priceTag('零售', Formatters.currency(product.retailPrice), AppTheme.gold),
              const Spacer(),
              Text('${product.unitsPerBox}瓶/箱', style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _priceTag(String label, String price, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600)),
      Text(price, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }

  Widget _fallbackThumb(String cat) {
    return Container(width: 56, height: 56, decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.science_outlined, color: AppTheme.slate, size: 24));
  }

  Widget _tag(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  // === Tab 2: Stock Overview ===
  Widget _stockTab(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    if (stocks.isEmpty) return const Center(child: Text('暂无库存数据', style: TextStyle(color: AppTheme.slate)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: stocks.length,
      itemBuilder: (ctx, i) {
        final s = stocks[i];
        final c = _stockColor(s.currentStock);
        final qcPending = crm.getQcPendingQuantity(s.productId);
        final reserved = crm.getReservedStock(s.productId);
        final available = s.currentStock - reserved;
        final label = s.currentStock <= 0 ? '缺货' : s.currentStock < 5 ? '低库存' : '正常';
        // 获取产品价格
        final product = crm.getProduct(s.productId);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${s.currentStock}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.productName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                Row(children: [
                  Text(s.productCode, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
                  if (reserved > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text('预留:$reserved', style: const TextStyle(color: AppTheme.warning, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  if (qcPending > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text('送检:$qcPending', style: const TextStyle(color: AppTheme.info, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
              ])),
              GestureDetector(
                onTap: () => _showQuickAdjustDialog(context, crm, s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(4)),
                  child: const Text('调整', style: TextStyle(color: AppTheme.gold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              _tag(label, c),
            ]),
            if (product != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const SizedBox(width: 54), // 与上方库存数字对齐
                Text('可用:$available', style: TextStyle(color: available <= 0 ? AppTheme.danger : AppTheme.slate, fontSize: 10, fontWeight: available <= 0 ? FontWeight.bold : FontWeight.normal)),
                const Spacer(),
                Text('代理${Formatters.currency(product.agentPrice)}', style: const TextStyle(color: Color(0xFF00B894), fontSize: 9)),
                const SizedBox(width: 8),
                Text('诊所${Formatters.currency(product.clinicPrice)}', style: const TextStyle(color: Color(0xFF0984E3), fontSize: 9)),
                const SizedBox(width: 8),
                Text('零售${Formatters.currency(product.retailPrice)}', style: const TextStyle(color: AppTheme.gold, fontSize: 9)),
              ]),
            ],
          ]),
        );
      },
    );
  }

  // === Tab 3: QC/检测 ===
  Widget _qcTab(CrmProvider crm) {
    final records = crm.qcRecords;
    if (records.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.science_outlined, color: AppTheme.slate, size: 48),
      const SizedBox(height: 12),
      const Text('暂无检测记录', style: TextStyle(color: AppTheme.slate)),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: () => _showCreateQcSheet(context, crm),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('创建送检'),
      ),
    ]));

    final sorted = List<QcRecord>.from(records)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final q = sorted[i];
        final isActive = QcStatus.activeStatuses.contains(q.status);
        Color statusColor;
        switch (q.status) {
          case QcStatus.passed: statusColor = AppTheme.success; break;
          case QcStatus.failed: statusColor = AppTheme.danger; break;
          case QcStatus.submitted: case QcStatus.inProgress: statusColor = AppTheme.info; break;
          case QcStatus.cancelled: statusColor = AppTheme.slate; break;
          default: statusColor = AppTheme.warning; break;
        }
        return GestureDetector(
          onTap: () => _showQcDetailSheet(ctx, crm, q),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isActive ? statusColor.withValues(alpha: 0.4) : AppTheme.steel.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.science, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.productName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                Row(children: [
                  Text(QcRecord.testTypeLabel(q.testType), style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
                  if (q.testLab.isNotEmpty) ...[const SizedBox(width: 6), Text(q.testLab, style: const TextStyle(color: AppTheme.slate, fontSize: 10))],
                  if (q.batchNumber.isNotEmpty) ...[const SizedBox(width: 6), Text('#${q.batchNumber}', style: const TextStyle(color: AppTheme.slate, fontSize: 9))],
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('x${q.quantity}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                _tag(QcStatus.label(q.status), statusColor),
              ]),
            ]),
          ),
        );
      },
    );
  }

  // === QC Detail Sheet ===
  void _showQcDetailSheet(BuildContext context, CrmProvider crm, QcRecord q) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.science, color: AppTheme.info, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('检测详情: ${q.productName}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600))),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: AppTheme.navyLight,
                      title: const Text('删除检测记录', style: TextStyle(color: AppTheme.offWhite, fontSize: 15)),
                      content: Text('确认删除 ${q.productName} 的检测记录?', style: const TextStyle(color: AppTheme.slate)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('删除', style: TextStyle(color: AppTheme.danger))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await crm.deleteQcRecord(q.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('检测记录已删除'), backgroundColor: AppTheme.danger));
                    }
                  }
                },
              ),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            _qcInfoRow('状态', QcStatus.label(q.status)),
            _qcInfoRow('数量', 'x${q.quantity}'),
            _qcInfoRow('类型', QcRecord.testTypeLabel(q.testType)),
            if (q.testLab.isNotEmpty) _qcInfoRow('机构', q.testLab),
            if (q.batchNumber.isNotEmpty) _qcInfoRow('批次', q.batchNumber),
            if (q.result.isNotEmpty) _qcInfoRow('结果', q.result),
            if (q.notes.isNotEmpty) _qcInfoRow('备注', q.notes),
            const SizedBox(height: 16),
            if (QcStatus.activeStatuses.contains(q.status)) ...[
              const Text('更新状态:', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
              const SizedBox(height: 8),
              Row(children: [
                if (q.status == QcStatus.pending) Expanded(child: _qcActionBtn('送检', AppTheme.info, () async {
                  await crm.updateQcStatus(q.id, QcStatus.submitted);
                  if (ctx.mounted) { Navigator.pop(ctx); set(() {}); }
                })),
                if (q.status == QcStatus.submitted) Expanded(child: _qcActionBtn('检测中', AppTheme.warning, () async {
                  await crm.updateQcStatus(q.id, QcStatus.inProgress);
                  if (ctx.mounted) { Navigator.pop(ctx); set(() {}); }
                })),
                if (q.status == QcStatus.submitted || q.status == QcStatus.inProgress) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _qcActionBtn('合格', AppTheme.success, () async {
                    await crm.updateQcStatus(q.id, QcStatus.passed, result: '全部指标合格');
                    if (ctx.mounted) Navigator.pop(ctx);
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _qcActionBtn('不合格', AppTheme.danger, () async {
                    await crm.updateQcStatus(q.id, QcStatus.failed, result: '部分指标不合格');
                    if (ctx.mounted) Navigator.pop(ctx);
                  })),
                ],
              ]),
            ],
            const SizedBox(height: 12),
          ]),
        );
      }),
    );
  }

  Widget _qcInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      SizedBox(width: 60, child: Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 11))),
      Expanded(child: Text(value, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12))),
    ]));
  }

  Widget _qcActionBtn(String label, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.4))),
        child: Center(child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12))),
      ),
    );
  }

  // === Create QC Sheet ===
  void _showCreateQcSheet(BuildContext context, CrmProvider crm) {
    Product? selectedProduct;
    final qtyCtrl = TextEditingController(text: '1');
    final labCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String testType = 'comprehensive';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.science, color: AppTheme.info, size: 18),
              const SizedBox(width: 8),
              const Text('创建送检', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<Product>(
              value: selectedProduct,
              decoration: const InputDecoration(labelText: '选择产品'),
              dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite),
              items: crm.products.map((p) {
                final stock = crm.getProductStock(p.id);
                return DropdownMenuItem(value: p, child: Text('${p.name} (库存:$stock)', style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (v) => set(() => selectedProduct = v),
            ),
            const SizedBox(height: 8),
            const Text('检测类型', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 6, children: ['comprehensive', 'stability', 'purity', 'sterility', 'appearance', 'potency'].map((t) {
              final sel = testType == t;
              return ChoiceChip(
                label: Text(QcRecord.testTypeLabel(t), style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                selected: sel, onSelected: (_) => set(() => testType = t),
                selectedColor: AppTheme.info, backgroundColor: AppTheme.navyMid,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
              );
            }).toList()),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.offWhite),
                decoration: const InputDecoration(labelText: '送检数量'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: batchCtrl, style: const TextStyle(color: AppTheme.offWhite),
                decoration: const InputDecoration(labelText: '批次号'))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: labCtrl, style: const TextStyle(color: AppTheme.offWhite),
              decoration: const InputDecoration(labelText: '检测机构')),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.offWhite),
              decoration: const InputDecoration(labelText: '备注')),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: selectedProduct == null ? null : () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                final err = await crm.createQcRecord(QcRecord(
                  id: crm.generateId(),
                  productId: selectedProduct!.id,
                  productName: selectedProduct!.name,
                  productCode: selectedProduct!.code,
                  quantity: qty,
                  testType: testType,
                  testLab: labCtrl.text,
                  batchNumber: batchCtrl.text,
                  notes: notesCtrl.text,
                ));
                if (err != null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.danger));
                  }
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('送检记录已创建'), backgroundColor: AppTheme.success));
                }
              },
              child: const Text('确认送检'),
            )),
            const SizedBox(height: 16),
          ]),
        );
      }),
    );
  }

  // === Tab 4: Records ===
  Widget _recordsTab(CrmProvider crm) {
    final records = crm.inventoryRecords;
    if (records.isEmpty) return const Center(child: Text('暂无出入库记录', style: TextStyle(color: AppTheme.slate)));

    final sorted = List<InventoryRecord>.from(records)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final r = sorted[i];
        final isIn = r.type == 'in';
        final isAdj = r.type == 'adjust';
        final c = isIn ? AppTheme.success : isAdj ? AppTheme.warning : AppTheme.danger;
        return Dismissible(
          key: Key(r.id),
          direction: DismissDirection.endToStart,
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: AppTheme.danger)),
          onDismissed: (_) => crm.deleteInventoryRecord(r.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              Icon(isIn ? Icons.arrow_downward : isAdj ? Icons.tune : Icons.arrow_upward, color: c, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.productName, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.w500)),
                Row(children: [
                  Text(InventoryRecord.typeLabel(r.type), style: TextStyle(color: c, fontSize: 10)),
                  if (r.reason.isNotEmpty) ...[const SizedBox(width: 6), Flexible(child: Text(r.reason, style: const TextStyle(color: AppTheme.slate, fontSize: 10), overflow: TextOverflow.ellipsis))],
                ]),
              ])),
              Text('${r.type == "out" ? "-" : "+"}${r.quantity}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ),
        );
      },
    );
  }

  // === Quick Adjust Dialog ===
  void _showQuickAdjustDialog(BuildContext context, CrmProvider crm, InventoryStock stock) {
    final qtyCtrl = TextEditingController(text: '${stock.currentStock}');
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppTheme.navyLight,
        title: Text('调整 ${stock.productName}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('当前库存: ${stock.currentStock}', style: const TextStyle(color: AppTheme.slate, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(controller: qtyCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(labelText: '目标库存')),
          const SizedBox(height: 8),
          TextField(controller: reasonCtrl, style: const TextStyle(color: AppTheme.offWhite),
            decoration: const InputDecoration(labelText: '调整原因', hintText: '盘点/退货/损耗...')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            final newQty = int.tryParse(qtyCtrl.text) ?? stock.currentStock;
            if (newQty != stock.currentStock) {
              crm.addInventoryRecord(InventoryRecord(id: crm.generateId(), productId: stock.productId,
                productName: stock.productName, productCode: stock.productCode, type: 'adjust',
                quantity: newQty, reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : '手动调整',
                notes: '${stock.currentStock} -> $newQty'));
            }
            Navigator.pop(ctx);
          }, child: const Text('确认')),
        ],
      );
    });
  }

  // === Add Record Sheet ===
  void _showAddRecordSheet(BuildContext context, CrmProvider crm) {
    String type = 'in';
    Product? selectedProduct;
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    final products = crm.products;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('新增出入库', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(children: ['in', 'out', 'adjust'].map((t) {
              final sel = type == t;
              return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                label: Text(InventoryRecord.typeLabel(t)),
                selected: sel,
                onSelected: (_) => set(() => type = t),
                selectedColor: AppTheme.gold, backgroundColor: AppTheme.navyMid,
                labelStyle: TextStyle(color: sel ? AppTheme.navy : AppTheme.offWhite, fontSize: 12),
              ));
            }).toList()),
            const SizedBox(height: 12),
            DropdownButtonFormField<Product>(
              initialValue: selectedProduct,
              decoration: const InputDecoration(labelText: '选择产品'),
              dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite),
              items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => set(() => selectedProduct = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.offWhite),
                decoration: const InputDecoration(labelText: '数量'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: reasonCtrl, style: const TextStyle(color: AppTheme.offWhite),
                decoration: const InputDecoration(labelText: '原因'))),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: selectedProduct == null ? null : () {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                crm.addInventoryRecord(InventoryRecord(id: crm.generateId(), productId: selectedProduct!.id,
                  productName: selectedProduct!.name, productCode: selectedProduct!.code, type: type,
                  quantity: qty, reason: reasonCtrl.text));
                Navigator.pop(ctx);
              },
              child: const Text('确认'),
            )),
            const SizedBox(height: 16),
          ]),
        );
      }),
    );
  }

  // === Quick Order Sheet (与销售管线下单完全一致) ===
  void _showQuickOrderSheet(BuildContext context, CrmProvider crm) {
    String? selectedContactId;
    String selectedContactName = '';
    String selectedContactCompany = '';
    String selectedContactPhone = '';
    final contacts = crm.allContacts;
    final products = crm.products;
    final selectedProducts = <String, int>{};
    String priceType = 'retail';
    String selectedStage = 'ordered';
    String shippingMethod = '';
    String paymentTerms = '';
    DateTime? expectedDate;
    final qtyControllers = <String, TextEditingController>{};
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        double total = 0;
        for (final e in selectedProducts.entries) {
          final p = products.firstWhere((p) => p.id == e.key);
          double up;
          switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
          total += up * e.value;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.shopping_cart, color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                const Text('快捷下单', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 6),
              Flexible(child: ListView(shrinkWrap: true, children: [
                // 选择客户
                DropdownButtonFormField<String>(
                  value: selectedContactId,
                  decoration: const InputDecoration(labelText: '选择客户', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  items: contacts.map((c) {
                    final relLabel = c.myRelation.isMedChannel ? ' [${c.myRelation.label}]' : '';
                    return DropdownMenuItem(value: c.id, child: Text('${c.name}$relLabel - ${c.company}', style: const TextStyle(fontSize: 11)));
                  }).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedContactId = v;
                      final contact = contacts.firstWhere((c) => c.id == v);
                      selectedContactName = contact.name;
                      selectedContactCompany = contact.company;
                      selectedContactPhone = contact.phone;
                      if (contact.myRelation == MyRelationType.agent) priceType = 'agent';
                      else if (contact.myRelation == MyRelationType.clinic) priceType = 'clinic';
                      else if (contact.myRelation == MyRelationType.retailer) priceType = 'retail';
                    });
                  },
                ),
                const SizedBox(height: 8),
                // 价格类型
                const Text('价格类型', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: ['agent', 'clinic', 'retail'].map((pt) {
                  final labels = {'agent': '代理', 'clinic': '诊所', 'retail': '零售'};
                  final sel = priceType == pt;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                    label: Text(labels[pt]!, style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => priceType = pt),
                    selectedColor: AppTheme.gold, backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact));
                }).toList()),
                const SizedBox(height: 8),
                // 交易阶段
                const Text('交易阶段', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: DealStage.values.where((s) => s != DealStage.lost).map((s) {
                  final sel = selectedStage == s.name;
                  return ChoiceChip(label: Text(s.label, style: TextStyle(fontSize: 9, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => selectedStage = s.name),
                    selectedColor: _stageColor(s), backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact);
                }).toList()),
                const SizedBox(height: 8),
                // 选择产品
                const Text('选择产品', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                ...products.map((p) {
                  final qty = selectedProducts[p.id] ?? 0;
                  double up;
                  switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
                  final stock = crm.getProductStock(p.id);
                  final reserved = crm.getReservedStock(p.id);
                  final available = stock - reserved;
                  final hasProduction = crm.getProductionByProduct(p.id).where((po) => ProductionStatus.activeStatuses.contains(po.status)).isNotEmpty;
                  final isOverStock = qty > 0 && qty > available;
                  qtyControllers.putIfAbsent(p.id, () => TextEditingController(text: qty > 0 ? '$qty' : ''));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 3), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverStock ? AppTheme.danger.withValues(alpha: 0.08) : (qty > 0 ? AppTheme.gold.withValues(alpha: 0.06) : AppTheme.navyMid),
                      borderRadius: BorderRadius.circular(6),
                      border: isOverStock ? Border.all(color: AppTheme.danger.withValues(alpha: 0.5)) : (qty > 0 ? Border.all(color: AppTheme.gold.withValues(alpha: 0.3)) : null)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          if (isOverStock) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.warning_amber, color: AppTheme.danger, size: 12)),
                          Flexible(child: Text(p.name, style: TextStyle(color: isOverStock ? AppTheme.danger : AppTheme.offWhite, fontSize: 11, fontWeight: FontWeight.w500))),
                        ]),
                        Row(children: [
                          Text(Formatters.currency(up), style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text('可用:$available', style: TextStyle(color: available <= 0 ? AppTheme.danger : (isOverStock ? AppTheme.danger : AppTheme.slate), fontSize: 9, fontWeight: isOverStock ? FontWeight.bold : FontWeight.normal)),
                          if (reserved > 0) ...[const SizedBox(width: 3), Text('(预留$reserved)', style: const TextStyle(color: AppTheme.warning, fontSize: 8))],
                          const SizedBox(width: 6),
                          Text('${p.unitsPerBox}瓶/套', style: const TextStyle(color: AppTheme.slate, fontSize: 8)),
                          if (available <= 0) ...[const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: (hasProduction ? AppTheme.warning : AppTheme.danger).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                              child: Text(hasProduction ? '有排产' : '无排产', style: TextStyle(color: hasProduction ? AppTheme.warning : AppTheme.danger, fontSize: 7, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          if (isOverStock) ...[const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                              child: Text('缺${qty - available}', style: const TextStyle(color: AppTheme.danger, fontSize: 7, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ])),
                      SizedBox(width: 52, height: 30, child: TextField(
                        controller: qtyControllers[p.id], keyboardType: TextInputType.number, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.offWhite, fontSize: 12, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(hintText: '0', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          filled: true, fillColor: AppTheme.navyLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                        onChanged: (v) { final n = int.tryParse(v) ?? 0; set(() { if (n > 0) selectedProducts[p.id] = n; else selectedProducts.remove(p.id); }); },
                      )),
                    ]),
                  );
                }),
                const SizedBox(height: 8),
                // 配送方式
                const Text('配送方式', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: ['express', 'sea', 'air', 'pickup'].map((s) {
                  final sel = shippingMethod == s;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                    label: Text(SalesOrder.shippingLabel(s), style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => shippingMethod = s),
                    selectedColor: AppTheme.info, backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact));
                }).toList()),
                const SizedBox(height: 8),
                // 付款条件
                const Text('付款条件', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: ['prepaid', 'cod', 'net30', 'net60'].map((p) {
                  final sel = paymentTerms == p;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                    label: Text(SalesOrder.paymentLabel(p), style: TextStyle(fontSize: 10, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => paymentTerms = p),
                    selectedColor: AppTheme.warning, backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact));
                }).toList()),
                const SizedBox(height: 8),
                // 预计交付日期
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) set(() => expectedDate = picked);
                  },
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [const Icon(Icons.calendar_today, color: AppTheme.slate, size: 16), const SizedBox(width: 8),
                      Text(expectedDate != null ? '预计交付: ${Formatters.dateShort(expectedDate!)}' : '选择预计交付日期', style: TextStyle(color: expectedDate != null ? AppTheme.offWhite : AppTheme.slate, fontSize: 11))])),
                ),
                const SizedBox(height: 8),
                // 配送地址
                TextField(controller: addressCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  decoration: InputDecoration(labelText: '配送地址', labelStyle: const TextStyle(fontSize: 11), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true, fillColor: AppTheme.navyMid, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none))),
                const SizedBox(height: 6),
                // 备注
                TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  decoration: InputDecoration(labelText: '备注', labelStyle: const TextStyle(fontSize: 11), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true, fillColor: AppTheme.navyMid, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none))),
              ])),
              const SizedBox(height: 6),
              Row(children: [
                const Text('合计: ', style: TextStyle(color: AppTheme.slate, fontSize: 13)),
                Text(Formatters.currency(total), style: const TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              // 库存预警汇总条
              Builder(builder: (_) {
                final warnings = <String>[];
                for (final e in selectedProducts.entries) {
                  final p = products.firstWhere((p) => p.id == e.key);
                  final stock = crm.getProductStock(p.id);
                  final reserved = crm.getReservedStock(p.id);
                  final avail = stock - reserved;
                  if (e.value > avail) {
                    warnings.add('${p.name}: 需${e.value}, 可用$avail');
                  }
                }
                if (warnings.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.warning_amber, color: AppTheme.danger, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('库存不足预警', style: TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                      ...warnings.map((w) => Text(w, style: const TextStyle(color: AppTheme.danger, fontSize: 10))),
                    ])),
                  ]),
                );
              }),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: (selectedContactId == null || selectedProducts.isEmpty) ? null : () async {
                  final items = selectedProducts.entries.map((e) {
                    final p = products.firstWhere((p) => p.id == e.key);
                    double up;
                    switch (priceType) { case 'agent': up = p.agentPrice; break; case 'clinic': up = p.clinicPrice; break; default: up = p.retailPrice; break; }
                    return OrderItem(productId: p.id, productName: p.name, productCode: p.code, quantity: e.value, unitPrice: up, subtotal: up * e.value);
                  }).toList();
                  final dealStage = DealStage.values.firstWhere((s) => s.name == selectedStage, orElse: () => DealStage.ordered);
                  final err = await crm.createOrderWithDeal(SalesOrder(
                    id: crm.generateId(), contactId: selectedContactId!, contactName: selectedContactName,
                    contactCompany: selectedContactCompany, contactPhone: selectedContactPhone,
                    items: items, totalAmount: total, priceType: priceType, dealStage: dealStage.label,
                    shippingMethod: shippingMethod, paymentTerms: paymentTerms,
                    deliveryAddress: addressCtrl.text, notes: notesCtrl.text, expectedDeliveryDate: expectedDate,
                  ));
                  if (err != null) {
                    if (ctx.mounted) _showStockShortageDialog(ctx, crm, err, selectedProducts, products);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('\u8ba2\u5355\u5df2\u521b\u5efa: $selectedContactName | ${Formatters.currency(total)}'),
                      backgroundColor: AppTheme.success));
                  }
                },
                child: const Text('创建订单'),
              )),
              const SizedBox(height: 12),
            ]),
          ),
        );
      }),
    );
  }

  Color _stageColor(DealStage s) {
    switch (s) {
      case DealStage.lead: return AppTheme.slate;
      case DealStage.contacted: return AppTheme.info;
      case DealStage.proposal: return const Color(0xFF9B59B6);
      case DealStage.negotiation: return AppTheme.warning;
      case DealStage.ordered: return const Color(0xFF1ABC9C);
      case DealStage.paid: return AppTheme.success;
      case DealStage.shipped: return AppTheme.info;
      case DealStage.inTransit: return const Color(0xFF8E7CC3);
      case DealStage.received: return const Color(0xFF5DADE2);
      case DealStage.completed: return AppTheme.success;
      case DealStage.lost: return AppTheme.danger;
    }
  }

  /// 库存不足弹窗（与PipelineScreen一致）
  void _showStockShortageDialog(BuildContext context, CrmProvider crm, String errorMsg,
      Map<String, int> selectedProducts, List<Product> products) {
    final details = <Map<String, dynamic>>[];
    for (final e in selectedProducts.entries) {
      final p = products.firstWhere((p) => p.id == e.key);
      final stock = crm.getProductStock(p.id);
      final reserved = crm.getReservedStock(p.id);
      final available = stock - reserved;
      final required = e.value;
      final hasProduction = crm.getProductionByProduct(p.id)
          .where((po) => ProductionStatus.activeStatuses.contains(po.status)).isNotEmpty;
      if (available < required) {
        details.add({'name': p.name, 'required': required, 'available': available, 'shortage': required - available, 'reserved': reserved, 'hasProduction': hasProduction});
      }
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.navyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.danger, size: 20)),
        const SizedBox(width: 10),
        const Expanded(child: Text('库存不足, 无法下单', style: TextStyle(color: AppTheme.danger, fontSize: 16, fontWeight: FontWeight.bold))),
      ]),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
          child: Text(errorMsg, style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('缺货明细:', style: TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...details.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'] as String, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                _shortageMetric('需要', '${d['required']}', AppTheme.offWhite),
                _shortageMetric('可用', '${d['available']}', (d['available'] as int) <= 0 ? AppTheme.danger : AppTheme.warning),
                _shortageMetric('缺口', '-${d['shortage']}', AppTheme.danger),
              ]),
            ]),
          )),
        ],
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('建议:', style: TextStyle(color: AppTheme.info, fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('1. 安排生产排期', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
            Text('2. 手动入库调整', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
            Text('3. 减少下单数量', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
          ])),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('返回修改'))],
    ));
  }

  Widget _shortageMetric(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
    ]));
  }
}
