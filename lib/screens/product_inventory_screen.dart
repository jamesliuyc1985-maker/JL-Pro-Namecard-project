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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(
        child: Column(children: [
          _buildHeader(context, crm),
          _buildSummaryRow(crm),
          _buildTabBar(),
          const SizedBox(height: 6),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildProductCatalog(crm),
              _buildStockOverview(crm),
              _buildRecordsList(crm),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(children: [
        const Icon(Icons.science_rounded, color: AppTheme.primaryPurple, size: 24),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('产品 & 库存', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_box, color: AppTheme.success, size: 18),
          ),
          tooltip: '入库/出库',
          onPressed: () => _showAddRecordSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummaryRow(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    final totalStock = stocks.fold<int>(0, (sum, s) => sum + s.currentStock);
    final lowStock = stocks.where((s) => s.currentStock > 0 && s.currentStock < 5).length;
    final outOfStock = stocks.where((s) => s.currentStock <= 0).length;
    final productCount = crm.products.length;
    // Production linkage: active productions
    final activeProd = crm.activeProductions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Expanded(child: _summaryChip('$productCount', '产品', AppTheme.primaryPurple)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('$totalStock', '总库存', AppTheme.primaryBlue)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('$lowStock', '低库存', AppTheme.warning)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('$outOfStock', '缺货', AppTheme.danger)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('$activeProd', '生产中', const Color(0xFF00CEC9))),
      ]),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          gradient: AppTheme.gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '产品目录'),
          Tab(text: '库存总览'),
          Tab(text: '出入库记录'),
        ],
      ),
    );
  }

  // ========== Tab 1: Product Catalog ==========
  Widget _buildProductCatalog(CrmProvider crm) {
    final allProducts = crm.products;
    final products = _selectedCategory == 'all'
        ? allProducts
        : allProducts.where((p) => p.category == _selectedCategory).toList();

    return Column(children: [
      _buildCategoryFilter(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Row(children: [
          Text('${products.length} 款产品', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const Spacer(),
          const Text('能道再生株式会社', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
      Expanded(child: _buildProductList(products, crm)),
    ]);
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'key': 'all', 'label': '全部', 'icon': Icons.apps, 'color': AppTheme.primaryPurple},
      {'key': 'exosome', 'label': '外泌体', 'icon': Icons.bubble_chart, 'color': const Color(0xFF00B894)},
      {'key': 'nad', 'label': 'NAD+', 'icon': Icons.flash_on, 'color': const Color(0xFFE17055)},
      {'key': 'nmn', 'label': 'NMN', 'icon': Icons.medication, 'color': const Color(0xFF0984E3)},
    ];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['key'];
          final color = cat['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat['icon'] as IconData, size: 13, color: isSelected ? Colors.white : color),
                const SizedBox(width: 4),
                Text(cat['label'] as String),
              ]),
              onSelected: (_) => setState(() => _selectedCategory = cat['key'] as String),
              selectedColor: color,
              backgroundColor: AppTheme.cardBgLight,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, CrmProvider crm) {
    if (products.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无产品', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) => _productCard(context, products[index], crm),
    );
  }

  Widget _productCard(BuildContext context, Product product, CrmProvider crm) {
    Color catColor;
    IconData catIcon;
    switch (product.category) {
      case 'exosome': catColor = const Color(0xFF00B894); catIcon = Icons.bubble_chart; break;
      case 'nad': catColor = const Color(0xFFE17055); catIcon = Icons.flash_on; break;
      case 'nmn': catColor = const Color(0xFF0984E3); catIcon = Icons.medication; break;
      default: catColor = AppTheme.primaryPurple; catIcon = Icons.science; break;
    }

    final stock = crm.getProductStock(product.id);
    final activeProd = crm.getProductionByProduct(product.id).where(
      (p) => p.status != 'completed' && p.status != 'cancelled'
    ).length;

    Color stockColor = stock <= 0 ? AppTheme.danger : stock < 5 ? AppTheme.warning : AppTheme.success;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: catColor.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(catIcon, color: catColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(product.specification, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(ProductCategory.label(product.category), style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('库存:$stock', style: TextStyle(color: stockColor, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
              if (activeProd > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF00CEC9).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('生产中:$activeProd', style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currency(product.retailPrice), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text('零售/瓶', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 9)),
          ]),
        ]),
      ),
    );
  }

  // ========== Tab 2: Stock Overview ==========
  Widget _buildStockOverview(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    if (stocks.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无库存数据', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        Color statusColor;
        String statusText;
        if (stock.currentStock <= 0) {
          statusColor = AppTheme.danger;
          statusText = '缺货';
        } else if (stock.currentStock < 5) {
          statusColor = AppTheme.warning;
          statusText = '低库存';
        } else {
          statusColor = AppTheme.success;
          statusText = '正常';
        }

        // Check active production
        final activeProd = crm.getProductionByProduct(stock.productId).where(
          (p) => p.status != 'completed' && p.status != 'cancelled'
        ).toList();
        int incomingQty = 0;
        for (final p in activeProd) { incomingQty += p.quantity; }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text('${stock.currentStock}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stock.productName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(stock.productCode, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              GestureDetector(
                onTap: () => _showQuickAdjustDialog(context, crm, stock),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tune, color: AppTheme.primaryPurple, size: 14),
                    SizedBox(width: 4),
                    Text('调整', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            // Show incoming production
            if (incomingQty > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CEC9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.precision_manufacturing, color: Color(0xFF00CEC9), size: 14),
                    const SizedBox(width: 6),
                    Text('生产中: ${activeProd.length} 单, 预计入库 $incomingQty 件',
                      style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 11)),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }

  // ========== Tab 3: Records ==========
  Widget _buildRecordsList(CrmProvider crm) {
    final records = crm.inventoryRecords;
    if (records.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无出入库记录', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }

    final sorted = List<InventoryRecord>.from(records)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final r = sorted[index];
        Color typeColor;
        IconData typeIcon;
        switch (r.type) {
          case 'in': typeColor = AppTheme.success; typeIcon = Icons.arrow_downward; break;
          case 'out': typeColor = AppTheme.danger; typeIcon = Icons.arrow_upward; break;
          default: typeColor = AppTheme.warning; typeIcon = Icons.tune; break;
        }

        return Dismissible(
          key: Key(r.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.delete, color: AppTheme.danger),
          ),
          onDismissed: (_) => crm.deleteInventoryRecord(r.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.productName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(InventoryRecord.typeLabel(r.type), style: TextStyle(color: typeColor, fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  if (r.reason.isNotEmpty) Flexible(child: Text(r.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${r.type == "out" ? "-" : "+"}${r.quantity}', style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(Formatters.dateShort(r.createdAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  // ========== Quick Adjust Dialog ==========
  void _showQuickAdjustDialog(BuildContext context, CrmProvider crm, InventoryStock stock) {
    final qtyCtrl = TextEditingController(text: '${stock.currentStock}');
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Row(children: [
            const Icon(Icons.tune, color: AppTheme.primaryPurple, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text('调整 ${stock.productName}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('当前库存: ${stock.currentStock}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: '目标库存数量',
                filled: true, fillColor: AppTheme.cardBgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: '调整原因', hintText: '盘点/退货/损耗...'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                final newQty = int.tryParse(qtyCtrl.text) ?? stock.currentStock;
                if (newQty != stock.currentStock) {
                  crm.addInventoryRecord(InventoryRecord(
                    id: crm.generateId(),
                    productId: stock.productId,
                    productName: stock.productName,
                    productCode: stock.productCode,
                    type: 'adjust',
                    quantity: newQty,
                    reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : '手动调整',
                    notes: '${stock.currentStock} -> $newQty',
                  ));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${stock.productName} 库存: ${stock.currentStock} -> $newQty'),
                      backgroundColor: AppTheme.success,
                    ));
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('确认调整'),
            ),
          ],
        );
      },
    );
  }

  // ========== Add Record Sheet ==========
  void _showAddRecordSheet(BuildContext context, CrmProvider crm) {
    String type = 'in';
    Product? selectedProduct;
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final products = crm.products;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('新增出入库', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                const Text('类型: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ...['in', 'out', 'adjust'].map((t) {
                  Color c;
                  switch (t) {
                    case 'in': c = AppTheme.success; break;
                    case 'out': c = AppTheme.danger; break;
                    default: c = AppTheme.warning; break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(InventoryRecord.typeLabel(t)),
                      selected: type == t,
                      onSelected: (_) => setModalState(() => type = t),
                      selectedColor: c,
                      backgroundColor: AppTheme.cardBgLight,
                      labelStyle: TextStyle(color: type == t ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<Product>(
                initialValue: selectedProduct,
                decoration: const InputDecoration(labelText: '选择产品'),
                dropdownColor: AppTheme.cardBgLight,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() => selectedProduct = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '数量', prefixIcon: Icon(Icons.numbers, color: AppTheme.textSecondary, size: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: reasonCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: '原因', prefixIcon: Icon(Icons.note, color: AppTheme.textSecondary, size: 20)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '备注'),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: selectedProduct == null ? null : () {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty <= 0) return;
                  crm.addInventoryRecord(InventoryRecord(
                    id: crm.generateId(),
                    productId: selectedProduct!.id,
                    productName: selectedProduct!.name,
                    productCode: selectedProduct!.code,
                    type: type,
                    quantity: qty,
                    reason: reasonCtrl.text,
                    notes: notesCtrl.text,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${InventoryRecord.typeLabel(type)}: ${selectedProduct!.name} x$qty'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                child: const Text('确认'),
              )),
              const SizedBox(height: 16),
            ]),
          );
        });
      },
    );
  }
}
