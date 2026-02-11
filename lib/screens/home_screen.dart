import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'dashboard_screen.dart';
import 'contacts_screen.dart';
import 'pipeline_screen.dart';
import 'network_screen.dart';
import 'product_inventory_screen.dart';
import 'production_screen.dart';
import 'calendar_task_screen.dart';
import 'team_screen.dart';
import 'sales_stats_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),           // 0 首页
    ContactsScreen(),            // 1 人脉
    NetworkScreen(),             // 2 图谱
    PipelineScreen(),            // 3 销售管线
    ProductInventoryScreen(),    // 4 产品&库存
    ProductionScreen(),          // 5 生产
    CalendarTaskScreen(),        // 6 任务
    TeamScreen(),                // 7 团队
    SalesStatsScreen(),          // 8 统计
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _screens[_currentIndex],
        // Notification overlay
        _buildNotificationBell(context),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBg,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, '首页'),
                _navItem(1, Icons.people_rounded, '人脉'),
                _navItem(2, Icons.hub_rounded, '图谱'),
                _navItem(3, Icons.view_kanban_rounded, '管线'),
                _navItem(4, Icons.science_rounded, '产品'),
                _navItem(5, Icons.precision_manufacturing, '生产'),
                _navItem(6, Icons.calendar_month, '任务'),
                _navItem(7, Icons.group_rounded, '团队'),
                _navItem(8, Icons.analytics_rounded, '统计'),
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
        return Row(mainAxisSize: MainAxisSize.min, children: [
          // Notification bell
          GestureDetector(
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
          ),
          // Logout button
          GestureDetector(
            onTap: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => AuthScreen(onAuthenticated: () {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
                  })), (_) => false);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.logout, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 18),
            ),
          ),
        ]);
      }),
    );
  }

  void _showNotificationPanel(BuildContext context, NotificationService ns) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
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
        });
      },
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppTheme.gradient : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 16),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 8,
            )),
          ],
        ),
      ),
    );
  }
}
