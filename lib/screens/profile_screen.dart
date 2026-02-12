import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

/// 本地用户模型（无 Firebase 依赖）
class LocalUser {
  String name;
  String email;
  String phone;
  String role;
  DateTime createdAt;

  LocalUser({
    this.name = 'James Liu',
    this.email = 'james@dealnavigator.com',
    this.phone = '',
    this.role = 'admin',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';
  String get id => 'local-user-001';
}

/// 角色工具类（从 auth_service 迁移）
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
  late LocalUser _user;

  @override
  void initState() {
    super.initState();
    _user = LocalUser();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(_user),
          const SizedBox(height: 20),
          _buildProfileCard(_user),
          const SizedBox(height: 16),
          _buildPermissionsCard(_user),
          const SizedBox(height: 16),
          _buildMyWorkCard(context, _user),
          const SizedBox(height: 16),
          _buildActionsCard(context),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildHeader(LocalUser user) {
    return Row(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        )),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _roleColor(user.role).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(AppRole.label(user.role),
              style: TextStyle(color: _roleColor(user.role), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(user.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ])),
    ]);
  }

  Widget _buildProfileCard(LocalUser user) {
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
        _infoRow(Icons.phone_outlined, '电话', user.phone.isEmpty ? '未设置' : user.phone),
        _infoRow(Icons.calendar_today, '注册时间', Formatters.dateFull(user.createdAt)),
        _infoRow(Icons.badge_outlined, '模式', '本地模式'),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('编辑资料', style: TextStyle(fontSize: 13)),
          onPressed: () => _showEditProfile(context, user),
        )),
      ]),
    );
  }

  Widget _buildPermissionsCard(LocalUser user) {
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
        _permRow('编辑/新增数据', AppRole.canEditData(user.role)),
        _permRow('管理团队成员', AppRole.canManageTeam(user.role)),
        _permRow('查看统计仪表板', AppRole.canViewStats(user.role)),
        _permRow('删除数据', AppRole.canDelete(user.role)),
        _permRow('管理用户权限', AppRole.canAssignRole(user.role)),
      ]),
    );
  }

  Widget _buildMyWorkCard(BuildContext context, LocalUser user) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final myTasks = crm.tasks.where((t) => t.assigneeName == user.name || t.creatorName == user.name).toList();
      final activeTasks = myTasks.where((t) => t.status != 'completed').length;
      final completedTasks = myTasks.where((t) => t.status == 'completed').length;
      final myAssignments = crm.assignments.where((a) => a.memberName == user.name).length;
      final myProductions = crm.productionOrders.where((p) => p.assigneeName == user.name).length;

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
            Expanded(child: _statBox('$activeTasks', '进行中任务', AppTheme.warning)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$completedTasks', '已完成任务', AppTheme.success)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$myAssignments', '跟进人脉', AppTheme.primaryBlue)),
            const SizedBox(width: 8),
            Expanded(child: _statBox('$myProductions', '生产单', const Color(0xFF00CEC9))),
          ]),
        ]),
      );
    });
  }

  Widget _buildActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        _actionTile(Icons.info_outline, '关于 Deal Navigator', () {
          showAboutDialog(
            context: context,
            applicationName: 'Deal Navigator',
            applicationVersion: 'v14.2 (Local Mode)',
            children: [const Text('CRM & 商务管理系统\n纯本地模式，数据保存在内存中。')],
          );
        }),
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
          color: allowed ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 13,
        )),
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

  void _showEditProfile(BuildContext context, LocalUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);

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
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: '电话', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondary))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              setState(() {
                _user.name = nameCtrl.text.trim();
                _user.phone = phoneCtrl.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('资料已更新'), backgroundColor: AppTheme.success),
              );
            },
            child: const Text('保存'),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
