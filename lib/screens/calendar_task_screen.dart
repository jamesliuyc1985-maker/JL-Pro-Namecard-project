import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/crm_provider.dart';
import '../models/task.dart';
import '../models/team.dart';
import '../utils/theme.dart';

class CalendarTaskScreen extends StatefulWidget {
  const CalendarTaskScreen({super.key});
  @override
  State<CalendarTaskScreen> createState() => _CalendarTaskScreenState();
}

class _CalendarTaskScreenState extends State<CalendarTaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusMonth = DateTime.now();

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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(12)),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '日历'), Tab(text: '任务列表'), Tab(text: '工作量')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildCalendarView(crm),
              _buildTaskList(crm),
              _buildWorkloadView(crm),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _buildHeader(BuildContext context, CrmProvider crm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(children: [
        const Icon(Icons.calendar_month, color: AppTheme.warning, size: 24),
        const SizedBox(width: 10),
        const Text('日历与任务', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_task, color: Colors.white, size: 20),
          ),
          onPressed: () => _showAddTaskSheet(context, crm),
        ),
      ]),
    );
  }

  // ========== Calendar View ==========
  Widget _buildCalendarView(CrmProvider crm) {
    final tasks = crm.tasks;
    final dayTasks = crm.getTasksByDate(_selectedDate);

    return Column(children: [
      _buildMiniCalendar(tasks),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text(DateFormat('yyyy年MM月dd日').format(_selectedDate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${dayTasks.length} 个任务', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ),
      Expanded(
        child: dayTasks.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.event_available, color: AppTheme.textSecondary, size: 40),
                SizedBox(height: 8),
                Text('当日无任务', style: TextStyle(color: AppTheme.textSecondary)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dayTasks.length,
                itemBuilder: (context, index) => _taskCard(context, crm, dayTasks[index]),
              ),
      ),
    ]);
  }

  Widget _buildMiniCalendar(List<Task> allTasks) {
    final year = _focusMonth.year;
    final month = _focusMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    // Dates that have tasks
    final taskDates = <int>{};
    for (final t in allTasks) {
      if (t.dueDate.year == year && t.dueDate.month == month) {
        taskDates.add(t.dueDate.day);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 20),
            onPressed: () => setState(() { _focusMonth = DateTime(year, month - 1, 1); }),
          ),
          Text(DateFormat('yyyy年MM月').format(_focusMonth), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
            onPressed: () => setState(() { _focusMonth = DateTime(year, month + 1, 1); }),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: ['日', '月', '火', '水', '木', '金', '土'].map((d) => Expanded(
          child: Center(child: Text(d, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
        )).toList()),
        const SizedBox(height: 4),
        ...List.generate(6, (week) {
          return Row(children: List.generate(7, (dow) {
            final dayIndex = week * 7 + dow - startWeekday + 1;
            if (dayIndex < 1 || dayIndex > daysInMonth) {
              return const Expanded(child: SizedBox(height: 32));
            }
            final date = DateTime(year, month, dayIndex);
            final isSelected = _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
            final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;
            final hasTask = taskDates.contains(dayIndex);

            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                height: 32,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryPurple : (isToday ? AppTheme.primaryPurple.withValues(alpha: 0.15) : null),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(children: [
                  Center(child: Text(
                    '$dayIndex',
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isToday ? AppTheme.primaryPurple : AppTheme.textPrimary),
                      fontSize: 12,
                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  )),
                  if (hasTask) Positioned(
                    bottom: 2, left: 0, right: 0,
                    child: Center(child: Container(width: 4, height: 4, decoration: BoxDecoration(color: isSelected ? Colors.white : AppTheme.accentGold, shape: BoxShape.circle))),
                  ),
                ]),
              ),
            ));
          }));
        }),
      ]),
    );
  }

  // ========== Task List ==========
  Widget _buildTaskList(CrmProvider crm) {
    final tasks = List<Task>.from(crm.tasks)..sort((a, b) {
      if (a.status == 'completed' && b.status != 'completed') { return 1; }
      if (a.status != 'completed' && b.status == 'completed') { return -1; }
      return a.dueDate.compareTo(b.dueDate);
    });

    if (tasks.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.task_alt, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无任务', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _taskCard(context, crm, tasks[index]),
    );
  }

  Widget _taskCard(BuildContext context, CrmProvider crm, Task task) {
    Color priorityColor;
    switch (task.priority) {
      case 'urgent': priorityColor = AppTheme.danger; break;
      case 'high': priorityColor = AppTheme.warning; break;
      case 'medium': priorityColor = AppTheme.primaryBlue; break;
      default: priorityColor = AppTheme.textSecondary; break;
    }
    Color statusColor;
    switch (task.status) {
      case 'in_progress': statusColor = AppTheme.primaryBlue; break;
      case 'completed': statusColor = AppTheme.success; break;
      case 'cancelled': statusColor = AppTheme.danger; break;
      default: statusColor = AppTheme.textSecondary; break;
    }
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != 'completed' && task.status != 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOverdue ? AppTheme.danger.withValues(alpha: 0.5) : priorityColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () {
              task.status = task.status == 'completed' ? 'pending' : 'completed';
              task.updatedAt = DateTime.now();
              crm.updateTask(task);
            },
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: task.status == 'completed' ? AppTheme.success : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: task.status == 'completed' ? AppTheme.success : AppTheme.textSecondary, width: 2),
              ),
              child: task.status == 'completed' ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            task.title,
            style: TextStyle(
              color: task.status == 'completed' ? AppTheme.textSecondary : AppTheme.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 14,
              decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
            ),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(Task.priorityLabel(task.priority), style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 16),
            color: AppTheme.cardBgLight,
            onSelected: (action) {
              switch (action) {
                case 'progress':
                  task.status = 'in_progress';
                  task.updatedAt = DateTime.now();
                  crm.updateTask(task);
                  break;
                case 'delete':
                  crm.deleteTask(task.id);
                  break;
              }
            },
            itemBuilder: (_) => [
              if (task.status == 'pending') const PopupMenuItem(value: 'progress', child: Text('开始', style: TextStyle(color: AppTheme.textPrimary))),
              const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: AppTheme.danger))),
            ],
          ),
        ]),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(task.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Row(children: [
            Icon(Icons.person_outline, color: AppTheme.textSecondary, size: 13),
            const SizedBox(width: 3),
            Text(task.assigneeName.isNotEmpty ? task.assigneeName : '未分配', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(width: 12),
            Icon(Icons.calendar_today, color: isOverdue ? AppTheme.danger : AppTheme.textSecondary, size: 12),
            const SizedBox(width: 3),
            Text(DateFormat('MM/dd').format(task.dueDate), style: TextStyle(color: isOverdue ? AppTheme.danger : AppTheme.textSecondary, fontSize: 11)),
            if (isOverdue) ...[
              const SizedBox(width: 4),
              const Text('逾期', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(Task.statusLabel(task.status), style: TextStyle(color: statusColor, fontSize: 10)),
            ),
            if (task.estimatedHours > 0) ...[
              const SizedBox(width: 8),
              Text('${task.estimatedHours}h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ]),
        ),
      ]),
    );
  }

  // ========== Workload View ==========
  Widget _buildWorkloadView(CrmProvider crm) {
    final workload = crm.workloadStats;
    final members = crm.teamMembers;
    if (workload.isEmpty && members.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无工作量数据', style: TextStyle(color: AppTheme.textSecondary)),
        SizedBox(height: 4),
        Text('添加团队成员和任务后查看统计', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]));
    }

    // Calculate per-member stats
    final memberStats = <String, Map<String, dynamic>>{};
    for (final m in members) {
      final mTasks = crm.getTasksByAssignee(m.id);
      final totalTasks = mTasks.length;
      final completed = mTasks.where((t) => t.status == 'completed').length;
      final active = mTasks.where((t) => t.status != 'completed' && t.status != 'cancelled').length;
      double hours = 0;
      for (final t in mTasks) {
        hours += t.actualHours > 0 ? t.actualHours : t.estimatedHours;
      }
      memberStats[m.id] = {
        'name': m.name,
        'total': totalTasks,
        'completed': completed,
        'active': active,
        'hours': hours,
      };
    }

    final maxHours = memberStats.values.fold<double>(0, (max, s) => (s['hours'] as double) > max ? (s['hours'] as double) : max);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppTheme.gradient, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Column(children: [
              Text('${crm.tasks.length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('总任务', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            Container(width: 1, height: 40, color: Colors.white30),
            Expanded(child: Column(children: [
              Text('${crm.tasks.where((t) => t.status == 'completed').length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('已完成', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            Container(width: 1, height: 40, color: Colors.white30),
            Expanded(child: Column(children: [
              Text('${crm.tasks.where((t) => t.dueDate.isBefore(DateTime.now()) && t.status != 'completed' && t.status != 'cancelled').length}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('逾期', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('成员工作量', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...memberStats.entries.map((entry) {
          final s = entry.value;
          final hours = s['hours'] as double;
          final barWidth = maxHours > 0 ? hours / maxHours : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Text('${hours.toStringAsFixed(1)}h', style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _miniStat('任务', '${s['total']}', AppTheme.primaryBlue),
                const SizedBox(width: 8),
                _miniStat('完成', '${s['completed']}', AppTheme.success),
                const SizedBox(width: 8),
                _miniStat('进行中', '${s['active']}', AppTheme.warning),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barWidth,
                  backgroundColor: AppTheme.cardBgLight,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryPurple),
                  minHeight: 6,
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // ========== Add Task ==========
  void _showAddTaskSheet(BuildContext context, CrmProvider crm) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '1');
    String priority = 'medium';
    String? assigneeId;
    String assigneeName = '';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final members = crm.teamMembers;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('新建任务', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: '任务标题 *', prefixIcon: Icon(Icons.task, color: AppTheme.textSecondary, size: 20))),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 2,
                  decoration: const InputDecoration(labelText: '描述', prefixIcon: Icon(Icons.description, color: AppTheme.textSecondary, size: 20))),
                const SizedBox(height: 10),
                if (members.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: assigneeId,
                    decoration: const InputDecoration(labelText: '分配给', prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary, size: 20)),
                    dropdownColor: AppTheme.cardBgLight,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: members.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${TeamMember.roleLabel(m.role)})', style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setModalState(() {
                      assigneeId = v;
                      assigneeName = members.firstWhere((m) => m.id == v).name;
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text('优先级', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: ['low', 'medium', 'high', 'urgent'].map((p) {
                  Color c;
                  switch (p) {
                    case 'urgent': c = AppTheme.danger; break;
                    case 'high': c = AppTheme.warning; break;
                    case 'medium': c = AppTheme.primaryBlue; break;
                    default: c = AppTheme.textSecondary; break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(Task.priorityLabel(p)),
                      selected: priority == p,
                      onSelected: (_) => setModalState(() => priority = p),
                      selectedColor: c, backgroundColor: AppTheme.cardBgLight,
                      labelStyle: TextStyle(color: priority == p ? Colors.white : AppTheme.textPrimary, fontSize: 11),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList()),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx, initialDate: dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) { setModalState(() => dueDate = picked); }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('yyyy/MM/dd').format(dueDate), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 10),
                  SizedBox(width: 80, child: TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: '工时', suffixText: 'h', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                  )),
                ]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) { return; }
                    crm.addTask(Task(
                      id: crm.generateId(),
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      assigneeId: assigneeId ?? '',
                      assigneeName: assigneeName,
                      creatorId: 'james',
                      creatorName: 'James Liu',
                      priority: priority,
                      dueDate: dueDate,
                      estimatedHours: double.tryParse(hoursCtrl.text) ?? 0,
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('任务已创建: ${titleCtrl.text}'), backgroundColor: AppTheme.success),
                    );
                  },
                  child: const Text('创建任务'),
                )),
                const SizedBox(height: 16),
              ]),
            ),
          );
        });
      },
    );
  }
}
