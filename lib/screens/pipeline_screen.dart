import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/crm_provider.dart';
import '../models/deal.dart';
import '../models/contact.dart';
import '../models/product.dart';
import '../models/factory.dart';
import '../models/team.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

import 'home_screen.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});
  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); _searchCtrl.dispose(); super.dispose(); }

  List<Deal> _filtered(List<Deal> deals) {
    if (_searchQuery.isEmpty) return deals;
    final q = _searchQuery.toLowerCase();
    return deals.where((d) =>
      d.title.toLowerCase().contains(q) ||
      d.contactName.toLowerCase().contains(q) ||
      d.description.toLowerCase().contains(q) ||
      d.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      return SafeArea(child: Column(children: [
        _header(context, crm),
        if (_showSearch) _searchBar(),
        _summary(crm),
        _tabs(),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _allPipelineTab(crm),
          _stageTab(crm),
          _top20Tab(crm),
          _staffSalesTab(crm),
        ])),
      ]));
    });
  }

  Widget _header(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('销售管线', style: TextStyle(color: AppTheme.offWhite, fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Sales Pipeline & Finance', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
        ])),
        // 按钮紧凑排列，避免重叠
        SizedBox(
          width: 32, height: 32,
          child: IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: AppTheme.gold, size: 20),
            onPressed: () => setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); } }),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 32, height: 32,
          child: HomeScreen.buildNotificationBell(context),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showNewOrderSheet(context, crm),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add_shopping_cart, color: AppTheme.gold, size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
        decoration: InputDecoration(
          hintText: '搜索交易/客户/标签...', hintStyle: const TextStyle(color: AppTheme.slate, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: AppTheme.slate, size: 18),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16, color: AppTheme.slate), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
          filled: true, fillColor: AppTheme.navyLight, contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _summary(CrmProvider crm) {
    final active = crm.deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost);
    double pipeline = 0, weighted = 0;
    for (final d in active) { pipeline += d.amount; weighted += d.amount * d.probability / 100; }
    final completedDeals = crm.deals.where((d) => d.stage == DealStage.completed);
    double closedVal = 0;
    for (final d in completedDeals) { closedVal += d.amount; }
    // 已收款（基于收款状态）
    double collected = 0;
    for (final o in crm.orders) { collected += o.paidAmount; }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
      child: Row(children: [
        _kpi('管线总额', Formatters.currency(pipeline), AppTheme.gold),
        _vd(),
        _kpi('加权期望', Formatters.currency(weighted), AppTheme.info),
        _vd(),
        _kpi('已成交', Formatters.currency(closedVal), AppTheme.success),
        _vd(),
        _kpi('已收款', Formatters.currency(collected), const Color(0xFF1ABC9C)),
      ]),
    );
  }

  Widget _kpi(String label, String val, Color c) => Expanded(child: Column(children: [
    Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
  ]));
  Widget _vd() => Container(width: 1, height: 28, color: AppTheme.steel.withValues(alpha: 0.2));

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppTheme.gold, indicatorWeight: 2,
      labelColor: AppTheme.gold, unselectedLabelColor: AppTheme.slate,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      isScrollable: true, tabAlignment: TabAlignment.start,
      dividerColor: AppTheme.steel.withValues(alpha: 0.2),
      tabs: const [Tab(text: '全管线'), Tab(text: '按阶段'), Tab(text: 'TOP 20'), Tab(text: '员工业绩')],
    );
  }

  // ====== TAB 1: 全管线视图 ======
  Widget _allPipelineTab(CrmProvider crm) {
    final allDeals = List<Deal>.from(crm.deals)..sort((a, b) => b.amount.compareTo(a.amount));
    final deals = _filtered(allDeals);
    if (deals.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? '暂无交易' : '未找到"$_searchQuery"', style: const TextStyle(color: AppTheme.slate)));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: deals.length,
      itemBuilder: (ctx, i) => _dealCard(ctx, crm, deals[i]));
  }

  // ====== TAB 2: 按阶段 ======
  Widget _stageTab(CrmProvider crm) {
    final stages = DealStage.values;
    return ListView(padding: const EdgeInsets.all(12), children: stages.map((stage) {
      final deals = _filtered(crm.getDealsByStage(stage));
      if (deals.isEmpty) return const SizedBox.shrink();
      double stageTotal = 0;
      for (final d in deals) { stageTotal += d.amount; }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => _drillStageDeals(stage, deals),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: _color(stage).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: _color(stage), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(stage.label, style: TextStyle(color: _color(stage), fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _color(stage).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('${deals.length}', style: TextStyle(color: _color(stage), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(Formatters.currency(stageTotal), style: TextStyle(color: _color(stage), fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: _color(stage), size: 16),
            ]),
          ),
        ),
        ...deals.take(3).map((d) => _miniDealCard(crm, d)),
        if (deals.length > 3) Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8),
          child: GestureDetector(
            onTap: () => _drillStageDeals(stage, deals),
            child: Text('查看全部 ${deals.length} 笔 →', style: const TextStyle(color: AppTheme.gold, fontSize: 11)),
          ),
        ),
        const SizedBox(height: 8),
      ]);
    }).toList());
  }

  // ====== TAB 3: TOP 20 ======
  Widget _top20Tab(CrmProvider crm) {
    final sorted = List<Deal>.from(crm.deals.where((d) => d.stage != DealStage.lost))
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top20 = _filtered(sorted).take(20).toList();
    if (top20.isEmpty) return const Center(child: Text('暂无交易数据', style: TextStyle(color: AppTheme.slate)));
    double maxAmount = top20.isNotEmpty ? top20.first.amount : 1;
    if (maxAmount == 0) maxAmount = 1;

    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.emoji_events, color: AppTheme.gold, size: 20),
          const SizedBox(width: 8),
          Text('交易排行 TOP ${top20.length}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          Text('总计 ${Formatters.currency(top20.fold(0.0, (sum, d) => sum + d.amount))}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 12)),
        ]),
      ),
      ...top20.asMap().entries.map((e) {
        final i = e.key; final d = e.value; final c = _color(d.stage);
        final ratio = d.amount / maxAmount;
        final rankColor = i == 0 ? const Color(0xFFFFD700) : i == 1 ? const Color(0xFFC0C0C0) : i == 2 ? const Color(0xFFCD7F32) : AppTheme.slate;
        return Container(
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
            border: i < 3 ? Border.all(color: rankColor.withValues(alpha: 0.4)) : null),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${i + 1}', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 13)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (d.isStarred) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: AppTheme.gold, size: 14)),
                  Expanded(child: Text(d.title, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
                Text('${d.contactName} | ${d.stage.label}', style: TextStyle(color: c, fontSize: 10)),
              ])),
              Text(Formatters.currency(d.amount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: ratio.clamp(0.02, 1.0), backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(c), minHeight: 3)),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // === 收款对话框 ===
  void _showPaymentDialog(CrmProvider crm, SalesOrder o) {
    final amtCtrl = TextEditingController(text: o.unpaidAmount.toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: o.paymentNote);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.attach_money, color: AppTheme.success),
            const SizedBox(width: 8),
            const Text('确认收款', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('订单总额: ${Formatters.currency(o.totalAmount)}', style: const TextStyle(color: AppTheme.slate, fontSize: 12)),
            const SizedBox(width: 12),
            Text('已收: ${Formatters.currency(o.paidAmount)}', style: const TextStyle(color: AppTheme.success, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(labelText: '本次收款金额 (JPY)', prefixIcon: Icon(Icons.currency_yen, size: 18)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => amtCtrl.text = o.unpaidAmount.toStringAsFixed(0),
              child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Center(child: Text('全额收款', style: TextStyle(color: AppTheme.success, fontSize: 11)))),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () => amtCtrl.text = (o.unpaidAmount / 2).toStringAsFixed(0),
              child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Center(child: Text('收50%', style: TextStyle(color: AppTheme.warning, fontSize: 11)))),
            )),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: noteCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
            decoration: const InputDecoration(labelText: '收款备注', labelStyle: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0) return;
              o.paidAmount += amt;
              o.paidAt = DateTime.now();
              o.paymentNote = noteCtrl.text;
              if (o.paidAmount >= o.totalAmount) {
                o.paymentStatus = PaymentStatus.paid;
                o.paidAmount = o.totalAmount;
              } else {
                o.paymentStatus = PaymentStatus.partial;
              }
              o.updatedAt = DateTime.now();
              crm.updateOrder(o);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('收款 ${Formatters.currency(amt)} 成功! ${o.isFullyPaid ? "已全额结清" : "剩余待收${Formatters.currency(o.unpaidAmount)}"}'),
                backgroundColor: AppTheme.success));
            },
            child: const Text('确认收款'),
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // === 出货对话框 (含物流单号+照片) ===
  void _showShipDialog(CrmProvider crm, SalesOrder o) {
    final trackCtrl = TextEditingController(text: o.trackingNumber);
    final carrierCtrl = TextEditingController(text: o.trackingCarrier);
    final noteCtrl = TextEditingController(text: o.trackingNote);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Icon(Icons.local_shipping, color: AppTheme.info),
            const SizedBox(width: 8),
            const Text('确认出货', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 8),
          Text('${o.contactName} | ${o.items.length}项产品 | ${Formatters.currency(o.totalAmount)}',
            style: const TextStyle(color: AppTheme.slate, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: carrierCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
            decoration: const InputDecoration(labelText: '物流公司', hintText: '如: ヤマト運輸, 佐川急便, EMS, DHL', prefixIcon: Icon(Icons.business, size: 18)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: trackCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
            decoration: const InputDecoration(labelText: '物流单据号', hintText: '输入快递/物流单号', prefixIcon: Icon(Icons.qr_code, size: 18)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
            decoration: const InputDecoration(labelText: '出货备注', labelStyle: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 8),
          // 上传物流凭证照片
          GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final xfile = await picker.pickImage(source: kIsWeb ? ImageSource.gallery : ImageSource.camera, maxWidth: 1920, imageQuality: 85);
              if (xfile != null) {
                set(() {
                  o.trackingPhotos.add(xfile.path);
                });
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('物流凭证已添加'), backgroundColor: AppTheme.success));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.steel.withValues(alpha: 0.3), style: BorderStyle.solid)),
              child: Row(children: [
                const Icon(Icons.add_a_photo, color: AppTheme.info, size: 20),
                const SizedBox(width: 8),
                Text('${o.trackingPhotos.isEmpty ? "拍照/上传物流凭证" : "已添加${o.trackingPhotos.length}张凭证"}',
                  style: const TextStyle(color: AppTheme.offWhite, fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              o.trackingNumber = trackCtrl.text;
              o.trackingCarrier = carrierCtrl.text;
              o.trackingNote = noteCtrl.text;
              o.trackingStatus = 'picked_up';
              o.shippedAt = DateTime.now();
              await crm.updateOrder(o);
              final shipErr = await crm.shipOrder(o.id);
              if (shipErr != null) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('\u274C \u51FA\u8D27\u5931\u8D25: $shipErr'), backgroundColor: AppTheme.danger, duration: const Duration(seconds: 4)));
                }
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${o.contactName} 的订单已出货${trackCtrl.text.isNotEmpty ? " | 单号: ${trackCtrl.text}" : ""}'),
                  backgroundColor: AppTheme.success));
              }
            },
            child: const Text('确认出货并扣减库存'),
          )),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }

  // ====== TAB 4: 员工业绩 ======
  Widget _staffSalesTab(CrmProvider crm) {
    final members = crm.teamMembers;
    final memberSales = <String, Map<String, dynamic>>{};
    for (final m in members) { memberSales[m.id] = {'name': m.name, 'role': m.role, 'dealCount': 0, 'totalAmount': 0.0, 'closedAmount': 0.0, 'orderCount': 0}; }
    for (final a in crm.assignments) {
      final ms = memberSales[a.memberId]; if (ms == null) continue;
      final deals = crm.getDealsByContact(a.contactId);
      ms['dealCount'] = (ms['dealCount'] as int) + deals.length;
      for (final d in deals) { ms['totalAmount'] = (ms['totalAmount'] as double) + d.amount; if (d.stage == DealStage.completed) { ms['closedAmount'] = (ms['closedAmount'] as double) + d.amount; } }
      ms['orderCount'] = (ms['orderCount'] as int) + crm.getOrdersByContact(a.contactId).length;
    }
    if (crm.assignments.isEmpty && members.isNotEmpty) {
      for (final d in crm.deals) {
        final ms = memberSales[members.first.id]!;
        ms['dealCount'] = (ms['dealCount'] as int) + 1; ms['totalAmount'] = (ms['totalAmount'] as double) + d.amount;
        if (d.stage == DealStage.completed) { ms['closedAmount'] = (ms['closedAmount'] as double) + d.amount; }
      }
    }
    final sorted = memberSales.entries.toList()..sort((a, b) => (b.value['totalAmount'] as double).compareTo(a.value['totalAmount'] as double));
    double maxAmount = 1;
    for (final e in sorted) { final a = e.value['totalAmount'] as double; if (a > maxAmount) maxAmount = a; }

    return ListView(padding: const EdgeInsets.all(12), children: [
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('员工销售额统计', style: TextStyle(color: AppTheme.offWhite, fontSize: 14, fontWeight: FontWeight.w600))),
      ...sorted.map((e) {
        final s = e.value; final ratio = (s['totalAmount'] as double) / maxAmount;
        return Container(
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.steel.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text((s['name'] as String).isNotEmpty ? (s['name'] as String)[0] : '?', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] as String, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${TeamMember.roleLabel(s['role'] as String)} | ${s['dealCount']}笔交易 | ${s['orderCount']}笔订单', style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Formatters.currency(s['totalAmount'] as double), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('成交${Formatters.currency(s['closedAmount'] as double)}', style: const TextStyle(color: AppTheme.success, fontSize: 9)),
              ]),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: ratio.clamp(0.02, 1.0), backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation(AppTheme.gold), minHeight: 3)),
          ]),
        );
      }),
      const SizedBox(height: 30),
    ]);
  }

  // ====== Deal Card ======
  Widget _dealCard(BuildContext context, CrmProvider crm, Deal deal) {
    final c = _color(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: deal.isStarred ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.steel.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(deal.stage.label, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          if (deal.isStarred) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: AppTheme.gold, size: 14)),
          Expanded(child: Text(deal.title, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.slate, size: 18), color: AppTheme.navyMid,
            onSelected: (action) async {
              if (action == 'edit') {
                _showEditDealSheet(context, crm, deal);
              } else if (action == 'delete') {
                _confirmDeleteDeal(context, crm, deal);
              } else if (action == 'star') {
                deal.isStarred = !deal.isStarred;
                await crm.updateDeal(deal);
                setState(() {});
              } else if (action.startsWith('stage_')) {
                final stageName = action.substring(6);
                final newStage = DealStage.values.firstWhere((s) => s.name == stageName, orElse: () => deal.stage);
                await crm.moveDealStage(deal.id, newStage);
                setState(() {});
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [
                Icon(Icons.edit, color: AppTheme.info, size: 16), SizedBox(width: 8),
                Text('编辑', style: TextStyle(color: AppTheme.offWhite, fontSize: 12))])),
              PopupMenuItem(value: 'star', child: Row(children: [
                Icon(deal.isStarred ? Icons.star_border : Icons.star, color: AppTheme.gold, size: 16), const SizedBox(width: 8),
                Text(deal.isStarred ? '取消星标' : '设为星标', style: const TextStyle(color: AppTheme.offWhite, fontSize: 12))])),
              const PopupMenuDivider(),
              // 阶段快速切换子菜单
              ...DealStage.values.where((s) => s != deal.stage).map((s) => PopupMenuItem(
                value: 'stage_${s.name}',
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('→ ${s.label}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 11)),
                ]),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline, color: AppTheme.danger, size: 16), SizedBox(width: 8),
                Text('删除', style: TextStyle(color: AppTheme.danger, fontSize: 12))])),
            ],
          ),
        ]),
        Text(deal.contactName, style: const TextStyle(color: AppTheme.slate, fontSize: 11)),
        if (deal.description.isNotEmpty) Text(deal.description, style: const TextStyle(color: AppTheme.slate, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (deal.notes.isNotEmpty) Row(children: [
          Icon(Icons.note_outlined, color: AppTheme.slate.withValues(alpha: 0.6), size: 11),
          const SizedBox(width: 3),
          Expanded(child: Text(deal.notes, style: TextStyle(color: AppTheme.gold.withValues(alpha: 0.7), fontSize: 10, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text(Formatters.currency(deal.amount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          if (deal.tags.isNotEmpty) ...deal.tags.take(2).map((t) => Container(
            margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: AppTheme.steel.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
            child: Text(t, style: const TextStyle(color: AppTheme.slate, fontSize: 8)))),
          Text('${deal.probability.toInt()}%', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: deal.probability / 100, backgroundColor: AppTheme.steel.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(c), minHeight: 2)),
        // 关联订单收款状态
        if (deal.orderId != null) _buildDealPaymentInfo(crm, deal),
      ]),
    );
  }

  /// 交易关联的订单 - 状态流水线 + 醒目操作按钮
  Widget _buildDealPaymentInfo(CrmProvider crm, Deal deal) {
    final order = crm.orders.where((o) => o.id == deal.orderId).firstOrNull;
    if (order == null) return const SizedBox.shrink();
    final payC = order.isFullyPaid ? AppTheme.success : order.paidAmount > 0 ? AppTheme.warning : AppTheme.slate;
    final payLabel = order.isFullyPaid ? '\u2705 \u5DF2\u7ED3\u6E05' : order.paidAmount > 0 ? '\u23F3 \u90E8\u5206\u6536\u6B3E' : '\u26A0 \u5F85\u6536\u6B3E';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.navyMid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: payC.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // 状态流水线
          Row(children: [
            _statusStep('\u5DF2\u4E0B\u5355', true, const Color(0xFF1ABC9C)),
            _statusLine(order.status != 'draft' && order.status != 'confirmed'),
            _statusStep('\u5DF2\u51FA\u8D27', order.status == 'shipped' || order.status == 'completed', AppTheme.info),
            _statusLine(order.isFullyPaid),
            _statusStep('\u5DF2\u6536\u6B3E', order.isFullyPaid, AppTheme.success),
          ]),
          const SizedBox(height: 8),
          // 收款进度条
          Row(children: [
            Icon(order.isFullyPaid ? Icons.check_circle : Icons.account_balance_wallet_outlined, color: payC, size: 14),
            const SizedBox(width: 6),
            Text(payLabel, style: TextStyle(color: payC, fontSize: 10, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${Formatters.currency(order.paidAmount)} / ${Formatters.currency(order.totalAmount)}',
              style: TextStyle(color: payC, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: order.totalAmount > 0 ? (order.paidAmount / order.totalAmount).clamp(0, 1) : 0,
              backgroundColor: AppTheme.steel.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(payC),
              minHeight: 4,
            ),
          ),
          // 物流信息
          if (order.trackingNumber.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              const Icon(Icons.local_shipping, color: AppTheme.info, size: 13),
              const SizedBox(width: 4),
              Expanded(child: Text('${order.trackingCarrier.isNotEmpty ? "${order.trackingCarrier}: " : ""}${order.trackingNumber}',
                style: const TextStyle(color: AppTheme.info, fontSize: 10))),
            ]),
          ),
          const SizedBox(height: 8),
          // 醒目操作按钮行
          Row(children: [
            if (order.status == 'confirmed')
              Expanded(child: GestureDetector(
                onTap: () => _showShipDialog(crm, order),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF74B9FF)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.local_shipping, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('\u786E\u8BA4\u51FA\u8D27', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              )),
            if (!order.isFullyPaid && order.status != 'cancelled' && order.status != 'draft')
              Expanded(child: GestureDetector(
                onTap: () => _showPaymentDialog(crm, order),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00B894), Color(0xFF55EFC4)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.attach_money, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('\u6536\u6B3E \u00A5${order.unpaidAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              )),
            if (order.status == 'shipped' && order.isFullyPaid)
              Expanded(child: GestureDetector(
                onTap: () async {
                  order.status = 'completed';
                  order.updatedAt = DateTime.now();
                  await crm.updateOrder(order);
                  final linkedDeal = crm.deals.where((d) => d.orderId == order.id).toList();
                  for (final d in linkedDeal) {
                    await crm.moveDealStage(d.id, DealStage.completed);
                  }
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('\u2705 \u4EA4\u6613\u5DF2\u5B8C\u6210!'), backgroundColor: AppTheme.success));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFF1C40F)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('\u5B8C\u6210\u4EA4\u6613', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              )),
          ]),
        ]),
      ),
    );
  }

  Widget _statusStep(String label, bool active, Color color) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          color: active ? color : AppTheme.steel.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: active ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: active ? color : AppTheme.slate, fontSize: 9, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    ]));
  }

  Widget _statusLine(bool active) {
    return Container(
      width: 30, height: 2, margin: const EdgeInsets.only(bottom: 14),
      color: active ? AppTheme.success.withValues(alpha: 0.6) : AppTheme.steel.withValues(alpha: 0.2),
    );
  }

  // ========== 删除确认 ==========
  void _confirmDeleteDeal(BuildContext context, CrmProvider crm, Deal deal) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.navyMid,
      title: const Text('确认删除', style: TextStyle(color: AppTheme.offWhite, fontSize: 16)),
      content: Text('确定要删除交易「${deal.title}」吗？\n金额: ${Formatters.currency(deal.amount)}\n此操作不可撤销。',
        style: const TextStyle(color: AppTheme.slate, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('取消', style: TextStyle(color: AppTheme.slate))),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          await crm.deleteDeal(deal.id);
          setState(() {});
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('已删除: ${deal.title}'), backgroundColor: AppTheme.danger));
          }
        }, child: const Text('删除', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  // ========== 编辑交易弹窗 ==========
  void _showEditDealSheet(BuildContext context, CrmProvider crm, Deal deal) {
    final titleCtrl = TextEditingController(text: deal.title);
    final descCtrl = TextEditingController(text: deal.description);
    final amountCtrl = TextEditingController(text: deal.amount > 0 ? deal.amount.toStringAsFixed(0) : '');
    final probCtrl = TextEditingController(text: deal.probability.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: deal.notes);
    final tagsCtrl = TextEditingController(text: deal.tags.join(', '));
    String selectedStage = deal.stage.name;
    String selectedCurrency = deal.currency;
    DateTime expectedDate = deal.expectedCloseDate;
    String? selectedContactId = deal.contactId;
    String selectedContactName = deal.contactName;
    final contacts = crm.allContacts;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('编辑交易', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 6),
              Flexible(child: ListView(shrinkWrap: true, children: [
                // 标题
                TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 13),
                  decoration: _editInputDeco('交易标题 *')),
                const SizedBox(height: 8),
                // 客户
                DropdownButtonFormField<String>(
                  value: contacts.any((c) => c.id == selectedContactId) ? selectedContactId : null,
                  decoration: const InputDecoration(labelText: '关联客户', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  items: contacts.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.company}', style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) { if (v != null) set(() { selectedContactId = v; selectedContactName = contacts.firstWhere((c) => c.id == v).name; }); },
                ),
                const SizedBox(height: 8),
                // 描述
                TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  maxLines: 2, decoration: _editInputDeco('描述')),
                const SizedBox(height: 8),
                // 金额 + 货币
                Row(children: [
                  Expanded(flex: 3, child: TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: _editInputDeco('金额'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    dropdownColor: AppTheme.navyMid, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                    items: ['JPY', 'USD', 'CNY', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                    onChanged: (v) { if (v != null) set(() => selectedCurrency = v); },
                  )),
                ]),
                const SizedBox(height: 8),
                // 交易阶段
                const Text('交易阶段', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: DealStage.values.map((s) {
                  final sel = selectedStage == s.name;
                  return ChoiceChip(label: Text(s.label, style: TextStyle(fontSize: 9, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => selectedStage = s.name),
                    selectedColor: _color(s), backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact);
                }).toList()),
                const SizedBox(height: 8),
                // 概率
                Row(children: [
                  const Text('成交概率: ', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                  SizedBox(width: 60, child: TextField(controller: probCtrl, keyboardType: TextInputType.number,
                    textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                    decoration: _editInputDeco(''))),
                  const Text(' %', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                ]),
                const SizedBox(height: 8),
                // 预计成交日期
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: expectedDate,
                      firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (picked != null) set(() => expectedDate = picked);
                  },
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [const Icon(Icons.calendar_today, color: AppTheme.slate, size: 16), const SizedBox(width: 8),
                      Text('预计成交: ${Formatters.dateShort(expectedDate)}', style: const TextStyle(color: AppTheme.offWhite, fontSize: 11))])),
                ),
                const SizedBox(height: 8),
                // 标签
                TextField(controller: tagsCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  decoration: _editInputDeco('标签 (逗号分隔)')),
                const SizedBox(height: 8),
                // 备注
                TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  maxLines: 2, decoration: _editInputDeco('备注')),
              ])),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: titleCtrl.text.trim().isEmpty ? null : () async {
                  deal.title = titleCtrl.text.trim();
                  deal.description = descCtrl.text.trim();
                  deal.contactId = selectedContactId ?? deal.contactId;
                  deal.contactName = selectedContactName;
                  deal.amount = double.tryParse(amountCtrl.text) ?? deal.amount;
                  deal.currency = selectedCurrency;
                  deal.stage = DealStage.values.firstWhere((s) => s.name == selectedStage, orElse: () => deal.stage);
                  deal.probability = (double.tryParse(probCtrl.text) ?? deal.probability).clamp(0, 100);
                  deal.expectedCloseDate = expectedDate;
                  deal.notes = notesCtrl.text.trim();
                  deal.tags = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                  deal.updatedAt = DateTime.now();
                  await crm.updateDeal(deal);
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('已更新: ${deal.title}'), backgroundColor: AppTheme.success));
                  }
                },
                child: const Text('保存修改'),
              )),
              const SizedBox(height: 12),
            ]),
          ),
        );
      }),
    );
  }

  InputDecoration _editInputDeco(String label) => InputDecoration(
    labelText: label.isNotEmpty ? label : null, labelStyle: const TextStyle(fontSize: 11),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    filled: true, fillColor: AppTheme.navyMid,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
  );

  Widget _miniDealCard(CrmProvider crm, Deal deal) {
    final c = _color(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 16), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.navyMid, borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        if (deal.isStarred) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star, color: AppTheme.gold, size: 12)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(deal.title, style: const TextStyle(color: AppTheme.offWhite, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          Text(deal.contactName, style: const TextStyle(color: AppTheme.slate, fontSize: 10)),
        ])),
        Text(Formatters.currency(deal.amount), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  void _drillStageDeals(DealStage stage, List<Deal> deals) {
    final crm = context.read<CrmProvider>();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _color(stage), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('${stage.label} (${deals.length})', style: const TextStyle(color: AppTheme.offWhite, fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.slate, size: 18), onPressed: () => Navigator.pop(ctx)),
          ])),
          Flexible(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12),
            children: deals.map((d) => _dealCard(ctx, crm, d)).toList())),
        ]),
      ),
    );
  }

  Color _color(DealStage s) {
    switch (s) {
      case DealStage.lead: return AppTheme.slate; case DealStage.contacted: return AppTheme.info;
      case DealStage.proposal: return const Color(0xFF9B59B6); case DealStage.negotiation: return AppTheme.warning;
      case DealStage.ordered: return const Color(0xFF1ABC9C); case DealStage.paid: return AppTheme.success;
      case DealStage.shipped: return AppTheme.info; case DealStage.inTransit: return const Color(0xFF8E7CC3);
      case DealStage.received: return const Color(0xFF5DADE2); case DealStage.completed: return AppTheme.success;
      case DealStage.lost: return AppTheme.danger;
    }
  }

  // ========== New Order Sheet ==========
  void _showNewOrderSheet(BuildContext context, CrmProvider crm) {
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
                const Text('新增订单', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.slate), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 6),
              Flexible(child: ListView(shrinkWrap: true, children: [
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
                const Text('交易阶段', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: DealStage.values.where((s) => s != DealStage.lost).map((s) {
                  final sel = selectedStage == s.name;
                  return ChoiceChip(label: Text(s.label, style: TextStyle(fontSize: 9, color: sel ? AppTheme.navy : AppTheme.offWhite)),
                    selected: sel, onSelected: (_) => set(() => selectedStage = s.name),
                    selectedColor: _color(s), backgroundColor: AppTheme.navyMid,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact);
                }).toList()),
                const SizedBox(height: 8),
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
                  final isOverStock = qty > 0 && qty > available; // 数量超可用库存
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
                TextField(controller: addressCtrl, style: const TextStyle(color: AppTheme.offWhite, fontSize: 12),
                  decoration: InputDecoration(labelText: '配送地址', labelStyle: const TextStyle(fontSize: 11), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true, fillColor: AppTheme.navyMid, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none))),
                const SizedBox(height: 6),
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
                  final available = stock - reserved;
                  if (e.value > available) {
                    warnings.add('${p.name}: 需${e.value}, 可用$available');
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
                  // 下单前二次确认：如果有库存不足，先弹确认框
                  final stockIssues = <Map<String, dynamic>>[];
                  for (final e in selectedProducts.entries) {
                    final p = products.firstWhere((p) => p.id == e.key);
                    final stock = crm.getProductStock(p.id);
                    final reserved = crm.getReservedStock(p.id);
                    final available = stock - reserved;
                    if (e.value > available) {
                      stockIssues.add({'name': p.name, 'need': e.value, 'available': available});
                    }
                  }

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
                    if (ctx.mounted) {
                      _showStockShortageDialog(ctx, crm, err, selectedProducts, products);
                    }
                    return;
                  }
                  Navigator.pop(ctx);
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('订单已创建: $selectedContactName | ${Formatters.currency(total)}'),
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

  /// 库存不足详细弹窗 — 替代一闪而过的SnackBar
  void _showStockShortageDialog(BuildContext context, CrmProvider crm, String errorMsg,
      Map<String, int> selectedProducts, List<Product> products) {
    // 解析每个产品的库存状况
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
        details.add({
          'name': p.name,
          'required': required,
          'available': available,
          'stock': stock,
          'reserved': reserved,
          'shortage': required - available,
          'hasProduction': hasProduction,
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.danger, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('库存不足, 无法下单', style: TextStyle(color: AppTheme.danger, fontSize: 16, fontWeight: FontWeight.bold))),
        ]),
        content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // 总体原因
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
            child: Text(errorMsg, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('缺货明细:', style: TextStyle(color: AppTheme.offWhite, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...details.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.navyMid, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] as String, style: const TextStyle(color: AppTheme.offWhite, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  _shortageMetric('需要', '${d['required']}', AppTheme.offWhite),
                  _shortageMetric('可用', '${d['available']}', d['available'] as int <= 0 ? AppTheme.danger : AppTheme.warning),
                  _shortageMetric('缺口', '-${d['shortage']}', AppTheme.danger),
                  if ((d['reserved'] as int) > 0) _shortageMetric('预留', '${d['reserved']}', AppTheme.warning),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ((d['hasProduction'] as bool) ? AppTheme.warning : AppTheme.danger).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (d['hasProduction'] as bool) ? '有排产中' : '无排产计划',
                      style: TextStyle(color: (d['hasProduction'] as bool) ? AppTheme.warning : AppTheme.danger, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
              ]),
            )),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('建议操作:', style: TextStyle(color: AppTheme.info, fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('1. 前往"生产"板块安排排产计划', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
              Text('2. 前往"产品&库存"手动入库/调整', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
              Text('3. 减少下单数量至可用库存以内', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
              Text('4. 设置交货日期晚于排产完成日', style: TextStyle(color: AppTheme.slate, fontSize: 11)),
            ]),
          ),
        ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了, 返回修改', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _shortageMetric(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
    ]));
  }
}
