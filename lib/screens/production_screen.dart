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
              _buildProductionOrders(crm),
              _buildFactoryList(crm),
              _buildCompletedHistory(crm),
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
        const Icon(Icons.precision_manufacturing, color: Color(0xFF00CEC9), size: 24),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('生产管理', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
          tooltip: '新建生产单',
          onPressed: () => _showNewProductionSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummaryRow(CrmProvider crm) {
    final stats = crm.productionStats;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Expanded(child: _summaryChip('${stats['activeOrders']}', '进行中', const Color(0xFF00CEC9))),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('${stats['totalPlannedQty']}', '计划产量', AppTheme.primaryBlue)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('${stats['completedOrders']}', '已完成', AppTheme.success)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('${stats['totalCompletedQty']}', '已产出', AppTheme.accentGold)),
        const SizedBox(width: 6),
        Expanded(child: _summaryChip('${stats['factoryCount']}', '工厂', AppTheme.primaryPurple)),
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
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '生产订单'),
          Tab(text: '工厂信息'),
          Tab(text: '完成历史'),
        ],
      ),
    );
  }

  // ========== Tab 1: Active Production Orders ==========
  Widget _buildProductionOrders(CrmProvider crm) {
    final orders = crm.activeProductions;
    if (orders.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.precision_manufacturing_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无进行中的生产订单', style: TextStyle(color: AppTheme.textSecondary)),
        SizedBox(height: 4),
        Text('点击右上角 + 创建生产单', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]));
    }

    // Sort by planned date
    final sorted = List<ProductionOrder>.from(orders)
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _productionCard(context, crm, sorted[index]),
    );
  }

  Widget _productionCard(BuildContext context, CrmProvider crm, ProductionOrder order) {
    final statusColor = _statusColor(order.status);
    final statusLabel = ProductionStatus.label(order.status);
    final nextStatus = _nextStatus(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.precision_manufacturing, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.productName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Row(children: [
              Text(order.factoryName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              if (order.assigneeName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person, color: AppTheme.primaryPurple, size: 10),
                    const SizedBox(width: 3),
                    Text(order.assigneeName, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        _buildStatusProgress(order.status),
        const SizedBox(height: 10),
        Row(children: [
          _infoTag(Icons.numbers, '数量: ${order.quantity}', AppTheme.primaryBlue),
          const SizedBox(width: 8),
          if (order.batchNumber.isNotEmpty)
            _infoTag(Icons.qr_code, order.batchNumber, AppTheme.primaryPurple),
          const Spacer(),
          Text('计划: ${Formatters.dateFull(order.plannedDate)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
        if (order.notes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(order.notes, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (nextStatus != null) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  crm.moveProductionStatus(order.id, nextStatus);
                  if (nextStatus == ProductionStatus.completed && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${order.productName} x${order.quantity} 已完成, 自动入库!'),
                      backgroundColor: AppTheme.success,
                    ));
                  }
                },
                icon: Icon(nextStatus == ProductionStatus.completed ? Icons.check_circle : Icons.arrow_forward, size: 16),
                label: Text(_nextStatusLabel(nextStatus), style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _statusColor(nextStatus),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardBg,
                  title: const Text('确认删除?', style: TextStyle(color: AppTheme.textPrimary)),
                  content: Text('删除 ${order.productName} 的生产订单?', style: const TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                      onPressed: () { crm.deleteProductionOrder(order.id); Navigator.pop(ctx); },
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
            },
          ),
        ]),
      ]),
    );
  }

  Widget _buildStatusProgress(String currentStatus) {
    final statuses = [ProductionStatus.planned, ProductionStatus.materials, ProductionStatus.producing, ProductionStatus.quality, ProductionStatus.completed];
    final currentIdx = statuses.indexOf(currentStatus);

    return Row(children: List.generate(statuses.length, (i) {
      final isActive = i <= currentIdx;
      final isCurrent = i == currentIdx;
      final color = isActive ? _statusColor(statuses[i]) : AppTheme.cardBgLight;

      return Expanded(child: Row(children: [
        if (i > 0) Expanded(
          child: Container(height: 2, color: isActive ? color : AppTheme.cardBgLight),
        ),
        Container(
          width: isCurrent ? 12 : 8,
          height: isCurrent ? 12 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)] : null,
          ),
        ),
      ]));
    }));
  }

  Widget _infoTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ========== Tab 2: Factory List ==========
  Widget _buildFactoryList(CrmProvider crm) {
    final factories = crm.factories;
    if (factories.isEmpty) {
      return const Center(child: Text('暂无工厂信息', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: factories.length,
      itemBuilder: (context, index) => _factoryCard(crm, factories[index]),
    );
  }

  Widget _factoryCard(CrmProvider crm, ProductionFactory factory) {
    final activeOrders = crm.getProductionByFactory(factory.id).where(
      (p) => ProductionStatus.activeStatuses.contains(p.status)
    ).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.factory, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(factory.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            if (factory.representative.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('代表: ${factory.representative}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ])),
          if (activeOrders > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00CEC9).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('$activeOrders 单', style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.location_on, color: AppTheme.textSecondary, size: 14),
          const SizedBox(width: 4),
          Expanded(child: Text(factory.address, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Text(factory.description, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        // Certifications
        if (factory.certifications.isNotEmpty) ...[
          Wrap(spacing: 6, runSpacing: 4, children: factory.certifications.map((cert) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(cert, style: const TextStyle(color: AppTheme.success, fontSize: 9, fontWeight: FontWeight.w600)),
            ),
          ).toList()),
          const SizedBox(height: 8),
        ],
        // Capabilities
        if (factory.capabilities.isNotEmpty)
          Wrap(spacing: 6, runSpacing: 4, children: factory.capabilities.map((cap) {
            Color c;
            String label;
            switch (cap) {
              case 'exosome': c = const Color(0xFF00B894); label = '外泌体'; break;
              case 'nad': c = const Color(0xFFE17055); label = 'NAD+'; break;
              case 'nmn': c = const Color(0xFF0984E3); label = 'NMN'; break;
              case 'skincare': c = AppTheme.primaryPurple; label = '美容'; break;
              default: c = AppTheme.textSecondary; label = cap; break;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600)),
            );
          }).toList()),
      ]),
    );
  }

  // ========== Tab 3: Completed History ==========
  Widget _buildCompletedHistory(CrmProvider crm) {
    final completed = crm.productionOrders.where(
      (p) => p.status == ProductionStatus.completed || p.status == ProductionStatus.cancelled
    ).toList()
      ..sort((a, b) => (b.completedDate ?? b.updatedAt).compareTo(a.completedDate ?? a.updatedAt));

    if (completed.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无完成记录', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final order = completed[index];
        final isCompleted = order.status == ProductionStatus.completed;
        final color = isCompleted ? AppTheme.success : AppTheme.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(isCompleted ? Icons.check_circle : Icons.cancel, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.productName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Row(children: [
                Text(order.factoryName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                if (order.inventoryLinked) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('已入库', style: TextStyle(color: AppTheme.success, fontSize: 9)),
                  ),
                ],
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('x${order.quantity}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              if (order.completedDate != null)
                Text(Formatters.dateShort(order.completedDate!), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ]),
          ]),
        );
      },
    );
  }

  // ========== New Production Order Sheet ==========
  void _showNewProductionSheet(BuildContext context, CrmProvider crm) {
    ProductionFactory? selectedFactory;
    Product? selectedProduct;
    TeamMember? selectedAssignee;
    final qtyCtrl = TextEditingController(text: '10');
    final batchCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime plannedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.precision_manufacturing, color: Color(0xFF00CEC9), size: 22),
                    const SizedBox(width: 8),
                    const Text('新建生产单', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ]),
                  const SizedBox(height: 12),
                  // Select Factory
                  DropdownButtonFormField<ProductionFactory>(
                    initialValue: selectedFactory,
                    decoration: const InputDecoration(labelText: '选择工厂', prefixIcon: Icon(Icons.factory, color: AppTheme.textSecondary, size: 20)),
                    dropdownColor: AppTheme.cardBgLight,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: crm.factories.map<DropdownMenuItem<ProductionFactory>>((f) => DropdownMenuItem<ProductionFactory>(value: f, child: Text(f.name, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setModalState(() => selectedFactory = v),
                  ),
                  const SizedBox(height: 12),
                  // Select Product (filter by factory capability)
                  DropdownButtonFormField<Product>(
                    initialValue: selectedProduct,
                    decoration: const InputDecoration(labelText: '选择产品', prefixIcon: Icon(Icons.science, color: AppTheme.textSecondary, size: 20)),
                    dropdownColor: AppTheme.cardBgLight,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: _getFilteredProducts(crm, selectedFactory).map((p) => DropdownMenuItem(
                      value: p,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(p.name, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Text('库存:${crm.getProductStock(p.id)}', style: TextStyle(color: crm.getProductStock(p.id) <= 0 ? AppTheme.danger : AppTheme.textSecondary, fontSize: 10)),
                      ]),
                    )).toList(),
                    onChanged: (v) => setModalState(() => selectedProduct = v),
                  ),
                  const SizedBox(height: 12),
                  // Select Assignee
                  DropdownButtonFormField<TeamMember>(
                    initialValue: selectedAssignee,
                    decoration: const InputDecoration(labelText: '负责人 (可选)', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 20)),
                    dropdownColor: AppTheme.cardBgLight,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: [
                      const DropdownMenuItem<TeamMember>(value: null, child: Text('不指派', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                      ...crm.teamMembers.map((m) => DropdownMenuItem<TeamMember>(
                        value: m,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          CircleAvatar(radius: 10, backgroundColor: _roleColor(m.role), child: Text(m.name.isNotEmpty ? m.name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 10))),
                          const SizedBox(width: 8),
                          Text(m.name, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(TeamMember.roleLabel(m.role), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        ]),
                      )),
                    ],
                    onChanged: (v) => setModalState(() => selectedAssignee = v),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: '生产数量', prefixIcon: Icon(Icons.numbers, color: AppTheme.textSecondary, size: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: batchCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: '批次号 (可选)', prefixIcon: Icon(Icons.qr_code, color: AppTheme.textSecondary, size: 20)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Planned Date
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: plannedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setModalState(() => plannedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text('计划日期: ${Formatters.dateFull(plannedDate)}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '备注'),
                  ),
                  const SizedBox(height: 16),
                  // Linkage info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CEC9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.link, color: Color(0xFF00CEC9), size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        '生产完成后将自动入库, 销售下单时自动出库扣减',
                        style: TextStyle(color: Color(0xFF00CEC9), fontSize: 11),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.precision_manufacturing, size: 18),
                    label: const Text('创建生产单'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CEC9),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (selectedFactory == null || selectedProduct == null) ? null : () {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) return;

                      final order = ProductionOrder(
                        id: crm.generateId(),
                        factoryId: selectedFactory!.id,
                        factoryName: selectedFactory!.name,
                        productId: selectedProduct!.id,
                        productName: selectedProduct!.name,
                        productCode: selectedProduct!.code,
                        quantity: qty,
                        batchNumber: batchCtrl.text,
                        plannedDate: plannedDate,
                        notes: notesCtrl.text,
                        assigneeId: selectedAssignee?.id ?? '',
                        assigneeName: selectedAssignee?.name ?? '',
                      );
                      crm.addProductionOrder(order);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('生产单已创建: ${selectedProduct!.name} x$qty @ ${selectedFactory!.name}'),
                        backgroundColor: const Color(0xFF00CEC9),
                      ));
                    },
                  )),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  /// Filter products based on factory capabilities
  List<Product> _getFilteredProducts(CrmProvider crm, ProductionFactory? factory) {
    if (factory == null || factory.capabilities.isEmpty) return crm.products;
    return crm.products.where((p) => factory.capabilities.contains(p.category)).toList();
  }

  // ========== Helpers ==========
  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return const Color(0xFFE17055);
      case 'manager': return AppTheme.accentGold;
      case 'member': return AppTheme.primaryBlue;
      default: return AppTheme.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'planned': return AppTheme.textSecondary;
      case 'materials': return AppTheme.warning;
      case 'producing': return const Color(0xFF00CEC9);
      case 'quality': return AppTheme.primaryPurple;
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'planned': return 'materials';
      case 'materials': return 'producing';
      case 'producing': return 'quality';
      case 'quality': return 'completed';
      default: return null;
    }
  }

  String _nextStatusLabel(String status) {
    switch (status) {
      case 'materials': return '开始备料';
      case 'producing': return '开始生产';
      case 'quality': return '送检';
      case 'completed': return '完成 (自动入库)';
      default: return status;
    }
  }
}
