import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../models/contact.dart';
import '../models/inventory.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

/// 客户类型 → 对应价格体系
class CustomerType {
  static const agent = 'agent';
  static const clinic = 'clinic';
  static const retail = 'retail';

  static String label(String t) {
    switch (t) {
      case agent: return '代理商';
      case clinic: return '诊所';
      case retail: return '零售(个人)';
      default: return t;
    }
  }

  static Color color(String t) {
    switch (t) {
      case agent: return AppTheme.primaryPurple;
      case clinic: return AppTheme.primaryBlue;
      case retail: return AppTheme.accentGold;
      default: return AppTheme.textSecondary;
    }
  }

  /// 根据Contact的relationType自动推断客户类型
  static String fromContact(Contact c) {
    if (c.myRelation == MyRelationType.agent) return agent;
    if (c.myRelation == MyRelationType.client) return clinic;
    return retail;
  }
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final allOrders = crm.orders;
      final filteredOrders = _filterStatus == 'all'
          ? allOrders
          : allOrders.where((o) => o.status == _filterStatus).toList();
      filteredOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return SafeArea(
        child: Column(children: [
          _buildHeader(context, crm),
          _buildSummaryCards(crm),
          _buildStatusFilter(allOrders),
          Expanded(child: filteredOrders.isEmpty ? _buildEmpty() : _buildOrderList(context, crm, filteredOrders)),
        ]),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Icon(Icons.receipt_long, color: AppTheme.accentGold, size: 24),
        const SizedBox(width: 10),
        const Text('销售管理', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: Colors.white, size: 20)),
          onPressed: () => _showNewOrderSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummaryCards(CrmProvider crm) {
    final orders = crm.orders;
    final draft = orders.where((o) => o.status == 'draft').length;
    final confirmed = orders.where((o) => o.status == 'confirmed').length;
    final shipped = orders.where((o) => o.status == 'shipped').length;
    final completed = orders.where((o) => o.status == 'completed').length;
    double totalRevenue = 0;
    double unpaidTotal = 0;
    for (final o in orders) {
      if (o.status == 'completed' || o.status == 'shipped' || o.status == 'confirmed') {
        totalRevenue += o.totalAmount;
        unpaidTotal += o.unpaidAmount;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        Row(children: [
          _miniStat('草稿', '$draft', AppTheme.textSecondary),
          _miniStat('已确认', '$confirmed', AppTheme.primaryBlue),
          _miniStat('已发货', '$shipped', AppTheme.warning),
          _miniStat('已完成', '$completed', AppTheme.success),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('销售总额', style: TextStyle(color: AppTheme.accentGold, fontSize: 10)),
              Text(Formatters.currency(totalRevenue), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
          )),
          const SizedBox(width: 8),
          Expanded(child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('待收款', style: TextStyle(color: AppTheme.danger, fontSize: 10)),
              Text(Formatters.currency(unpaidTotal), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: color, fontSize: 9)),
      ]),
    ));
  }

  Widget _buildStatusFilter(List<SalesOrder> allOrders) {
    const filters = [
      {'key': 'all', 'label': '全部'},
      {'key': 'draft', 'label': '草稿'},
      {'key': 'confirmed', 'label': '已确认'},
      {'key': 'shipped', 'label': '已发货'},
      {'key': 'completed', 'label': '已完成'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: filters.map((f) {
        final active = _filterStatus == f['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            selected: active,
            label: Text(f['label']!, style: TextStyle(color: active ? Colors.white : AppTheme.textSecondary, fontSize: 12)),
            backgroundColor: AppTheme.cardBg,
            selectedColor: AppTheme.primaryPurple,
            onSelected: (_) => setState(() => _filterStatus = f['key']!),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_cart_outlined, color: AppTheme.textSecondary, size: 48),
      SizedBox(height: 12),
      Text('暂无订单', style: TextStyle(color: AppTheme.textSecondary)),
      SizedBox(height: 4),
      Text('点击右上角 + 创建订单', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]));
  }

  Widget _buildOrderList(BuildContext context, CrmProvider crm, List<SalesOrder> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _orderCard(context, crm, orders[index]),
    );
  }

  Widget _orderCard(BuildContext context, CrmProvider crm, SalesOrder order) {
    Color statusColor;
    switch (order.status) {
      case 'confirmed': statusColor = AppTheme.primaryBlue; break;
      case 'shipped': statusColor = AppTheme.warning; break;
      case 'completed': statusColor = AppTheme.success; break;
      case 'cancelled': statusColor = AppTheme.danger; break;
      default: statusColor = AppTheme.textSecondary; break;
    }

    final payColor = order.paymentStatus == 'paid' ? AppTheme.success
        : order.paymentStatus == 'partial' ? AppTheme.warning : AppTheme.danger;

    return GestureDetector(
      onTap: () => _showOrderDetail(context, crm, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 第一行：客户 + 客户类型 + 订单状态
          Row(children: [
            Expanded(child: Row(children: [
              Text(order.contactName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: CustomerType.color(order.priceType).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(CustomerType.label(order.priceType), style: TextStyle(color: CustomerType.color(order.priceType), fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(SalesOrder.statusLabel(order.status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          // 产品列表
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              const Icon(Icons.circle, size: 5, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text('${item.productName} x${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              Text(Formatters.currency(item.subtotal), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            ]),
          )),
          const Divider(color: AppTheme.cardBgLight, height: 12),
          // 底部：日期 + 收款状态 + 合计
          Row(children: [
            Text(Formatters.dateShort(order.createdAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: payColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(PaymentStatus.label(order.paymentStatus), style: TextStyle(color: payColor, fontSize: 9, fontWeight: FontWeight.w600)),
            ),
            if (order.trackingNumber.isNotEmpty) ...[
              const SizedBox(width: 6),
              Icon(Icons.local_shipping, size: 12, color: AppTheme.primaryBlue.withValues(alpha: 0.7)),
            ],
            const Spacer(),
            Text(Formatters.currency(order.totalAmount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ]),
      ),
    );
  }

  // ========== 订单详情 + 编辑 ==========
  void _showOrderDetail(BuildContext context, CrmProvider crm, SalesOrder order) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _OrderDetailSheet(order: order, crm: crm),
    );
  }

  // ========== 新建订单（带库存校验 + 客户类型定价 + 预售） ==========
  void _showNewOrderSheet(BuildContext context, CrmProvider crm) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NewOrderSheet(crm: crm),
    );
  }
}

// ========== 订单详情面板 ==========
class _OrderDetailSheet extends StatefulWidget {
  final SalesOrder order;
  final CrmProvider crm;
  const _OrderDetailSheet({required this.order, required this.crm});
  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late SalesOrder _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _save() {
    _order.updatedAt = DateTime.now();
    widget.crm.updateOrder(_order);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (_order.status) {
      case 'confirmed': statusColor = AppTheme.primaryBlue; break;
      case 'shipped': statusColor = AppTheme.warning; break;
      case 'completed': statusColor = AppTheme.success; break;
      case 'cancelled': statusColor = AppTheme.danger; break;
      default: statusColor = AppTheme.textSecondary; break;
    }
    final payColor = _order.paymentStatus == 'paid' ? AppTheme.success
        : _order.paymentStatus == 'partial' ? AppTheme.warning : AppTheme.danger;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 标题
          Row(children: [
            const Text('订单详情', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(SalesOrder.statusLabel(_order.status), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 12),

          // 客户信息
          _sectionTitle('客户信息'),
          _infoRow('客户', _order.contactName),
          _infoRow('类型', CustomerType.label(_order.priceType)),
          if (_order.contactCompany.isNotEmpty) _infoRow('公司', _order.contactCompany),
          if (_order.contactPhone.isNotEmpty) _infoRow('电话', _order.contactPhone),
          if (_order.deliveryAddress.isNotEmpty) _infoRow('地址', _order.deliveryAddress),

          const SizedBox(height: 12),
          _sectionTitle('产品明细'),
          ..._order.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.productName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${Formatters.currency(item.unitPrice)} x ${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ])),
              Text(Formatters.currency(item.subtotal), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
            ]),
          )),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Text('合计', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(Formatters.currency(_order.totalAmount), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
          ),

          // 收款状态
          const SizedBox(height: 12),
          _sectionTitle('收款状态'),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: payColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(PaymentStatus.label(_order.paymentStatus), style: TextStyle(color: payColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Text('已收: ${Formatters.currency(_order.paidAmount)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const Spacer(),
            Text('待收: ${Formatters.currency(_order.unpaidAmount)}', style: TextStyle(color: _order.unpaidAmount > 0 ? AppTheme.danger : AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          if (_order.paymentNote.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('备注: ${_order.paymentNote}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ),

          // 物流信息
          if (_order.status == 'shipped' || _order.status == 'completed' || _order.trackingNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle('物流信息'),
            if (_order.trackingNumber.isNotEmpty) _infoRow('单号', _order.trackingNumber),
            if (_order.trackingCarrier.isNotEmpty) _infoRow('物流', _order.trackingCarrier),
            _infoRow('状态', SalesOrder.trackingStatusLabel(_order.trackingStatus)),
            if (_order.shippedAt != null) _infoRow('发货', Formatters.dateFull(_order.shippedAt!)),
            if (_order.deliveredAt != null) _infoRow('签收', Formatters.dateFull(_order.deliveredAt!)),
          ],

          // 操作按钮
          const SizedBox(height: 16),
          _sectionTitle('操作'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (_order.status == 'draft') _actionBtn('确认订单', Icons.check, AppTheme.primaryBlue, () {
              _order.status = 'confirmed';
              _save();
              _showSnack('订单已确认');
            }),
            if (_order.status == 'confirmed') _actionBtn('标记发货', Icons.local_shipping, AppTheme.warning, () => _showShipDialog()),
            if (_order.status == 'shipped') _actionBtn('确认签收', Icons.done_all, AppTheme.success, () {
              _order.status = 'completed';
              _order.trackingStatus = 'delivered';
              _order.deliveredAt = DateTime.now();
              _save();
              _showSnack('订单已完成');
            }),
            if (_order.status != 'completed' && _order.status != 'cancelled')
              _actionBtn('登记收款', Icons.payment, AppTheme.accentGold, () => _showPaymentDialog()),
            _actionBtn('编辑备注', Icons.edit_note, AppTheme.textSecondary, () => _showEditNotes()),
            if (_order.status != 'completed' && _order.status != 'cancelled')
              _actionBtn('取消订单', Icons.cancel, AppTheme.danger, () {
                _order.status = 'cancelled';
                _save();
                _showSnack('订单已取消');
              }),
          ]),
          const SizedBox(height: 12),
          _infoRow('创建', Formatters.dateFull(_order.createdAt)),
          _infoRow('更新', Formatters.dateFull(_order.updatedAt)),
          if (_order.notes.isNotEmpty) _infoRow('备注', _order.notes),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color.withValues(alpha: 0.3))),
    );
  }

  // 发货对话框
  void _showShipDialog() {
    final trackNumCtrl = TextEditingController(text: _order.trackingNumber);
    final carrierCtrl = TextEditingController(text: _order.trackingCarrier);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('发货信息', style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: carrierCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: '物流公司', hintText: 'EMS / DHL / 顺丰')),
        const SizedBox(height: 8),
        TextField(controller: trackNumCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: '物流单号')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          _order.status = 'shipped';
          _order.trackingCarrier = carrierCtrl.text.trim();
          _order.trackingNumber = trackNumCtrl.text.trim();
          _order.trackingStatus = 'picked_up';
          _order.shippedAt = DateTime.now();
          _save();
          Navigator.pop(ctx);
          _showSnack('已标记发货');
        }, child: const Text('确认发货')),
      ],
    ));
  }

  // 收款对话框
  void _showPaymentDialog() {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: _order.paymentNote);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('登记收款', style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('订单金额: ${Formatters.currency(_order.totalAmount)}', style: const TextStyle(color: AppTheme.textSecondary)),
        Text('已收款: ${Formatters.currency(_order.paidAmount)}', style: const TextStyle(color: AppTheme.textSecondary)),
        Text('待收款: ${Formatters.currency(_order.unpaidAmount)}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: amtCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(labelText: '本次收款金额', hintText: '${_order.unpaidAmount.toInt()}')),
        const SizedBox(height: 8),
        TextField(controller: noteCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: '收款备注')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          final amt = double.tryParse(amtCtrl.text) ?? 0;
          if (amt <= 0) return;
          _order.paidAmount += amt;
          _order.paidAt = DateTime.now();
          _order.paymentNote = noteCtrl.text.trim();
          if (_order.paidAmount >= _order.totalAmount) {
            _order.paymentStatus = 'paid';
            // 收款完成 + 已签收 = 自动完成订单
            if (_order.trackingStatus == 'delivered') {
              _order.status = 'completed';
            }
          } else {
            _order.paymentStatus = 'partial';
          }
          _save();
          Navigator.pop(ctx);
          _showSnack('已登记收款 ${Formatters.currency(amt)}');
        }, child: const Text('确认收款')),
      ],
    ));
  }

  // 编辑备注
  void _showEditNotes() {
    final notesCtrl = TextEditingController(text: _order.notes);
    final addrCtrl = TextEditingController(text: _order.deliveryAddress);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('编辑订单', style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: addrCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: '送货地址')),
        const SizedBox(height: 8),
        TextField(controller: notesCtrl, maxLines: 3, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: '备注')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          _order.notes = notesCtrl.text.trim();
          _order.deliveryAddress = addrCtrl.text.trim();
          _save();
          Navigator.pop(ctx);
          _showSnack('已更新');
        }, child: const Text('保存')),
      ],
    ));
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.success));
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(title, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 13, fontWeight: FontWeight.bold)),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 60, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
    ]),
  );
}

// ========== 新建订单面板（带库存校验 + 客户类型定价 + 预售） ==========
class _NewOrderSheet extends StatefulWidget {
  final CrmProvider crm;
  const _NewOrderSheet({required this.crm});
  @override
  State<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<_NewOrderSheet> {
  String? _selectedContactId;
  String _selectedContactName = '';
  String _customerType = 'retail';
  final _selectedProducts = <String, int>{}; // productId -> quantity (套数)
  bool _isPreOrder = false;
  DateTime? _expectedDate;
  final _notesCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final contacts = widget.crm.allContacts;
    final products = widget.crm.products;
    final stocks = widget.crm.inventoryStocks;

    // 根据客户类型获取单价（单只价格 * 套数 = 总价，因为unitsPerBox已包含在总价中）
    double getPrice(Product p) {
      switch (_customerType) {
        case 'agent': return p.agentTotalPrice;
        case 'clinic': return p.clinicTotalPrice;
        default: return p.retailTotalPrice;
      }
    }

    double getUnitPrice(Product p) {
      switch (_customerType) {
        case 'agent': return p.agentPrice;
        case 'clinic': return p.clinicPrice;
        default: return p.retailPrice;
      }
    }

    int getStock(String productId) {
      final s = stocks.where((s) => s.productId == productId).toList();
      return s.isEmpty ? 0 : s.first.currentStock;
    }

    // 检查是否有预售可用（生产中的订单有预计到货日期）
    DateTime? getPreOrderDate(String productId) {
      final prods = widget.crm.productionOrders.where((po) =>
        po.productId == productId &&
        po.status != 'completed' && po.status != 'cancelled' &&
        po.plannedDate.isAfter(DateTime.now())
      ).toList();
      if (prods.isEmpty) return null;
      prods.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
      return prods.first.plannedDate;
    }

    double total = 0;
    for (final entry in _selectedProducts.entries) {
      final p = products.firstWhere((p) => p.id == entry.key, orElse: () => products.first);
      total += getPrice(p) * entry.value;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('新建订单', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 8),

          // 选择客户
          DropdownButtonFormField<String>(
            value: _selectedContactId,
            decoration: const InputDecoration(labelText: '选择客户', isDense: true),
            dropdownColor: AppTheme.cardBgLight,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            items: contacts.map((c) => DropdownMenuItem(value: c.id,
              child: Text('${c.name} - ${c.company}', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() {
              _selectedContactId = v;
              final c = contacts.firstWhere((c) => c.id == v);
              _selectedContactName = c.name;
              _customerType = CustomerType.fromContact(c);
              _addrCtrl.text = c.address;
            }),
          ),
          const SizedBox(height: 8),

          // 客户类型（影响定价）
          Row(children: [
            const Text('客户类型: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ...['agent', 'clinic', 'retail'].map((t) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(CustomerType.label(t), style: TextStyle(color: _customerType == t ? Colors.white : AppTheme.textSecondary, fontSize: 11)),
                selected: _customerType == t,
                selectedColor: CustomerType.color(t),
                backgroundColor: AppTheme.cardBgLight,
                onSelected: (_) => setState(() => _customerType = t),
              ),
            )),
          ]),
          const SizedBox(height: 8),

          // 产品列表（带库存校验）
          const Text('选择产品 (按套购买):', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Flexible(
            child: ListView(shrinkWrap: true, children: products.map((p) {
              final qty = _selectedProducts[p.id] ?? 0;
              final stock = getStock(p.id);
              final preDate = getPreOrderDate(p.id);
              final available = stock > 0 || preDate != null;
              final stockUnits = stock ~/ (p.unitsPerBox > 0 ? p.unitsPerBox : 1);

              return Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: qty > 0 ? AppTheme.primaryPurple.withValues(alpha: 0.1) : available ? AppTheme.cardBgLight : AppTheme.cardBgLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: qty > 0 ? Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)) : null,
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: TextStyle(color: available ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 13,
                      fontWeight: qty > 0 ? FontWeight.w600 : FontWeight.normal)),
                    Row(children: [
                      Text('${Formatters.currency(getUnitPrice(p))}/只', style: TextStyle(color: AppTheme.accentGold, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text('${Formatters.currency(getPrice(p))}/套(${p.unitsPerBox}只)', style: TextStyle(color: AppTheme.accentGold.withValues(alpha: 0.7), fontSize: 10)),
                    ]),
                    Row(children: [
                      Icon(Icons.inventory_2, size: 10, color: stock > 0 ? AppTheme.success : AppTheme.danger),
                      const SizedBox(width: 3),
                      Text(stock > 0 ? '库存: $stock只($stockUnits套)' : '无库存',
                        style: TextStyle(color: stock > 0 ? AppTheme.success : AppTheme.danger, fontSize: 10)),
                      if (stock <= 0 && preDate != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.schedule, size: 10, color: AppTheme.warning),
                        const SizedBox(width: 2),
                        Text('预计到货: ${preDate.month}/${preDate.day}', style: const TextStyle(color: AppTheme.warning, fontSize: 10)),
                      ],
                    ]),
                  ])),
                  if (available) ...[
                    IconButton(icon: const Icon(Icons.remove, size: 18, color: AppTheme.textSecondary),
                      onPressed: qty > 0 ? () => setState(() {
                        _selectedProducts[p.id] = qty - 1;
                        if (_selectedProducts[p.id] == 0) _selectedProducts.remove(p.id);
                      }) : null),
                    Text('$qty', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryPurple),
                      onPressed: () {
                        // 如果无库存只能预售
                        if (stock <= 0 && preDate != null) {
                          setState(() {
                            _selectedProducts[p.id] = qty + 1;
                            _isPreOrder = true;
                            _expectedDate = preDate;
                          });
                        } else if (stock > 0) {
                          final maxSets = stock ~/ (p.unitsPerBox > 0 ? p.unitsPerBox : 1);
                          if (qty < maxSets) {
                            setState(() => _selectedProducts[p.id] = qty + 1);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('库存不足! 最多可购$maxSets套'),
                              backgroundColor: AppTheme.danger));
                          }
                        }
                      }),
                  ] else
                    const Text('缺货', style: TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              );
            }).toList()),
          ),

          // 预售标识
          if (_isPreOrder) Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.schedule, size: 16, color: AppTheme.warning),
              const SizedBox(width: 6),
              Expanded(child: Text(
                '预售订单 - 预计交货: ${_expectedDate?.month}/${_expectedDate?.day}',
                style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600),
              )),
            ]),
          ),

          const SizedBox(height: 6),
          // 地址 + 备注
          TextField(controller: _addrCtrl, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(labelText: '送货地址', isDense: true, prefixIcon: Icon(Icons.location_on, size: 16))),
          const SizedBox(height: 6),
          TextField(controller: _notesCtrl, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(labelText: '备注', isDense: true, prefixIcon: Icon(Icons.note, size: 16))),

          // 合计 + 创建
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Text('合计 (${CustomerType.label(_customerType)}价)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(Formatters.currency(total), style: const TextStyle(color: AppTheme.accentGold, fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: Icon(_isPreOrder ? Icons.schedule : Icons.shopping_cart, size: 18),
            label: Text(_isPreOrder ? '创建预售订单' : '创建订单'),
            onPressed: (_selectedContactId == null || _selectedProducts.isEmpty) ? null : () {
              final products = widget.crm.products;
              final items = _selectedProducts.entries.map((e) {
                final p = products.firstWhere((pr) => pr.id == e.key, orElse: () => products.first);
                return OrderItem(
                  productId: p.id, productName: p.name, productCode: p.code,
                  quantity: e.value, unitPrice: getPrice(p), subtotal: getPrice(p) * e.value,
                );
              }).toList();

              final order = SalesOrder(
                id: widget.crm.generateId(),
                contactId: _selectedContactId!,
                contactName: _selectedContactName,
                priceType: _customerType,
                items: items,
                totalAmount: total,
                deliveryAddress: _addrCtrl.text.trim(),
                notes: _isPreOrder ? '[预售] ${_notesCtrl.text.trim()}' : _notesCtrl.text.trim(),
                expectedDeliveryDate: _expectedDate,
                contactCompany: contacts.firstWhere((c) => c.id == _selectedContactId, orElse: () => contacts.first).company,
              );

              // 创建订单 + 自动扣减库存（非预售时）
              widget.crm.addOrder(order);
              if (!_isPreOrder) {
                for (final entry in _selectedProducts.entries) {
                  final p = products.firstWhere((pr) => pr.id == entry.key, orElse: () => products.first);
                  final deductQty = entry.value * (p.unitsPerBox > 0 ? p.unitsPerBox : 1);
                  widget.crm.addInventoryRecord(InventoryRecord(
                    id: widget.crm.generateId(),
                    productId: p.id, productName: p.name,
                    type: 'out', quantity: deductQty,
                    reason: '销售出库',
                    notes: '订单客户: ${order.contactName}',
                  ));
                }
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_isPreOrder ? '预售订单已创建 ${Formatters.currency(total)}' : '订单已创建 ${Formatters.currency(total)}'),
                backgroundColor: AppTheme.success,
              ));
            },
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  List<Contact> get contacts => widget.crm.allContacts;
}
