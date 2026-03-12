import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

/// 15标签完整展示卡片 (ContactDetailScreen用)
/// 按用户需求1~15全部编号显示
class ContactTagsFullCard extends StatelessWidget {
  final Contact contact;
  const ContactTagsFullCard({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 标题行
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryPurple.withValues(alpha: 0.3), AppTheme.primaryBlue.withValues(alpha: 0.2)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.label, color: AppTheme.primaryPurple, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('客户标签', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          // 完成度指示
          _completenessIndicator(),
        ]),
        const SizedBox(height: 10),
        // 国籍 & 覆盖市场 (置顶)
        if (contact.nationality.isNotEmpty || contact.coverageMarkets.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF00CEC9).withValues(alpha: 0.12), const Color(0xFF636E72).withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              if (contact.nationality.isNotEmpty) ...[
                const Icon(Icons.flag, color: Color(0xFF636E72), size: 14),
                const SizedBox(width: 4),
                Text(contact.nationality, style: const TextStyle(color: Color(0xFF636E72), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
              ],
              if (contact.coverageMarkets.isNotEmpty) ...[
                const Icon(Icons.public, color: Color(0xFF00CEC9), size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text('覆盖: ${contact.coverageMarkets}', style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ]),
          ),
        // 15标签网格
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _tagRow(1, '客户名称', contact.name, AppTheme.primaryBlue, Icons.person),
            _tagRow(2, '所在地区', contact.region, const Color(0xFF0984E3), Icons.map),
            _tagRowWidget(3, '主体类型', contact.entityType.label, contact.entityType.color, contact.entityType.icon),
            _tagRow(4, '负责人/联系方式', _contactPersonStr(), const Color(0xFFE17055), Icons.person_outline),
            _tagRowBool(5, '使用过外泌体/NAD+', contact.hasUsedExosome),
            _tagRowAgg(6, '目前在用品牌', _aggBrands(), const Color(0xFF636E72), Icons.branding_watermark),
            _tagRowAgg(7, '月均采购量', _aggVolume(), AppTheme.warning, Icons.data_usage),
            _tagRowAgg(8, '现有采购单价', _aggUnitPrice(), AppTheme.accentGold, Icons.price_change),
            _tagRowAgg(9, '期望主要功效', _aggEffects(), AppTheme.primaryPurple, Icons.auto_awesome),
            _tagRowPotential(10, contact),
            _tagRowBudget(11, contact),
            _tagRow(12, '意向合作模式', contact.coopModeStr, const Color(0xFFE17055), Icons.handshake),
            _tagRowChips(13, '采购决策重点', contact.decisionFactors, AppTheme.primaryPurple),
            _tagRow(14, '可对接行业资源', contact.industryResources, const Color(0xFF00CEC9), Icons.hub),
            _tagRow(15, '其他需求', contact.otherNeeds, AppTheme.textSecondary, Icons.request_page),
          ]),
        ),
      ]),
    );
  }

  String _contactPersonStr() {
    if (contact.contactPerson.isEmpty) return '';
    if (contact.contactPersonPhone.isNotEmpty) {
      return '${contact.contactPerson} (${contact.contactPersonPhone})';
    }
    return contact.contactPerson;
  }

  // === 从 ProductInterest 聚合字段 (#6~#9) ===
  String _aggBrands() {
    // 先从旧contact级别字段取, 再从productInterests聚合
    final fromPI = contact.productInterests
        .where((p) => p.interested && p.currentBrand.isNotEmpty)
        .map((p) => p.currentBrand)
        .toSet()
        .join(', ');
    if (fromPI.isNotEmpty) return fromPI;
    return contact.currentBrands; // 向后兼容
  }

  String _aggVolume() {
    final fromPI = contact.productInterests
        .where((p) => p.interested && p.currentMonthlyVolume.isNotEmpty)
        .map((p) => '${p.productName}:${p.currentMonthlyVolume}')
        .join(', ');
    if (fromPI.isNotEmpty) return fromPI;
    return contact.currentMonthlyVolume;
  }

  String _aggUnitPrice() {
    final fromPI = contact.productInterests
        .where((p) => p.interested && p.currentUnitPrice > 0)
        .map((p) => '${p.productName}:${Formatters.currency(p.currentUnitPrice)}')
        .join(', ');
    if (fromPI.isNotEmpty) return fromPI;
    return contact.currentUnitPrice > 0 ? Formatters.currency(contact.currentUnitPrice) : '';
  }

  String _aggEffects() {
    final fromPI = contact.productInterests
        .where((p) => p.interested && p.desiredEffects.isNotEmpty)
        .map((p) => p.desiredEffects)
        .toSet()
        .join(', ');
    if (fromPI.isNotEmpty) return fromPI;
    return contact.desiredEffects;
  }

  Widget _tagRowAgg(int num, String label, String value, Color color, IconData icon) {
    return _tagRow(num, label, value, color, icon);
  }

  Widget _completenessIndicator() {
    int filled = 0;
    if (contact.name.isNotEmpty) filled++;
    if (contact.region.isNotEmpty) filled++;
    if (contact.entityType != EntityType.other) filled++;
    if (contact.contactPerson.isNotEmpty) filled++;
    if (contact.hasUsedExosome) filled++;
    // #6-9 从产品兴趣聚合
    if (_aggBrands().isNotEmpty) filled++;
    if (_aggVolume().isNotEmpty) filled++;
    if (_aggUnitPrice().isNotEmpty) filled++;
    if (_aggEffects().isNotEmpty) filled++;
    if (contact.totalMonthlyPotential > 0) filled++;
    if (contact.totalMonthlyBudget > 0) filled++;
    if (contact.coopModeStr.isNotEmpty) filled++;
    if (contact.decisionFactors.isNotEmpty) filled++;
    if (contact.industryResources.isNotEmpty) filled++;
    if (contact.otherNeeds.isNotEmpty) filled++;

    final pct = (filled / 15 * 100).round();
    final color = pct >= 80 ? AppTheme.success : pct >= 50 ? AppTheme.warning : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('$filled/15 ($pct%)', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tagRow(int num, String label, String value, Color color, IconData icon) {
    final hasValue = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _numBadge(num, hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Icon(icon, color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 4),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: hasValue ? 1.0 : 0.5), fontSize: 11)),
        ),
        Expanded(
          child: Text(
            hasValue ? value : '--',
            style: TextStyle(
              color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.3),
              fontSize: 12, fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _tagRowWidget(int num, String label, String value, Color color, IconData icon) {
    final isDefault = contact.entityType == EntityType.other;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        _numBadge(num, isDefault ? AppTheme.textSecondary.withValues(alpha: 0.5) : color),
        const SizedBox(width: 6),
        Icon(icon, color: isDefault ? AppTheme.textSecondary.withValues(alpha: 0.4) : color, size: 14),
        const SizedBox(width: 4),
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: isDefault ? 0.5 : 1.0), fontSize: 11))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: isDefault ? 0.05 : 0.15), borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: TextStyle(color: isDefault ? AppTheme.textSecondary.withValues(alpha: 0.4) : color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _tagRowBool(int num, String label, bool value) {
    final color = value ? const Color(0xFF00B894) : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        _numBadge(num, value ? color : color.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Icon(value ? Icons.check_circle : Icons.cancel_outlined, color: value ? color : color.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 4),
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: value ? 1.0 : 0.5), fontSize: 11))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (value ? const Color(0xFF00B894) : AppTheme.danger).withValues(alpha: value ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value ? '是' : '否', style: TextStyle(color: value ? const Color(0xFF00B894) : AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _tagRowPotential(int num, Contact c) {
    final total = c.totalMonthlyPotential;
    final hasValue = total > 0;
    final color = AppTheme.primaryBlue;
    // 展示每个感兴趣产品的月采购量
    final details = c.productInterests.where((p) => p.interested && p.monthlyQty > 0).map((p) => '${p.productName}${p.monthlyQty}瓶').join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _numBadge(num, hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Icon(Icons.trending_up, color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 4),
        SizedBox(width: 80, child: Text('月潜在采购量', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: hasValue ? 1.0 : 0.5), fontSize: 11))),
        Expanded(
          child: Text(
            hasValue ? '$total瓶${details.isNotEmpty ? ' ($details)' : ''}' : '--',
            style: TextStyle(color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.3), fontSize: 12, fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _tagRowBudget(int num, Contact c) {
    final budget = c.totalMonthlyBudget;
    final hasValue = budget > 0;
    final color = AppTheme.accentGold;
    final details = c.productInterests.where((p) => p.interested && p.budgetUnit > 0).map((p) =>
      '${p.productName} ${Formatters.currency(p.budgetUnit)}/瓶'
    ).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _numBadge(num, hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Icon(Icons.account_balance_wallet, color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 4),
        SizedBox(width: 80, child: Text('目标采购预算', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: hasValue ? 1.0 : 0.5), fontSize: 11))),
        Expanded(
          child: Text(
            hasValue ? '月${Formatters.currency(budget)}${details.isNotEmpty ? '\n($details)' : ''}' : '--',
            style: TextStyle(color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.3), fontSize: 12, fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal),
            maxLines: 3, overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _tagRowChips(int num, String label, List<String> values, Color color) {
    final hasValue = values.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _numBadge(num, hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Icon(Icons.checklist, color: hasValue ? color : AppTheme.textSecondary.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 4),
        SizedBox(width: 80, child: Text(label, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: hasValue ? 1.0 : 0.5), fontSize: 11))),
        Expanded(
          child: hasValue
            ? Wrap(spacing: 4, runSpacing: 3, children: values.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(v, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              )).toList())
            : Text('--', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.3), fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _numBadge(int num, Color color) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
      child: Center(child: Text('$num', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
    );
  }
}


/// 人脉列表用的紧凑标签行 (ContactsScreen用)
/// 在联系人卡片中显示最关键的标签摘要
class ContactTagsCompact extends StatelessWidget {
  final Contact contact;
  const ContactTagsCompact({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 4, runSpacing: 3, children: [
      // 国籍
      if (contact.nationality.isNotEmpty)
        _tag(contact.nationality, const Color(0xFF636E72), icon: Icons.flag),
      // #3 主体类型 (非other才显示)
      if (contact.entityType != EntityType.other)
        _tag(contact.entityType.label, contact.entityType.color),
      // 与我关系
      _tag(contact.myRelation.label, contact.myRelation.color),
      // #2 地区
      if (contact.region.isNotEmpty)
        _tag(contact.region, AppTheme.primaryBlue),
      // 覆盖市场
      if (contact.coverageMarkets.isNotEmpty)
        _tag(_truncate(contact.coverageMarkets, 8), const Color(0xFF00CEC9), icon: Icons.public),
      // #5 用过同类
      if (contact.hasUsedExosome)
        _tag('已用同类', const Color(0xFF00B894), icon: Icons.check_circle),
      // #6 在用品牌 (从产品兴趣聚合)
      ..._compactBrands(),
      // #10 月潜在量
      if (contact.totalMonthlyPotential > 0)
        _tag('潜在${contact.totalMonthlyPotential}瓶/月', AppTheme.primaryBlue),
      // #11 月预算
      if (contact.totalMonthlyBudget > 0)
        _tag('预算${Formatters.currency(contact.totalMonthlyBudget)}/月', AppTheme.accentGold),
      // #12 合作模式
      if (contact.coopModeStr.isNotEmpty)
        _tag(_truncate(contact.coopModeStr, 6), const Color(0xFFE17055)),
      // #13 决策重点
      if (contact.decisionFactors.isNotEmpty)
        _tag(contact.decisionFactors.take(2).join('/'), AppTheme.primaryPurple),
      // #14 行业资源
      if (contact.industryResources.isNotEmpty)
        _tag(_truncate(contact.industryResources, 6), const Color(0xFF00CEC9)),
      // 感兴趣产品数
      if (contact.interestedProductCount > 0)
        _tag('${contact.interestedProductCount}产品', const Color(0xFF00B894)),
    ]);
  }

  String _truncate(String s, int max) => s.length > max ? '${s.substring(0, max)}..' : s;

  List<Widget> _compactBrands() {
    final brands = contact.productInterests
        .where((p) => p.interested && p.currentBrand.isNotEmpty)
        .map((p) => p.currentBrand)
        .toSet();
    // 向后兼容: 旧数据在contact级别
    if (brands.isEmpty && contact.currentBrands.isNotEmpty) {
      return [_tag(_truncate(contact.currentBrands, 6), const Color(0xFF636E72))];
    }
    return brands.take(2).map((b) => _tag(_truncate(b, 6), const Color(0xFF636E72))).toList();
  }

  Widget _tag(String text, Color c, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: c, size: 9), const SizedBox(width: 2)],
        Text(text, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
