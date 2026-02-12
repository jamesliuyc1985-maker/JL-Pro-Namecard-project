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
      const StatsDashboardScreen(),       // 0 统计
      const PipelineScreen(),             // 1 销售
      const ProductInventoryScreen(),     // 2 产品
      const ProductionScreen(),           // 3 生产
      const SmartPriorityScreen(),        // 4 智能
      const ContactsScreen(),             // 5 人脉
      const NetworkScreen(),              // 6 图谱
      const TeamScreen(),                 // 7 团队
      const CalendarTaskScreen(),         // 8 任务
      ProfileScreen(onLogout: widget.onLogout), // 9 我的
    ];
  }

  // 上行导航项 (业务线)
  static const _topRow = [
    _NavDef(0, Icons.analytics_rounded, '统计'),
    _NavDef(1, Icons.view_kanban_rounded, '销售'),
    _NavDef(2, Icons.science_rounded, '产品'),
    _NavDef(3, Icons.precision_manufacturing, '生产'),
    _NavDef(4, Icons.auto_awesome, '智能'),
  ];

  // 下行导航项 (管理线 + 我的)
  static const _bottomRow = [
    _NavDef(5, Icons.people_rounded, '人脉'),
    _NavDef(6, Icons.hub_rounded, '图谱'),
    _NavDef(7, Icons.group_rounded, '团队'),
    _NavDef(8, Icons.calendar_month, '任务'),
    _NavDef(9, Icons.person_rounded, '我的'),
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
          color: AppTheme.darkBg,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: _topRow.map((n) => Expanded(child: _navItem(n))).toList(),
                ),
                const SizedBox(height: 2),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 0.5,
                  color: AppTheme.textSecondary.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 2),
                Row(
                  children: _bottomRow.map((n) => Expanded(child: _navItem(n))).toList(),
                ),
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
              Icon(Icons.notifications_none, color: AppTheme.textSecondary.withValues(alpha: 0.6), size: 22),
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
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer<NotificationService>(builder: (context, ns, _) {
          final items = ns.notifications;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.notifications, color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 8),
                  const Text('通知中心', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (ns.unreadCount > 0) TextButton(
                    onPressed: () { ns.markAllRead(); },
                    child: const Text('全部已读', style: TextStyle(fontSize: 12)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text('暂无通知', style: TextStyle(color: AppTheme.textSecondary)))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return GestureDetector(
                        onTap: () { ns.markRead(n.id); },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: n.isRead ? AppTheme.cardBgLight : n.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: n.isRead ? null : Border.all(color: n.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: n.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Icon(n.icon, color: n.color, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n.title, style: TextStyle(color: AppTheme.textPrimary, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(n.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ])),
                            Text(Formatters.timeAgo(n.createdAt), style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 9)),
                          ]),
                        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected ? LinearGradient(
            colors: [AppTheme.brandDarkRed, AppTheme.brandGold],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nav.icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 17),
            const SizedBox(height: 2),
            Text(nav.label, style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 9,
            )),
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
