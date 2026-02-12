import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../models/inventory.dart';
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

  static const _productImages = {
    'exosome': 'https://sspark.genspark.ai/cfimages?u1=gQJ0%2FI61F8aniwhXmW3RCOtb2ddp%2BIkvgbC7uSVsjje5TY6kHHdQPw%2BFX0pCr5TsSpLSsbDs4eWYMJDVR%2FFZAjSEVv7H2zT35KTXrux0iEY5eavPlEp5xTtvMR0zx5sQIvyRD6SSeJwJP6BNzxz7kIebeN1oPBmfpBnWtYaphXqzk2qYywDvrib4XqOrSyCsmijp5I4%3D&u2=vdsQVGBgw%2FpPeDo2&width=2560',
    'nad': 'https://sspark.genspark.ai/cfimages?u1=sRtjvw4%2BttLmk7K%2FoqtAySxDHIfxfQxdrWD8dNNTPqpf7SfyCC70nmBNWp2kitq5LVhYo72q0eLJKLZc6SGQcCEn0xAr%2Bt%2F6GBJL&u2=CUZ%2FXXvVVY4pRp%2FA&width=2560',
    'nmn': 'https://sspark.genspark.ai/cfimages?u1=umpIeewrXO51nUeXp9Sk6w%2BIHeHot3yc8B6pSBifIaLZ2ZvtXbmTVq0zU2pJNFDy5kBDFJCGoACEsZE0Us67CjdBUw%3D%3D&u2=41xNTu8VL%2Bvli1tf&width=2560',
  };

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
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
        tabs: const [Tab(text: '产品目录'), Tab(text: '库存总览'), Tab(text: '出入库记录')],
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
    final imageUrl = _productImages[product.category];

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
        child: Row(children: [
          // Product thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl != null
              ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackThumb(product.category))
              : _fallbackThumb(product.category),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(product.specification, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
            const SizedBox(height: 4),
            Row(children: [
              _tag(ProductCategory.label(product.category), AppTheme.info),
              const SizedBox(width: 6),
              _tag('库存:$stock', _stockColor(stock)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currency(product.retailPrice), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            const Text('零售/瓶', style: TextStyle(color: AppTheme.slate, fontSize: 9)),
          ]),
        ]),
      ),
    );
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
        final label = s.currentStock <= 0 ? '缺货' : s.currentStock < 5 ? '低库存' : '正常';
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('${s.currentStock}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.productName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(s.productCode, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
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
        );
      },
    );
  }

  // === Tab 3: Records ===
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
}
