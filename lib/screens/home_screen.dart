import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'contacts_screen.dart';
import 'products_screen.dart';
import 'pipeline_screen.dart';
import 'network_screen.dart';
import 'inventory_screen.dart';
import 'calendar_task_screen.dart';
import 'team_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),       // 0 首页
    ContactsScreen(),        // 1 人脉
    NetworkScreen(),         // 2 图谱
    PipelineScreen(),        // 3 管线+销售 (合并)
    ProductsScreen(),        // 4 产品
    InventoryScreen(),       // 5 库存
    CalendarTaskScreen(),    // 6 日历/任务
    TeamScreen(),            // 7 团队
    ToolsScreen(),           // 8 工具
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
                _navItem(5, Icons.warehouse_rounded, '库存'),
                _navItem(6, Icons.calendar_month, '任务'),
                _navItem(7, Icons.group_rounded, '团队'),
                _navItem(8, Icons.build_circle_rounded, '工具'),
              ],
            ),
          ),
        ),
      ),
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
