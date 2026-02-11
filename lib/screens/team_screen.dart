import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/team.dart';
import '../models/task.dart';
import '../models/contact_assignment.dart';
import '../utils/theme.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final members = crm.teamMembers;
      return SafeArea(
        child: Column(children: [
          _buildHeader(context, crm),
          _buildSummary(crm, members),
          Expanded(child: members.isEmpty ? _buildEmpty() : _buildMemberList(context, crm, members)),
        ]),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Icon(Icons.group, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(width: 10),
        const Text('团队管理', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_add, color: Colors.white, size: 20),
          ),
          onPressed: () => _showAddMemberSheet(context, crm),
        ),
      ]),
    );
  }

  Widget _buildSummary(CrmProvider crm, List<TeamMember> members) {
    final active = members.where((m) => m.isActive).length;
    final totalTasks = crm.tasks.length;
    final totalAssignments = crm.assignments.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _statCard('总成员', '${members.length}', Icons.people, AppTheme.primaryBlue)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('活跃', '$active', Icons.check_circle, AppTheme.success)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('总任务', '$totalTasks', Icons.task_alt, AppTheme.warning)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('跟进', '$totalAssignments', Icons.people_outline, AppTheme.primaryPurple)),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.group_outlined, color: AppTheme.textSecondary, size: 48),
      SizedBox(height: 12),
      Text('暂无团队成员', style: TextStyle(color: AppTheme.textSecondary)),
      SizedBox(height: 4),
      Text('点击右上角 + 添加成员', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]));
  }

  Widget _buildMemberList(BuildContext context, CrmProvider crm, List<TeamMember> members) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) => _memberCard(context, crm, members[index]),
    );
  }

  Widget _memberCard(BuildContext context, CrmProvider crm, TeamMember member) {
    Color roleColor;
    switch (member.role) {
      case 'admin': roleColor = AppTheme.primaryPurple; break;
      case 'manager': roleColor = AppTheme.warning; break;
      default: roleColor = AppTheme.primaryBlue; break;
    }

    final tasks = crm.getTasksByAssignee(member.id);
    final assignments = crm.getAssignmentsByMember(member.id);
    final activeTasks = tasks.where((t) => t.status != 'completed' && t.status != 'cancelled').length;
    final completedTasks = tasks.where((t) => t.status == 'completed').length;

    return GestureDetector(
      onTap: () => _showMemberDetail(context, crm, member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: member.isActive ? roleColor.withValues(alpha: 0.3) : AppTheme.textSecondary.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: member.isActive ? roleColor.withValues(alpha: 0.2) : AppTheme.cardBgLight, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(
                member.name.isNotEmpty ? member.name[0] : '?',
                style: TextStyle(color: member.isActive ? roleColor : AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 20),
              )),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(member.name, style: TextStyle(
                  color: member.isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold, fontSize: 15,
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(TeamMember.roleLabel(member.role), style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                if (!member.isActive) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('停用', style: TextStyle(color: AppTheme.danger, fontSize: 10)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              if (member.email.isNotEmpty) Text(member.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            // 右侧箭头 + 菜单
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
              color: AppTheme.cardBgLight,
              onSelected: (action) {
                switch (action) {
                  case 'edit': _showEditMemberSheet(context, crm, member); break;
                  case 'assign_task': _showAssignTaskSheet(context, crm, member); break;
                  case 'toggle':
                    member.isActive = !member.isActive;
                    crm.updateTeamMember(member);
                    break;
                  case 'delete':
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        title: const Text('删除成员', style: TextStyle(color: AppTheme.textPrimary)),
                        content: Text('确定删除 ${member.name}？', style: const TextStyle(color: AppTheme.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          TextButton(onPressed: () { crm.deleteTeamMember(member.id); Navigator.pop(ctx); }, child: const Text('删除', style: TextStyle(color: AppTheme.danger))),
                        ],
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('编辑', style: TextStyle(color: AppTheme.textPrimary))),
                const PopupMenuItem(value: 'assign_task', child: Text('分配任务', style: TextStyle(color: AppTheme.primaryBlue))),
                PopupMenuItem(value: 'toggle', child: Text(member.isActive ? '停用' : '启用', style: const TextStyle(color: AppTheme.textPrimary))),
                const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: AppTheme.danger))),
              ],
            ),
          ]),
          // 统计摘要行
          const SizedBox(height: 10),
          Row(children: [
            _miniStat(Icons.task_alt, '${tasks.length}任务', activeTasks > 0 ? AppTheme.warning : AppTheme.textSecondary),
            const SizedBox(width: 8),
            _miniStat(Icons.check_circle, '$completedTasks完成', AppTheme.success),
            const SizedBox(width: 8),
            _miniStat(Icons.people_outline, '${assignments.length}人脉', AppTheme.primaryPurple),
          ]),
          // 跟进人脉标签
          if (assignments.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: ListView(scrollDirection: Axis.horizontal, children: assignments.map((a) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(a.contactName, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(a.stage.label, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 8)),
                  ),
                ]),
              )).toList()),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ========== 成员详情 ==========
  void _showMemberDetail(BuildContext context, CrmProvider crm, TeamMember member) {
    final tasks = crm.getTasksByAssignee(member.id);
    final assignments = crm.getAssignmentsByMember(member.id);

    Color roleColor;
    switch (member.role) {
      case 'admin': roleColor = AppTheme.primaryPurple; break;
      case 'manager': roleColor = AppTheme.warning; break;
      default: roleColor = AppTheme.primaryBlue; break;
    }

    final activeTasks = tasks.where((t) => t.status != 'completed' && t.status != 'cancelled').toList();
    final completedTasks = tasks.where((t) => t.status == 'completed').toList();
    double totalHours = 0;
    for (final t in tasks) { totalHours += t.actualHours > 0 ? t.actualHours : t.estimatedHours; }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(member.name.isNotEmpty ? member.name[0] : '?',
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(member.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text(TeamMember.roleLabel(member.role), style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    if (member.email.isNotEmpty) ...[const SizedBox(height: 4), Text(member.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))],
                    if (member.phone.isNotEmpty) Text(member.phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ])),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 16),
                // KPI 行
                Row(children: [
                  Expanded(child: _detailKpi('总任务', '${tasks.length}', AppTheme.primaryBlue)),
                  const SizedBox(width: 8),
                  Expanded(child: _detailKpi('进行中', '${activeTasks.length}', AppTheme.warning)),
                  const SizedBox(width: 8),
                  Expanded(child: _detailKpi('已完成', '${completedTasks.length}', AppTheme.success)),
                  const SizedBox(width: 8),
                  Expanded(child: _detailKpi('工时', '${totalHours.toStringAsFixed(0)}h', const Color(0xFF00CEC9))),
                  const SizedBox(width: 8),
                  Expanded(child: _detailKpi('人脉', '${assignments.length}', AppTheme.primaryPurple)),
                ]),
              ]),
            ),
            const Divider(color: AppTheme.cardBgLight, height: 1),
            // 滚动内容
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
              const SizedBox(height: 16),
              // 跟进人脉
              if (assignments.isNotEmpty) ...[
                _detailSectionTitle('跟进人脉 (${assignments.length})', Icons.people, AppTheme.primaryPurple),
                ...assignments.map((a) => _assignmentItem(a)),
                const SizedBox(height: 16),
              ],
              // 进行中任务
              if (activeTasks.isNotEmpty) ...[
                _detailSectionTitle('进行中任务 (${activeTasks.length})', Icons.pending_actions, AppTheme.warning),
                ...activeTasks.map((t) => _taskItem(t)),
                const SizedBox(height: 16),
              ],
              // 已完成任务
              if (completedTasks.isNotEmpty) ...[
                _detailSectionTitle('已完成任务 (${completedTasks.length})', Icons.check_circle, AppTheme.success),
                ...completedTasks.take(5).map((t) => _taskItem(t)),
                if (completedTasks.length > 5) Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('还有 ${completedTasks.length - 5} 个已完成任务...', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ),
              ],
              // 无任务无人脉
              if (tasks.isEmpty && assignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('该成员暂无任务和跟进人脉', style: TextStyle(color: AppTheme.textSecondary))),
                ),
              const SizedBox(height: 20),
            ])),
          ]),
        );
      },
    );
  }

  Widget _detailKpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _detailSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  Widget _assignmentItem(ContactAssignment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(a.contactName.isNotEmpty ? a.contactName[0] : '?',
            style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.contactName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          if (a.notes.isNotEmpty) Text(a.notes, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _stageColor(a.stage).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(a.stage.label, style: TextStyle(color: _stageColor(a.stage), fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Color _stageColor(ContactWorkStage stage) {
    switch (stage) {
      case ContactWorkStage.lead: return AppTheme.textSecondary;
      case ContactWorkStage.contacted: return AppTheme.primaryBlue;
      case ContactWorkStage.ongoing: return AppTheme.warning;
      case ContactWorkStage.negotiation: return AppTheme.primaryPurple;
      case ContactWorkStage.ordered: return const Color(0xFF00CEC9);
      case ContactWorkStage.closed: return AppTheme.success;
    }
  }

  Widget _taskItem(Task t) {
    Color priorityColor;
    switch (t.priority) {
      case 'urgent': priorityColor = AppTheme.danger; break;
      case 'high': priorityColor = AppTheme.warning; break;
      case 'medium': priorityColor = AppTheme.primaryBlue; break;
      default: priorityColor = AppTheme.textSecondary; break;
    }
    final isCompleted = t.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? null : Border.all(color: priorityColor.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 6, height: 36,
          decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: TextStyle(
            color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 13,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Text('${t.phase.label} | ${Task.priorityLabel(t.priority)}', style: TextStyle(color: priorityColor, fontSize: 10)),
            const SizedBox(width: 8),
            Text('${t.dueDate.month}/${t.dueDate.day}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            if (t.estimatedHours > 0) ...[
              const SizedBox(width: 8),
              Text('${t.estimatedHours.toStringAsFixed(0)}h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ]),
        ])),
      ]),
    );
  }

  // ========== 添加/编辑成员 & 分配任务 (保留原逻辑) ==========
  void _showAddMemberSheet(BuildContext context, CrmProvider crm) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'member';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('添加团队成员', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '姓名 *', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, style: const TextStyle(color: AppTheme.textPrimary), keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '邮箱', prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, style: const TextStyle(color: AppTheme.textPrimary), keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '电话', prefixIcon: Icon(Icons.phone, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 12),
              const Text('角色', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: ['admin', 'manager', 'member'].map((r) {
                Color c;
                switch (r) { case 'admin': c = AppTheme.primaryPurple; break; case 'manager': c = AppTheme.warning; break; default: c = AppTheme.primaryBlue; break; }
                return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                  label: Text(TeamMember.roleLabel(r)), selected: role == r,
                  onSelected: (_) => setModalState(() => role = r),
                  selectedColor: c, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: role == r ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                ));
              }).toList()),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  crm.addTeamMember(TeamMember(id: crm.generateId(), name: nameCtrl.text, email: emailCtrl.text, phone: phoneCtrl.text, role: role));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameCtrl.text} 已加入团队'), backgroundColor: AppTheme.success));
                },
                child: const Text('添加'),
              )),
              const SizedBox(height: 16),
            ]),
          );
        });
      },
    );
  }

  void _showEditMemberSheet(BuildContext context, CrmProvider crm, TeamMember member) {
    final nameCtrl = TextEditingController(text: member.name);
    final emailCtrl = TextEditingController(text: member.email);
    final phoneCtrl = TextEditingController(text: member.phone);
    String role = member.role;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('编辑成员', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '姓名', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '邮箱', prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '电话', prefixIcon: Icon(Icons.phone, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 12),
              Row(children: ['admin', 'manager', 'member'].map((r) {
                Color c;
                switch (r) { case 'admin': c = AppTheme.primaryPurple; break; case 'manager': c = AppTheme.warning; break; default: c = AppTheme.primaryBlue; break; }
                return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                  label: Text(TeamMember.roleLabel(r)), selected: role == r,
                  onSelected: (_) => setModalState(() => role = r),
                  selectedColor: c, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: role == r ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                ));
              }).toList()),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  member.name = nameCtrl.text; member.email = emailCtrl.text;
                  member.phone = phoneCtrl.text; member.role = role;
                  crm.updateTeamMember(member);
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              )),
              const SizedBox(height: 16),
            ]),
          );
        });
      },
    );
  }

  void _showAssignTaskSheet(BuildContext context, CrmProvider crm, TeamMember member) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '1');
    String priority = 'medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.task_alt, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text('分配任务给 ${member.name}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 14),
              TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: '任务标题 *', prefixIcon: Icon(Icons.task, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 2,
                decoration: const InputDecoration(labelText: '描述', prefixIcon: Icon(Icons.description, color: AppTheme.textSecondary, size: 20))),
              const SizedBox(height: 10),
              const Text('优先级', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: ['low', 'medium', 'high', 'urgent'].map((p) {
                Color c;
                switch (p) { case 'urgent': c = AppTheme.danger; break; case 'high': c = AppTheme.warning; break; case 'medium': c = AppTheme.primaryBlue; break; default: c = AppTheme.textSecondary; break; }
                return Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
                  label: Text(Task.priorityLabel(p)), selected: priority == p,
                  onSelected: (_) => setModalState(() => priority = p),
                  selectedColor: c, backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(color: priority == p ? Colors.white : AppTheme.textPrimary, fontSize: 11),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
                ));
              }).toList()),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setModalState(() => dueDate = picked);
                  },
                  child: Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('${dueDate.month}/${dueDate.day}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    ])),
                )),
                const SizedBox(width: 10),
                SizedBox(width: 80, child: TextField(controller: hoursCtrl, keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: '工时', suffixText: 'h', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)))),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.isEmpty) return;
                  crm.addTask(Task(
                    id: crm.generateId(), title: titleCtrl.text, description: descCtrl.text,
                    assigneeId: member.id, assigneeName: member.name,
                    creatorId: 'james', creatorName: 'James Liu',
                    priority: priority, dueDate: dueDate,
                    estimatedHours: double.tryParse(hoursCtrl.text) ?? 0,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已分配任务给 ${member.name}'), backgroundColor: AppTheme.success));
                },
                child: const Text('创建并分配'),
              )),
              const SizedBox(height: 16),
            ])),
          );
        });
      },
    );
  }
}
