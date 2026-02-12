import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/factory.dart';
import '../models/product.dart';
import '../models/team.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});
  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _header(context, crm),
        if (_showSearch) _searchBarWidget(),
        _summaryBar(crm),
        _tabBar(),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _ordersTab(crm),
          _factoriesTab(crm),
          _historyTab(crm),
        ])),
      ]));
    });
  }

  Widget _header(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 4, 8),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('生产管理', style: TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Production Management', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
        ])),
        IconButton(
          icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: AppTheme.gold, size: 20),
          onPressed: () => setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); } }),
        ),
        IconButton(
          tooltip: '新建生产单',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.steel.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.add, color: AppTheme.gold, size: 18),
          ),
          onPressed: () => _showNewProductionSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _searchBarWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索产品/工厂/批次号...', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: AppTheme.slate, size: 18),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: AppTheme.slate), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
          filled: true, fillColor: AppTheme.navyLight, contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  List<ProductionOrder> _filterOrders(List<ProductionOrder> orders) {
    if (_searchQuery.isEmpty) return orders;
    final q = _searchQuery.toLowerCase();
    return orders.where((o) =>
      o.productName.toLowerCase().contains(q) ||
      o.factoryName.toLowerCase().contains(q) ||
      o.batchNumber.toLowerCase().contains(q) ||
      o.assigneeName.toLowerCase().contains(q) ||
      o.notes.toLowerCase().contains(q)
    ).toList();
  }

  Widget _summaryBar(CrmProvider crm) {
    final s = crm.productionStats;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: Row(children: [
        _m('${s['activeOrders']}', '进行中', AppTheme.info), _d(),
        _m('${s['totalPlannedQty']}', '计划量', AppTheme.gold), _d(),
        _m('${s['completedOrders']}', '已完成', AppTheme.success), _d(),
        _m('${s['totalCompletedQty']}', '已产出', AppTheme.gold), _d(),
        _m('${s['factoryCount']}', '工厂', AppTheme.slate),
      ]),
    );
  }

  Widget _m(String v, String l, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
  ]));
  Widget _d() => Container(width: 1, height: 28, color: AppTheme.steel.withValues(alpha: 0.2));

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
        tabs: const [Tab(text: '生产订单'), Tab(text: '工厂信息'), Tab(text: '完成历史')],
      ),
    );
  }

  // === Tab 1: Production Orders ===
  Widget _ordersTab(CrmProvider crm) {
    final orders = _filterOrders(crm.activeProductions);
    if (orders.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? '暂无进行中的生产订单' : '未找到"$_searchQuery"', style: const TextStyle(color: AppTheme.slate)));

    final sorted = List<ProductionOrder>.from(orders)..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) => _orderCard(ctx, crm, sorted[i]),
    );
  }

  Widget _orderCard(BuildContext context, CrmProvider crm, ProductionOrder order) {
    final sc = _statusColor(order.status);
    final next = _nextStatus(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(order.productName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(ProductionStatus.label(order.status), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text(order.factoryName, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
          if (order.assigneeName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text('| ${order.assigneeName}', style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
          ],
        ]),
        const SizedBox(height: 8),
        _statusBar(order.status),
        const SizedBox(height: 8),
        Row(children: [
          Text('x${order.quantity}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
          if (order.batchNumber.isNotEmpty) ...[const SizedBox(width: 8), Text(order.batchNumber, style: const TextStyle(color: AppTheme.slate, fontSize: 10))],
          const Spacer(),
          Text(Formatters.dateFull(order.plannedDate), style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
        ]),
        if (order.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
          child: Text(order.notes, style: const TextStyle(color: AppTheme.slate, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 8),
        Row(children: [
          if (next != null) Expanded(child: SizedBox(height: 32, child: ElevatedButton(
            onPressed: () {
              crm.moveProductionStatus(order.id, next);
              if (next == ProductionStatus.completed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${order.productName} x${order.quantity} 已完成, 自动入库!'), backgroundColor: AppTheme.success));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _statusColor(next), foregroundColor: AppTheme.navy, padding: EdgeInsets.zero),
            child: Text(_nextLabel(next), style: const TextStyle(fontSize: 11)),
          ))),
          if (next != null) const SizedBox(width: 8),
          SizedBox(height: 32, width: 32, child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
            onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.navyLight,
              title: const Text('确认删除?', style: TextStyle(color: AppTheme.offWhite, fontSize: 14)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                  onPressed: () { crm.deleteProductionOrder(order.id); Navigator.pop(ctx); }, child: const Text('删除')),
              ],
            )),
          )),
        ]),
      ]),
    );
  }

  Widget _statusBar(String current) {
    final steps = ['planned', 'materials', 'producing', 'quality', 'completed'];
    final idx = steps.indexOf(current);
    return Row(children: List.generate(steps.length, (i) {
      final active = i <= idx;
      final c = active ? _statusColor(steps[i]) : AppTheme.steel.withValues(alpha: 0.3);
      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(height: 2, color: c)),
        Container(width: i == idx ? 10 : 6, height: i == idx ? 10 : 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      ]));
    }));
  }

  // === Tab 2: Factory List ===
  Widget _factoriesTab(CrmProvider crm) {
    var factories = crm.factories;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      factories = factories.where((f) => f.name.toLowerCase().contains(q) || f.representative.toLowerCase().contains(q) || f.address.toLowerCase().contains(q)).toList();
    }
    if (factories.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? '暂无工厂信息' : '未找到"$_searchQuery"', style: const TextStyle(color: AppTheme.slate)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: factories.length,
      itemBuilder: (ctx, i) => _factoryCard(crm, factories[i], i),
    );
  }

  Widget _factoryCard(CrmProvider crm, ProductionFactory factory, int index) {
    final activeOrders = crm.getProductionByFactory(factory.id).where((p) => ProductionStatus.activeStatuses.contains(p.status)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.factory_outlined, color: AppTheme.gold, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(factory.name, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 14))),
          if (activeOrders > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text('$activeOrders 单', style: const TextStyle(color: AppTheme.info, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 4),
        if (factory.representative.isNotEmpty)
          Text('代表: ${factory.representative}', style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
        Text(factory.address, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
        const SizedBox(height: 6),
        if (factory.certifications.isNotEmpty)
          Wrap(spacing: 4, runSpacing: 4, children: factory.certifications.map((c) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(c, style: const TextStyle(color: AppTheme.success, fontSize: 9)),
            )).toList()),
        if (factory.capabilities.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: factory.capabilities.map((cap) {
            final label = cap == 'exosome' ? '外泌体' : cap == 'nad' ? 'NAD+' : cap == 'nmn' ? 'NMN' : cap == 'skincare' ? '美容' : cap;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(label, style: const TextStyle(color: AppTheme.info, fontSize: 9)),
            );
          }).toList()),
        ],
      ]),
    );
  }

  // === Tab 3: Completed History ===
  Widget _historyTab(CrmProvider crm) {
    final completed = crm.productionOrders
      .where((p) => p.status == ProductionStatus.completed || p.status == ProductionStatus.cancelled).toList()
      ..sort((a, b) => (b.completedDate ?? b.updatedAt).compareTo(a.completedDate ?? a.updatedAt));

    if (completed.isEmpty) return const Center(child: Text('暂无完成记录', style: TextStyle(color: AppTheme.slate)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: completed.length,
      itemBuilder: (ctx, i) {
        final o = completed[i];
        final done = o.status == ProductionStatus.completed;
        final c = done ? AppTheme.success : AppTheme.danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            Icon(done ? Icons.check_circle_outline : Icons.cancel_outlined, color: c, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.productName, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w500, fontSize: 12)),
              Text(o.factoryName, style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('x${o.quantity}', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
              if (o.completedDate != null) Text(Formatters.dateShort(o.completedDate!), style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
            ]),
          ]),
        );
      },
    );
  }

  // === New Production Sheet ===
  void _showNewProductionSheet(BuildContext context, CrmProvider crm) {
    ProductionFactory? selFactory;
    Product? selProduct;
    TeamMember? selAssignee;
    final qtyCtrl = TextEditingController(text: '10');
    final batchCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime plannedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('新建生产单', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProductionFactory>(
                initialValue: selFactory,
                decoration: const InputDecoration(labelText: '选择工厂'),
                dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite),
                items: crm.factories.map<DropdownMenuItem<ProductionFactory>>((f) => DropdownMenuItem<ProductionFactory>(value: f, child: Text(f.name, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => set(() => selFactory = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Product>(
                initialValue: selProduct,
                decoration: const InputDecoration(labelText: '选择产品'),
                dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite),
                items: _filteredProducts(crm, selFactory).map((p) => DropdownMenuItem(value: p,
                  child: Text('${p.name} (库存:${crm.getProductStock(p.id)})', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => set(() => selProduct = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TeamMember>(
                initialValue: selAssignee,
                decoration: const InputDecoration(labelText: '负责人 (可选)'),
                dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite),
                items: [
                  const DropdownMenuItem<TeamMember>(value: null, child: Text('不指派', style: TextStyle(fontSize: 13, color: AppTheme.slate))),
                  ...crm.teamMembers.map((m) => DropdownMenuItem<TeamMember>(value: m, child: Text(m.name, style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (v) => set(() => selAssignee = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.offWhite), decoration: const InputDecoration(labelText: '数量'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: batchCtrl, style: const TextStyle(color: AppTheme.offWhite),
                  decoration: const InputDecoration(labelText: '批次号'))),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: plannedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) set(() => plannedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.3))),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: AppTheme.slate, size: 16),
                    const SizedBox(width: 8),
                    Text('计划日期: ${Formatters.dateFull(plannedDate)}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.offWhite), maxLines: 2,
                decoration: const InputDecoration(labelText: '备注')),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: (selFactory == null || selProduct == null) ? null : () {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty <= 0) return;
                  crm.addProductionOrder(ProductionOrder(
                    id: crm.generateId(), factoryId: selFactory!.id, factoryName: selFactory!.name,
                    productId: selProduct!.id, productName: selProduct!.name, productCode: selProduct!.code,
                    quantity: qty, batchNumber: batchCtrl.text, plannedDate: plannedDate, notes: notesCtrl.text,
                    assigneeId: selAssignee?.id ?? '', assigneeName: selAssignee?.name ?? '',
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('创建生产单'),
              )),
              const SizedBox(height: 16),
            ])),
          ),
        );
      }),
    );
  }

  List<Product> _filteredProducts(CrmProvider crm, ProductionFactory? f) {
    if (f == null || f.capabilities.isEmpty) return crm.products;
    return crm.products.where((p) => f.capabilities.contains(p.category)).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'planned': return AppTheme.slate;
      case 'materials': return AppTheme.warning;
      case 'producing': return AppTheme.info;
      case 'quality': return const Color(0xFF9B59B6);
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.danger;
      default: return AppTheme.slate;
    }
  }

  String? _nextStatus(String c) {
    switch (c) { case 'planned': return 'materials'; case 'materials': return 'producing'; case 'producing': return 'quality'; case 'quality': return 'completed'; default: return null; }
  }
  String _nextLabel(String s) {
    switch (s) { case 'materials': return '开始备料'; case 'producing': return '开始生产'; case 'quality': return '送检'; case 'completed': return '完成(自动入库)'; default: return s; }
  }
}
