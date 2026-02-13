import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/crm_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../utils/download_helper.dart';

const String appVersion = 'v24.0';

/// 角色工具类
class AppRole {
  static String label(String role) {
    switch (role) {
      case 'admin': return '管理员';
      case 'manager': return '经理';
      case 'member': return '成员';
      default: return role;
    }
  }
  static bool canEditData(String role) => true;
  static bool canManageTeam(String role) => role == 'admin' || role == 'manager';
  static bool canViewStats(String role) => role == 'admin' || role == 'manager';
  static bool canDelete(String role) => role == 'admin';
  static bool canAssignRole(String role) => role == 'admin';
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _appUser;
  List<AppUser> _allUsers = [];
  bool _isLoading = true;
  String? _syncStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    if (fbUser != null) {
      _appUser = AppUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
        role: UserRole.admin,
      );
    } else {
      _appUser = AppUser(
        uid: 'local',
        email: 'local@mode',
        displayName: 'James Liu',
        role: UserRole.admin,
      );
    }

    if (mounted) setState(() => _isLoading = false);

    if (fbUser != null) {
      try {
        final auth = AuthService();
        final detailedUser = await auth.getCurrentUser()
            .timeout(const Duration(seconds: 3));
        if (detailedUser != null && mounted) {
          setState(() => _appUser = detailedUser);
        }
      } catch (_) {}

      if (_appUser?.role == UserRole.admin) {
        try {
          final auth = AuthService();
          final users = await auth.getAllUsers()
              .timeout(const Duration(seconds: 3));
          if (mounted && users.isNotEmpty) setState(() => _allUsers = users);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final user = _appUser ?? AppUser(uid: 'local', email: 'local@mode', displayName: 'User', role: UserRole.member);
    bool isFirebase = false;
    try {
      isFirebase = FirebaseAuth.instance.currentUser != null;
    } catch (_) {}

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(user, isFirebase),
          const SizedBox(height: 20),
          _buildProfileCard(user, isFirebase),
          const SizedBox(height: 16),
          _buildMyWorkCard(context, user),
          const SizedBox(height: 16),
          _buildExportCard(context),
          const SizedBox(height: 16),
          _buildEmailCard(context),
          const SizedBox(height: 16),
          _buildActionsCard(context, isFirebase),
          const SizedBox(height: 16),
          _buildPermissionsCard(user),
          if (user.role == UserRole.admin && _allUsers.length > 1) ...[
            const SizedBox(height: 16),
            _buildUserManagement(user),
          ],
          const SizedBox(height: 16),
          _buildVersionInfo(isFirebase),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildHeader(AppUser user, bool isFirebase) {
    return Row(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text(
          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        )),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.displayName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _roleColor(user.role.name).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(AppRole.label(user.role.name),
              style: TextStyle(color: _roleColor(user.role.name), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFirebase ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isFirebase ? Icons.cloud_done : Icons.cloud_off, size: 12,
                color: isFirebase ? AppTheme.success : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(isFirebase ? '云端' : '本地', style: TextStyle(
                color: isFirebase ? AppTheme.success : AppTheme.textSecondary,
                fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(appVersion, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ]),
      ])),
    ]);
  }

  Widget _buildProfileCard(AppUser user, bool isFirebase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.person, color: AppTheme.primaryBlue, size: 18),
          SizedBox(width: 8),
          Text('个人信息', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        _infoRow(Icons.email_outlined, '邮箱', user.email),
        _infoRow(Icons.calendar_today, '注册时间', Formatters.dateFull(user.createdAt)),
        _infoRow(Icons.badge_outlined, 'UID', user.uid.length > 12 ? '${user.uid.substring(0, 12)}...' : user.uid),
        _infoRow(Icons.sync, '模式', isFirebase ? 'Firebase 云端同步' : '本地模式'),
        if (_syncStatus != null) _infoRow(Icons.info_outline, '同步', _syncStatus!),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('编辑资料', style: TextStyle(fontSize: 13)),
          onPressed: () => _showEditProfile(context, user),
        )),
      ]),
    );
  }

  Widget _buildMyWorkCard(BuildContext context, AppUser user) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final myTasks = crm.tasks.where((t) => t.assigneeName == user.displayName || t.creatorName == user.displayName).toList();
      final activeTasks = myTasks.where((t) => t.status != 'completed').length;
      final completedTasks = myTasks.where((t) => t.status == 'completed').length;
      final myAssignments = crm.assignments.where((a) => a.memberName == user.displayName).length;
      final myProductions = crm.productionOrders.where((p) => p.assigneeName == user.displayName).length;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.work_outline, color: Color(0xFF00CEC9), size: 18),
            SizedBox(width: 8),
            Text('我的工作', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statBox('$activeTasks', '进行中', AppTheme.warning)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$completedTasks', '已完成', AppTheme.success)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$myAssignments', '跟进人脉', AppTheme.primaryBlue)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$myProductions', '生产单', const Color(0xFF00CEC9))),
          ]),
        ]),
      );
    });
  }

  // ========== Excel 导出卡片 ==========
  Widget _buildExportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.file_download, color: AppTheme.success, size: 18),
          SizedBox(width: 8),
          Text('数据导出', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        const Text('导出数据为 CSV/Excel 格式', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _exportChip(context, Icons.people, '人脉', AppTheme.primaryBlue, 'contacts'),
          _exportChip(context, Icons.view_kanban, '销售管线', AppTheme.primaryPurple, 'deals'),
          _exportChip(context, Icons.shopping_cart, '订单', AppTheme.accentGold, 'orders'),
          _exportChip(context, Icons.science, '产品', const Color(0xFF00CEC9), 'products'),
          _exportChip(context, Icons.inventory, '库存', AppTheme.warning, 'inventory'),
          _exportChip(context, Icons.precision_manufacturing, '生产', AppTheme.danger, 'production'),
          _exportChip(context, Icons.task_alt, '任务', AppTheme.success, 'tasks'),
          _exportChip(context, Icons.select_all, '全部导出', Colors.white, 'all'),
        ]),
      ]),
    );
  }

  Widget _exportChip(BuildContext context, IconData icon, String label, Color color, String type) {
    return GestureDetector(
      onTap: () => _exportData(context, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _exportData(BuildContext context, String type) {
    final crm = context.read<CrmProvider>();
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    try {
      if (type == 'all') {
        _doExport('contacts', dateStr, _contactsCsv(crm));
        _doExport('deals', dateStr, _dealsCsv(crm));
        _doExport('orders', dateStr, _ordersCsv(crm));
        _doExport('products', dateStr, _productsCsv(crm));
        _doExport('inventory', dateStr, _inventoryCsv(crm));
        _doExport('production', dateStr, _productionCsv(crm));
        _doExport('tasks', dateStr, _tasksCsv(crm));
      } else {
        String csv;
        switch (type) {
          case 'contacts': csv = _contactsCsv(crm); break;
          case 'deals': csv = _dealsCsv(crm); break;
          case 'orders': csv = _ordersCsv(crm); break;
          case 'products': csv = _productsCsv(crm); break;
          case 'inventory': csv = _inventoryCsv(crm); break;
          case 'production': csv = _productionCsv(crm); break;
          case 'tasks': csv = _tasksCsv(crm); break;
          default: return;
        }
        _doExport(type, dateStr, csv);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == "all" ? "全部数据" : type} 导出成功'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _doExport(String name, String dateStr, String csvContent) {
    final fileName = 'dealnavigator_${name}_$dateStr.csv';
    downloadCsvWeb(fileName, csvContent);
  }

  String _contactsCsv(CrmProvider crm) {
    final rows = <List<String>>[
      ['姓名', '公司', '职位', '电话', '邮箱', '地址', '行业', '关系强度', '与我关系', '标签', '备注', '最后联系', '创建时间'],
      ...crm.allContacts.map((c) => [
        c.name, c.company, c.position, c.phone, c.email, c.address,
        c.industry.label, c.strength.label, c.myRelation.label,
        c.tags.join(';'), c.notes,
        Formatters.dateFull(c.lastContactedAt), Formatters.dateFull(c.createdAt),
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _dealsCsv(CrmProvider crm) {
    final rows = <List<String>>[
      ['标题', '联系人', '阶段', '金额', '币种', '概率%', '预期关闭日期', '标签', '描述', '创建时间', '更新时间'],
      ...crm.deals.map((d) => [
        d.title, d.contactName, d.stage.label, d.amount.toStringAsFixed(0),
        d.currency, d.probability.toString(),
        Formatters.dateFull(d.expectedCloseDate),
        d.tags.join(';'), d.description,
        Formatters.dateFull(d.createdAt), Formatters.dateFull(d.updatedAt),
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _ordersCsv(CrmProvider crm) {
    final rows = <List<String>>[
      ['订单ID', '联系人', '价格类型', '总金额', '状态', '商品明细', '创建时间', '更新时间'],
      ...crm.orders.map((o) => [
        o.id.substring(0, 8), o.contactName, o.priceType, o.totalAmount.toStringAsFixed(0),
        o.status, o.items.map((i) => '${i.productName}x${i.quantity}').join(';'),
        Formatters.dateFull(o.createdAt), Formatters.dateFull(o.updatedAt),
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _productsCsv(CrmProvider crm) {
    final rows = <List<String>>[
      ['编码', '名称', '日文名', '类别', '规格', '每箱数量', '代理价', '诊所价', '零售价', '储存方式', '保质期', '说明'],
      ...crm.products.map((p) => [
        p.code, p.name, p.nameJa, p.category, p.specification,
        p.unitsPerBox.toString(), p.agentPrice.toStringAsFixed(0),
        p.clinicPrice.toStringAsFixed(0), p.retailPrice.toStringAsFixed(0),
        p.storageMethod, p.shelfLife, p.description,
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _inventoryCsv(CrmProvider crm) {
    final stocks = crm.inventoryStocks;
    final rows = <List<String>>[
      ['产品ID', '产品名', '产品编码', '当前库存'],
      ...stocks.map((s) => [s.productId, s.productName, s.productCode, s.currentStock.toString()]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _productionCsv(CrmProvider crm) {
    final rows = <List<String>>[
      ['产品', '工厂', '数量', '批次号', '状态', '负责人', '创建日期', '开始日期', '完成日期'],
      ...crm.productionOrders.map((p) => [
        p.productName, p.factoryName, p.quantity.toString(), p.batchNumber,
        p.status, p.assigneeName,
        Formatters.dateFull(p.createdAt),
        p.startedDate != null ? Formatters.dateFull(p.startedDate!) : '',
        p.completedDate != null ? Formatters.dateFull(p.completedDate!) : '',
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _tasksCsv(CrmProvider crm) {
    final rows = <List<String>>[
      ['标题', '描述', '负责人', '创建人', '优先级', '阶段', '截止日期', '预计工时', '实际工时', '标签'],
      ...crm.tasks.map((t) => [
        t.title, t.description, t.assigneeName, t.creatorName,
        t.priority, t.phase.name, Formatters.dateFull(t.dueDate),
        t.estimatedHours.toString(), t.actualHours.toString(),
        t.tags.join(';'),
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // ========== 邮件功能卡片 ==========
  Widget _buildEmailCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.email, color: AppTheme.primaryPurple, size: 18),
          SizedBox(width: 8),
          Text('发送邮件', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        const Text('快速发送邮件给联系人或团队', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _emailActionButton(
            Icons.send, '新邮件', AppTheme.primaryPurple,
            () => _composeEmail(context),
          )),
          const SizedBox(width: 8),
          Expanded(child: _emailActionButton(
            Icons.groups, '群发联系人', AppTheme.primaryBlue,
            () => _composeBulkEmail(context),
          )),
          const SizedBox(width: 8),
          Expanded(child: _emailActionButton(
            Icons.summarize, '发送报告', AppTheme.success,
            () => _composeReportEmail(context),
          )),
        ]),
      ]),
    );
  }

  Widget _emailActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _composeEmail(BuildContext context, {String? to, String? subject, String? body}) async {
    final toCtrl = TextEditingController(text: to ?? '');
    final subjectCtrl = TextEditingController(text: subject ?? '');
    final bodyCtrl = TextEditingController(text: body ?? '');
    final crm = context.read<CrmProvider>();
    final contactEmails = crm.allContacts.where((c) => c.email.isNotEmpty).toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('撰写邮件', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (contactEmails.isNotEmpty && toCtrl.text.isEmpty) ...[
                SizedBox(
                  height: 36,
                  child: ListView(scrollDirection: Axis.horizontal, children: contactEmails.take(10).map((c) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() { toCtrl.text = c.email; });
                        },
                        child: Chip(
                          avatar: CircleAvatar(backgroundColor: c.industry.color, radius: 10,
                            child: Text(c.name[0], style: const TextStyle(fontSize: 9, color: Colors.white))),
                          label: Text(c.name, style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ).toList()),
                ),
                const SizedBox(height: 8),
              ],
              TextField(controller: toCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '收件人', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: subjectCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '主题', prefixIcon: Icon(Icons.subject, color: AppTheme.textSecondary, size: 18))),
              const SizedBox(height: 10),
              TextField(controller: bodyCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 5, decoration: const InputDecoration(labelText: '正文', alignLabelWithHint: true)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('发送'),
                  onPressed: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: toCtrl.text.trim(),
                      queryParameters: {
                        if (subjectCtrl.text.isNotEmpty) 'subject': subjectCtrl.text.trim(),
                        if (bodyCtrl.text.isNotEmpty) 'body': bodyCtrl.text.trim(),
                      },
                    );
                    try {
                      await launchUrl(uri);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('无法打开邮件客户端: $e'), backgroundColor: AppTheme.danger),
                        );
                      }
                    }
                  },
                )),
              ]),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  void _composeBulkEmail(BuildContext context) {
    final crm = context.read<CrmProvider>();
    final contactEmails = crm.allContacts.where((c) => c.email.isNotEmpty).map((c) => c.email).toList();
    if (contactEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可发送的联系人邮箱'), backgroundColor: AppTheme.warning),
      );
      return;
    }
    _composeEmail(context,
      to: contactEmails.join(','),
      subject: 'Deal Navigator - 业务更新',
      body: '尊敬的合作伙伴，\n\n感谢您的持续合作。\n\n此致\nDeal Navigator 团队',
    );
  }

  void _composeReportEmail(BuildContext context) {
    final crm = context.read<CrmProvider>();
    final stats = crm.stats;
    final now = DateTime.now();
    final subject = 'Deal Navigator 业务报告 - ${now.year}/${now.month}/${now.day}';
    final body = '''Deal Navigator 业务报告
日期: ${Formatters.dateFull(now)}

=== 核心指标 ===
人脉总数: ${stats['totalContacts']}
活跃管线: ${stats['activeDeals']}
管线金额: ${Formatters.currency(stats['pipelineValue'] as double)}
成交金额: ${Formatters.currency(stats['closedValue'] as double)}
成交率: ${(stats['winRate'] as double).toStringAsFixed(1)}%

=== 销售数据 ===
总订单: ${stats['totalOrders']}
完成订单: ${stats['completedOrders']}
销售总额: ${Formatters.currency(stats['salesTotal'] as double)}

=== 生产数据 ===
活跃生产: ${stats['activeProductions']}
完成生产: ${stats['completedProductions']}
工厂数: ${stats['activeFactories']}

---
由 Deal Navigator $appVersion 生成
''';
    _composeEmail(context, subject: subject, body: body);
  }

  Widget _buildActionsCard(BuildContext context, bool isFirebase) {
    final isAdmin = _appUser?.role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.settings, color: AppTheme.textSecondary, size: 18),
          SizedBox(width: 8),
          Text('设置', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        if (isFirebase) ...[
          _actionTile(Icons.sync, '立即同步最新数据', () async {
            setState(() => _syncStatus = '正在同步...');
            try {
              final crm = context.read<CrmProvider>();
              await crm.syncFromCloud().timeout(const Duration(seconds: 15));
              if (mounted) {
                setState(() => _syncStatus = crm.syncStatus ?? '同步成功');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已拉取最新公共数据'), backgroundColor: AppTheme.success));
              }
            } catch (e) {
              if (mounted) setState(() => _syncStatus = '同步超时，请重试');
            }
          }),
          // 管理员专属：数据备份
          if (isAdmin) _actionTile(Icons.backup, '📦 数据备份（管理员）', () => _showBackupDialog(context), color: AppTheme.accentGold),
          if (isAdmin) _actionTile(Icons.restore, '📂 恢复备份（管理员）', () => _showRestoreDialog(context), color: AppTheme.accentGold),
          _actionTile(Icons.lock_outline, '修改密码', () => _showChangePassword(context)),
        ],
        _actionTile(Icons.info_outline, '关于 Deal Navigator', () {
          showAboutDialog(
            context: context,
            applicationName: 'Deal Navigator',
            applicationVersion: '$appVersion ${isFirebase ? "(Cloud)" : "(Local)"}',
            children: [
              Text(isFirebase
                ? 'CRM & 商务管理系统\nFirebase 公共协作模式\n所有成员共享同一份数据\n\nBuild: ${DateTime.now().year}.${DateTime.now().month}'
                : 'CRM & 商务管理系统\n本地模式\n\nBuild: ${DateTime.now().year}.${DateTime.now().month}'),
            ],
          );
        }),
        if (isFirebase && widget.onLogout != null)
          _actionTile(Icons.logout, '退出登录', () => _confirmLogout(context), color: AppTheme.danger),
      ]),
    );
  }

  // ========== 管理员备份功能 ==========
  void _showBackupDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Row(children: [
        Icon(Icons.backup, color: AppTheme.accentGold, size: 22),
        SizedBox(width: 8),
        Text('数据备份', style: TextStyle(color: AppTheme.textPrimary)),
      ]),
      content: const Text('将当前所有公共数据创建快照备份到云端。\n备份包含：人脉、交易、订单、产品、库存、生产等全部数据。\n\n建议每天备份一次。', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        ElevatedButton.icon(
          icon: const Icon(Icons.backup, size: 16),
          label: const Text('立即备份'),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ));
    if (confirm != true || !mounted) return;

    setState(() => _syncStatus = '正在创建备份...');
    try {
      final crm = context.read<CrmProvider>();
      final backupId = await crm.createBackup(_appUser?.displayName ?? 'admin')
          .timeout(const Duration(seconds: 30));
      if (mounted) {
        setState(() => _syncStatus = '备份成功: $backupId');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('备份创建成功！ID: $backupId'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncStatus = '备份失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('备份失败: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _showRestoreDialog(BuildContext context) async {
    setState(() => _syncStatus = '正在获取备份列表...');
    List<Map<String, dynamic>> backups = [];
    try {
      final crm = context.read<CrmProvider>();
      backups = await crm.getBackupList().timeout(const Duration(seconds: 10));
    } catch (e) {
      if (mounted) {
        setState(() => _syncStatus = '获取备份列表失败');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('获取备份列表失败: $e'), backgroundColor: AppTheme.danger));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _syncStatus = null);

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('暂无备份记录'), backgroundColor: AppTheme.warning));
      return;
    }

    final selected = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Row(children: [
        Icon(Icons.restore, color: AppTheme.accentGold, size: 22),
        SizedBox(width: 8),
        Text('选择要恢复的备份', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: backups.length,
          itemBuilder: (_, i) {
            final b = backups[i];
            final ts = DateTime.tryParse(b['timestamp'] ?? '');
            final dateStr = ts != null ? '${ts.year}/${ts.month.toString().padLeft(2, "0")}/${ts.day.toString().padLeft(2, "0")} ${ts.hour.toString().padLeft(2, "0")}:${ts.minute.toString().padLeft(2, "0")}' : '未知';
            return Card(
              color: AppTheme.cardBgLight,
              child: ListTile(
                leading: const Icon(Icons.archive, color: AppTheme.accentGold),
                title: Text(dateStr, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('操作人: ${b['createdBy'] ?? '未知'} | ${b['summary'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, b['id'] as String?),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ],
    ));
    if (selected == null || !mounted) return;

    final confirmRestore = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('确认恢复', style: TextStyle(color: AppTheme.danger)),
      content: const Text('恢复备份将覆盖当前所有数据！此操作不可撤销。\n\n确定要恢复吗？', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('确认恢复'),
        ),
      ],
    ));
    if (confirmRestore != true || !mounted) return;

    setState(() => _syncStatus = '正在恢复备份...');
    try {
      final crm = context.read<CrmProvider>();
      await crm.restoreBackup(selected).timeout(const Duration(seconds: 30));
      if (mounted) {
        setState(() => _syncStatus = '恢复成功');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('数据已恢复！'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncStatus = '恢复失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('恢复失败: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  Widget _buildPermissionsCard(AppUser user) {
    final role = user.role.name;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.security, color: AppTheme.accentGold, size: 18),
          SizedBox(width: 8),
          Text('权限说明', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        _permRow('查看所有数据', true),
        _permRow('编辑/新增数据', AppRole.canEditData(role)),
        _permRow('管理团队成员', AppRole.canManageTeam(role)),
        _permRow('查看统计仪表板', AppRole.canViewStats(role)),
        _permRow('删除数据', AppRole.canDelete(role)),
        _permRow('管理用户权限', AppRole.canAssignRole(role)),
      ]),
    );
  }

  Widget _buildUserManagement(AppUser currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.admin_panel_settings, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Text('用户管理 (${_allUsers.length})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        ...(_allUsers.map((u) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: u.uid == currentUser.uid ? AppTheme.primaryPurple.withValues(alpha: 0.08) : AppTheme.cardBgLight,
            borderRadius: BorderRadius.circular(10),
            border: u.uid == currentUser.uid ? Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)) : null,
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _roleColor(u.role.name).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(u.displayName.isNotEmpty ? u.displayName[0] : '?',
                style: TextStyle(color: _roleColor(u.role.name), fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(u.displayName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                if (u.uid == currentUser.uid) ...[
                  const SizedBox(width: 6),
                  const Text('(当前)', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 10)),
                ],
              ]),
              Text(u.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
            if (u.uid != currentUser.uid)
              PopupMenuButton<UserRole>(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _roleColor(u.role.name).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(AppRole.label(u.role.name), style: TextStyle(color: _roleColor(u.role.name), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                color: AppTheme.cardBgLight,
                onSelected: (role) async {
                  try {
                    await AuthService().updateUserRole(u.uid, role).timeout(const Duration(seconds: 4));
                    _loadUser();
                  } catch (_) {}
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${u.displayName} 角色已更新为 ${AppRole.label(role.name)}'),
                      backgroundColor: AppTheme.success,
                    ));
                  }
                },
                itemBuilder: (_) => UserRole.values.where((r) => r != u.role).map((r) => PopupMenuItem(
                  value: r,
                  child: Text(AppRole.label(r.name), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                )).toList(),
              ),
          ]),
        ))),
      ]),
    );
  }

  // ========== 版本信息卡片 ==========
  Widget _buildVersionInfo(bool isFirebase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardBg, AppTheme.primaryPurple.withValues(alpha: 0.08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Deal Navigator', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$appVersion | ${isFirebase ? "Firebase Cloud" : "Local Mode"}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.darkBg.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CRM & 商务管理系统', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text('外泌体 | NAD+ | NMN | 医药保健品', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            SizedBox(height: 4),
            Text('金融 | 股权投融资 | 交易 | 海内外进出口', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  // ========== Helpers ==========
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 10),
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _permRow(String label, bool allowed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(allowed ? Icons.check_circle : Icons.cancel,
          color: allowed ? AppTheme.success : AppTheme.textSecondary.withValues(alpha: 0.4), size: 16),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
          color: allowed ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppTheme.textPrimary;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: TextStyle(color: c, fontSize: 14)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
      onTap: onTap,
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppTheme.danger;
      case 'manager': return AppTheme.accentGold;
      case 'member': return AppTheme.primaryBlue;
      default: return AppTheme.textSecondary;
    }
  }

  void _showEditProfile(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('编辑资料', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: '姓名', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              try {
                await AuthService().updateProfile(user.uid, nameCtrl.text.trim())
                    .timeout(const Duration(seconds: 4));
                await _loadUser();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('资料已更新'), backgroundColor: AppTheme.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新失败: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              }
            },
            child: const Text('保存'),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final pwdCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('修改密码', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: pwdCtrl, obscureText: true, style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: '新密码 (至少6位)', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (pwdCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码至少6位'), backgroundColor: AppTheme.warning));
                return;
              }
              try {
                await AuthService().changePassword(pwdCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码已修改'), backgroundColor: AppTheme.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改失败: $e'), backgroundColor: AppTheme.danger));
                }
              }
            },
            child: const Text('确认修改'),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('确认退出', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('退出后需要重新登录', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout?.call();
            },
            child: const Text('退出', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
