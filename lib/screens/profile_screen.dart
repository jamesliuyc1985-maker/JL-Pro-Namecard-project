import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/crm_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

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
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 先用 Firebase Auth 本地缓存的信息（零延迟）
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      _appUser = AppUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? 'User',
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

    // 先展示，不等网络
    if (mounted) setState(() => _isLoading = false);

    // 后台尝试从 Firestore 获取更详细的用户信息（带超时）
    try {
      final auth = AuthService();
      final detailedUser = await auth.getCurrentUser()
          .timeout(const Duration(seconds: 4));
      if (detailedUser != null && mounted) {
        setState(() => _appUser = detailedUser);
      }

      // 如果是 admin，后台拉取所有用户
      if (_appUser?.role == UserRole.admin) {
        final users = await auth.getAllUsers()
            .timeout(const Duration(seconds: 4));
        if (mounted) setState(() => _allUsers = users);
      }
    } catch (e) {
      // Firestore 超时，保持已有的本地数据
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final user = _appUser ?? AppUser(uid: 'local', email: 'local@mode', displayName: 'User', role: UserRole.member);
    bool isFirebase;
    try {
      isFirebase = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      isFirebase = false;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(user, isFirebase),
          const SizedBox(height: 20),
          _buildProfileCard(user, isFirebase),
          const SizedBox(height: 16),
          _buildPermissionsCard(user),
          const SizedBox(height: 16),
          _buildMyWorkCard(context, user),
          const SizedBox(height: 16),
          _buildActionsCard(context, isFirebase),
          if (user.role == UserRole.admin && _allUsers.length > 1) ...[
            const SizedBox(height: 16),
            _buildUserManagement(user),
          ],
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

  Widget _buildActionsCard(BuildContext context, bool isFirebase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        if (isFirebase) ...[
          _actionTile(Icons.sync, '同步云端数据', () async {
            setState(() => _syncStatus = '正在同步...');
            try {
              final crm = context.read<CrmProvider>();
              await crm.syncFromCloud().timeout(const Duration(seconds: 8));
              if (mounted) setState(() => _syncStatus = crm.syncStatus ?? '同步成功');
            } catch (e) {
              if (mounted) setState(() => _syncStatus = '同步超时');
            }
          }),
          _actionTile(Icons.lock_outline, '修改密码', () => _showChangePassword(context)),
        ],
        _actionTile(Icons.info_outline, '关于 Deal Navigator', () {
          showAboutDialog(
            context: context,
            applicationName: 'Deal Navigator',
            applicationVersion: isFirebase ? 'v15.1 (Cloud)' : 'v15.1 (Local)',
            children: [Text(isFirebase ? 'CRM & 商务管理系统\nFirebase 云端同步模式' : 'CRM & 商务管理系统\n本地模式')],
          );
        }),
        if (isFirebase && widget.onLogout != null)
          _actionTile(Icons.logout, '退出登录', () => _confirmLogout(context), color: AppTheme.danger),
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
                    await AuthService().updateUserRole(u.uid, role);
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
                await AuthService().updateProfile(user.uid, nameCtrl.text.trim());
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
