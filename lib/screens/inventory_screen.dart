import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
          _buildSummaryCards(crm),
          Container(
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
              tabs: const [Tab(text: '库存总览'), Tab(text: '出入库记录')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildStockOverview(crm),
                _buildRecordsList(crm),
              ],
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Icon(Icons.warehouse, color: AppTheme.warning, size: 24),
        const SizedBox(width: 10),
        const Text('库存管理', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          onPressed: () => _showAddRecordSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummaryCards(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    final totalStock = stocks.fold<int>(0, (sum, s) => sum + s.currentStock);
    final lowStockCount = stocks.where((s) => s.currentStock > 0 && s.currentStock < 5).length;
    final outOfStock = stocks.where((s) => s.currentStock <= 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _summaryCard('总库存', '$totalStock', Icons.inventory_2, AppTheme.primaryBlue)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('低库存', '$lowStockCount', Icons.warning_amber, AppTheme.warning)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('缺货', '$outOfStock', Icons.cancel, AppTheme.danger)),
      ]),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ]),
    );
  }

  Widget _buildStockOverview(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    if (stocks.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无库存数据', style: TextStyle(color: AppTheme.textSecondary)),
        SizedBox(height: 4),
        Text('点击右上角 + 添加入库记录', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  '${stock.currentStock}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stock.productName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 3),
              Text(stock.productCode, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }

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
                  if (r.reason.isNotEmpty) Text(r.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
