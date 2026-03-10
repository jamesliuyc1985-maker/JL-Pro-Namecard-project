import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/product.dart';
import 'theme.dart';
import 'formatters.dart';

/// 统一的客户→价格档映射工具
/// 规则: myRelation > entityType > coopMode > 默认retail
class PricingUtils {
  /// 根据联系人属性自动推断价格档: agent / clinic / retail
  static String contactToPriceType(Contact c) {
    // 1) myRelation 优先
    if (c.myRelation == MyRelationType.agent) return 'agent';
    if (c.myRelation == MyRelationType.clinic) return 'clinic';
    if (c.myRelation == MyRelationType.retailer) return 'retail';

    // 2) entityType 次之
    if (c.entityType == EntityType.clinic || c.entityType == EntityType.medAesthetic) return 'clinic';
    if (c.entityType == EntityType.distributor || c.entityType == EntityType.daigou) return 'agent';

    // 3) coopMode 再次
    if (c.coopModeStr.contains('代理') || c.coopModeStr.contains('批发')) return 'agent';
    if (c.coopModeStr.contains('代购')) return 'agent';

    // 4) 默认零售
    return 'retail';
  }

  /// 价格档日文标签
  static String priceTypeLabel(String pt) {
    switch (pt) {
      case 'agent': return '代理店価格';
      case 'clinic': return '医療機関価格';
      case 'retail': return '通常販売価格';
      default: return '通常販売価格';
    }
  }

  /// 价格档中文标签
  static String priceTypeLabelCn(String pt) {
    switch (pt) {
      case 'agent': return '代理价';
      case 'clinic': return '诊所价';
      case 'retail': return '零售价';
      default: return '零售价';
    }
  }

  /// 价格档颜色
  static Color priceTypeColor(String pt) {
    switch (pt) {
      case 'agent': return const Color(0xFF00B894);
      case 'clinic': return const Color(0xFF0984E3);
      case 'retail': return AppTheme.accentGold;
      default: return AppTheme.accentGold;
    }
  }

  /// 获取单品单价
  static double getUnitPrice(Product p, String priceType) {
    switch (priceType) {
      case 'agent': return p.agentPrice;
      case 'clinic': return p.clinicPrice;
      default: return p.retailPrice;
    }
  }

  /// 获取套价(箱价)
  static double getBoxPrice(Product p, String priceType) {
    switch (priceType) {
      case 'agent': return p.agentTotalPrice;
      case 'clinic': return p.clinicTotalPrice;
      default: return p.retailTotalPrice;
    }
  }

  /// 客户选择下拉项: 显示名称 + 公司 + [价格档标签]
  static String contactDropdownLabel(Contact c) {
    final pt = contactToPriceType(c);
    final ptLabel = priceTypeLabelCn(pt);
    final entity = c.entityType != EntityType.other ? ' (${c.entityType.label})' : '';
    final region = c.region.isNotEmpty ? ' ${c.region}' : '';
    return '${c.name}$entity$region - ${c.company} [$ptLabel]';
  }

  /// 自动匹配价格档 提示条 Widget
  static Widget priceTypeBanner(String priceType, Product? singleProduct) {
    final color = priceTypeColor(priceType);
    final label = priceTypeLabel(priceType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.price_check, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('自动匹配: $label', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            if (singleProduct != null)
              Text('${Formatters.currency(getUnitPrice(singleProduct, priceType))}/瓶',
                style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(priceTypeLabelCn(priceType), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  /// 客户业务标签行 Widget (选客户后在下单界面展示关键信息)
  static Widget contactBusinessTags(Contact c) {
    final tags = <_TagInfo>[];
    // 主体类型
    if (c.entityType != EntityType.other) {
      tags.add(_TagInfo(c.entityType.label, c.entityType.color));
    }
    // 地区
    if (c.region.isNotEmpty) {
      tags.add(_TagInfo(c.region, const Color(0xFF74B9FF)));
    }
    // 合作模式
    if (c.coopModeStr.isNotEmpty) {
      tags.add(_TagInfo(c.coopModeStr, const Color(0xFF6C5CE7)));
    }
    // 是否用过同类产品
    if (c.hasUsedExosome) {
      tags.add(_TagInfo('已用过同类', const Color(0xFF00B894)));
    }
    // 感兴趣产品数
    if (c.interestedProductCount > 0) {
      tags.add(_TagInfo('${c.interestedProductCount}个感兴趣产品', AppTheme.accentGold));
    }
    // 月预算
    if (c.totalMonthlyBudget > 0) {
      tags.add(_TagInfo('月预算${Formatters.currency(c.totalMonthlyBudget)}', AppTheme.warning));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Wrap(
        spacing: 4, runSpacing: 4,
        children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: t.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(t.label, style: TextStyle(color: t.color, fontSize: 9, fontWeight: FontWeight.w600)),
        )).toList(),
      ),
    );
  }
}

class _TagInfo {
  final String label;
  final Color color;
  _TagInfo(this.label, this.color);
}
