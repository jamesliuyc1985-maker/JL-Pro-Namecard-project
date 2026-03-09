import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// AI Chat Screen — placeholder (Gemini API removed)
/// 提供静态商务工具和快捷功能
class GeminiChatScreen extends StatelessWidget {
  const GeminiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 22),
          SizedBox(width: 8),
          Text('AI 助手'),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('AI 助手', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AI对话功能需要配置有效的API密钥',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '当前版本已移除内置API Key。\n请在设置中配置您自己的AI API密钥以启用对话功能。',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Quick tools
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('快捷工具', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Expanded(child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _toolCard('产品目录', Icons.science_outlined, const Color(0xFF00B894), '查看完整产品线'),
                _toolCard('客户管理', Icons.people_outlined, const Color(0xFF0984E3), '管理联系人和关系'),
                _toolCard('销售管线', Icons.trending_up_outlined, const Color(0xFF6C5CE7), '跟踪交易进度'),
                _toolCard('库存检测', Icons.inventory_2_outlined, const Color(0xFFE17055), '库存和QC管理'),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Widget _toolCard(String title, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ]),
    );
  }
}
