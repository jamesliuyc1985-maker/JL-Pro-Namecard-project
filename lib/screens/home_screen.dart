import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'stats_dashboard_screen.dart';
import 'pipeline_screen.dart';
import 'product_inventory_screen.dart';
import 'production_screen.dart';
import 'smart_priority_screen.dart';
import 'contacts_screen.dart';
import 'network_screen.dart';
import 'team_screen.dart';
import 'calendar_task_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const HomeScreen({super.key, this.onLogout});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const StatsDashboardScreen(),
      const PipelineScreen(),
      const ProductInventoryScreen(),
      const ProductionScreen(),
      const SmartPriorityScreen(),
      const ContactsScreen(),
      const NetworkScreen(),
      const TeamScreen(),
      const CalendarTaskScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];
  }

  static const _topRow = [
    _NavDef(0, Icons.bar_chart_rounded, '统计'),
    _NavDef(1, Icons.view_kanban_rounded, '销售'),
    _NavDef(2, Icons.science_outlined, '产品'),
    _NavDef(3, Icons.precision_manufacturing_outlined, '生产'),
    _NavDef(4, Icons.auto_awesome_outlined, '智能'),
  ];

  static const _bottomRow = [
    _NavDef(5, Icons.people_outline, '人脉'),
    _NavDef(6, Icons.hub_outlined, '图谱'),
    _NavDef(7, Icons.group_outlined, '团队'),
    _NavDef(8, Icons.calendar_month_outlined, '任务'),
    _NavDef(9, Icons.person_outline, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _screens[_currentIndex],
        _buildNotificationBell(context),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navy,
          border: Border(top: BorderSide(color: AppTheme.steel.withValues(alpha: 0.3))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: _topRow.map((n) => Expanded(child: _navItem(n))).toList()),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                  height: 1,
                  color: AppTheme.steel.withValues(alpha: 0.15),
                ),
                Row(children: _bottomRow.map((n) => Expanded(child: _navItem(n))).toList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 8,
      child: Consumer<NotificationService>(builder: (context, ns, _) {
        return GestureDetector(
          onTap: () => _showNotificationPanel(context, ns),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.notifications_none, color: AppTheme.slate, size: 22),
              if (ns.unreadCount > 0)
                Positioned(top: -4, right: -4, child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                  child: Text('${ns.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                )),
            ]),
          ),
        );
      }),
    );
  }

  void _showNotificationPanel(BuildContext context, NotificationService ns) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return Consumer<NotificationService>(builder: (context, ns, _) {
          final items = ns.notifications;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Text('通知', style: TextStyle(color: AppTheme.offWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (ns.unreadCount > 0) TextButton(
                    onPressed: () { ns.markAllRead(); },
                    child: const Text('全部已读', style: TextStyle(fontSize: 12)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.slate, size: 20), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text('暂无通知', style: TextStyle(color: AppTheme.slate)))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.steel.withValues(alpha: 0.2)),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(n.icon, color: n.isRead ? AppTheme.slate : n.color, size: 18),
                        title: Text(n.title, style: TextStyle(color: AppTheme.offWhite, fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13)),
                        subtitle: Text(n.body, style: const TextStyle(color: AppTheme.slate, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(Formatters.timeAgo(n.createdAt), style: const TextStyle(color: AppTheme.slate, fontSize: 9)),
                        onTap: () => ns.markRead(n.id),
                      );
                    },
                  ),
                ),
            ]),
          );
        });
      },
    );
  }

  Widget _navItem(_NavDef nav) {
    final isSelected = _currentIndex == nav.index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = nav.index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nav.icon, color: isSelected ? AppTheme.gold : AppTheme.slate, size: 18),
            const SizedBox(height: 2),
            Text(nav.label, style: TextStyle(
              color: isSelected ? AppTheme.gold : AppTheme.slate,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 9,
            )),
            const SizedBox(height: 2),
            // Underline indicator
            Container(
              width: 16, height: 1.5,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDef {
  final int index;
  final IconData icon;
  final String label;
  const _NavDef(this.index, this.icon, this.label);
}
