import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../providers/crm_provider.dart';
import '../utils/formatters.dart';
import 'download_helper.dart';

/// 人脉数据完整Excel导出 (5个Sheet全维度)
class ContactExcelExporter {
  static void export(CrmProvider crm) {
    final excel = Excel.createExcel();
    final dtFmt = DateFormat('yyyy-MM-dd HH:mm');

    // ============ Sheet 1: 人脉总表 ============
    final mainSheet = 'contacts';
    excel.rename(excel.getDefaultSheet()!, mainSheet);
    final s1 = excel[mainSheet];

    // 表头 — 全量字段
    final headers = [
      'ID', '客户名称', '读音/拼音', '公司/机构', '职位',
      '电话', '邮箱', '地址',
      '国籍', '覆盖市场', '所在地区',
      '行业', '与我关系', '关系强度', '主体类型', '价格档',
      '负责人', '负责人电话', '是否用过同类产品',
      '意向合作模式', '采购决策重点',
      '可对接行业资源', '其他需求',
      '引荐人', '自定义标签',
      // 聚合数据
      '感兴趣产品数', '月潜在采购总量(瓶)', '月度总预算(¥)',
      // 逐产品聚合摘要
      '在用品牌(聚合)', '现有月均量(聚合)', '现有单价(聚合)', '期望功效(聚合)',
      '创建时间', '最后联系时间', '备注',
    ];
    _writeHeaderRow(s1, headers, '#4472C4');

    // 数据行
    final contacts = crm.allContacts;
    for (var r = 0; r < contacts.length; r++) {
      final c = contacts[r];
      final row = r + 1;
      final vals = <dynamic>[
        c.id,
        c.name,
        c.nameReading,
        c.company,
        c.position,
        c.phone,
        c.email,
        c.address,
        c.nationality,
        c.coverageMarkets,
        c.region,
        c.industry.label,
        c.myRelation.label,
        c.strength.label,
        c.entityType.label,
        _priceTypeLabel(crm, c),
        c.contactPerson,
        c.contactPersonPhone,
        c.hasUsedExosome ? '是' : '否',
        c.coopModeStr,
        c.decisionFactors.join(', '),
        c.industryResources,
        c.otherNeeds,
        c.referredBy,
        c.tags.join(', '),
        c.interestedProductCount,
        c.totalMonthlyPotential,
        c.totalMonthlyBudget,
        _aggBrands(c),
        _aggVolume(c),
        _aggUnitPrice(c),
        _aggEffects(c),
        dtFmt.format(c.createdAt),
        dtFmt.format(c.lastContactedAt),
        c.notes,
      ];
      _writeDataRow(s1, row, vals);
    }

    // ============ Sheet 2: 各产品需求明细 ============
    const piSheet = 'product_interests';
    excel.copy(mainSheet, piSheet);
    final s2 = excel[piSheet];
    _clearSheet(s2);

    final piHeaders = [
      '客户名称', '公司', '国籍', '主体类型', '与我关系', '价格档',
      '产品名称', '是否感兴趣',
      '现用品牌', '现有月均量', '现有采购单价(¥)', '期望主要功效',
      '月潜在采购量(瓶)', '目标单价(¥)', '月度预算(¥)', '备注',
    ];
    _writeHeaderRow(s2, piHeaders, '#00B894');

    var piRow = 1;
    for (final c in contacts) {
      for (final pi in c.productInterests) {
        if (!pi.interested) continue;
        final vals = <dynamic>[
          c.name, c.company, c.nationality, c.entityType.label,
          c.myRelation.label, _priceTypeLabel(crm, c),
          pi.productName, '是',
          pi.currentBrand, pi.currentMonthlyVolume,
          pi.currentUnitPrice > 0 ? pi.currentUnitPrice : '',
          pi.desiredEffects,
          pi.monthlyQty > 0 ? pi.monthlyQty : '',
          pi.budgetUnit > 0 ? pi.budgetUnit : '',
          pi.budgetMonthly > 0 ? pi.budgetMonthly : '',
          pi.notes,
        ];
        _writeDataRow(s2, piRow, vals);
        piRow++;
      }
    }

    // ============ Sheet 3: 人脉关系网络 ============
    const relSheet = 'relations';
    excel.copy(mainSheet, relSheet);
    final s3 = excel[relSheet];
    _clearSheet(s3);

    final relHeaders = [
      '关系ID', '人脉A', '人脉B', '关系类型', '关系强度',
      '双向/单向', '描述', '标签', '创建时间',
    ];
    _writeHeaderRow(s3, relHeaders, '#E17055');

    final relations = crm.relations;
    for (var r = 0; r < relations.length; r++) {
      final rel = relations[r];
      final vals = <dynamic>[
        rel.id, rel.fromName, rel.toName, rel.relationType,
        rel.strength.label, rel.isBidirectional ? '双向' : '单向',
        rel.description, rel.tags.join(', '), dtFmt.format(rel.createdAt),
      ];
      _writeDataRow(s3, r + 1, vals);
    }

    // ============ Sheet 4: 客户指派 ============
    const assignSheet = 'assignments';
    excel.copy(mainSheet, assignSheet);
    final s4 = excel[assignSheet];
    _clearSheet(s4);

    final assignHeaders = ['客户', '负责成员', '工作阶段', '备注', '指派时间', '更新时间'];
    _writeHeaderRow(s4, assignHeaders, '#6C5CE7');

    final assigns = crm.assignments;
    for (var r = 0; r < assigns.length; r++) {
      final a = assigns[r];
      final vals = <dynamic>[
        a.contactName, a.memberName, a.stage.label, a.notes,
        dtFmt.format(a.createdAt), dtFmt.format(a.updatedAt),
      ];
      _writeDataRow(s4, r + 1, vals);
    }

    // ============ Sheet 5: 互动记录 ============
    const interSheet = 'interactions';
    excel.copy(mainSheet, interSheet);
    final s5 = excel[interSheet];
    _clearSheet(s5);

    final interHeaders = ['客户名称', '互动类型', '标题', '日期', '备注', '关联交易ID'];
    _writeHeaderRow(s5, interHeaders, '#0984E3');

    final allInteractions = crm.interactions;
    for (var r = 0; r < allInteractions.length; r++) {
      final inter = allInteractions[r];
      final vals = <dynamic>[
        inter.contactName, inter.type.label, inter.title,
        dtFmt.format(inter.date), inter.notes, inter.dealId ?? '',
      ];
      _writeDataRow(s5, r + 1, vals);
    }

    // === 导出 ===
    final bytes = excel.save();
    if (bytes != null) {
      final fileName = 'CRM_人脉导出_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      downloadExcelWeb(fileName, Uint8List.fromList(bytes));
    }
  }

  // ========== 辅助方法 ==========

  static void _writeHeaderRow(Sheet sheet, List<String> headers, String bgHex) {
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle =
          CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString(bgHex),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          );
    }
  }

  static void _writeDataRow(Sheet sheet, int row, List<dynamic> vals) {
    for (var i = 0; i < vals.length; i++) {
      final v = vals[i];
      if (v is int) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value = IntCellValue(v);
      } else if (v is double) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value = DoubleCellValue(v);
      } else {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value = TextCellValue(v.toString());
      }
    }
  }

  static void _clearSheet(Sheet sheet) {
    for (var r = sheet.maxRows - 1; r >= 0; r--) {
      for (var c = sheet.maxColumns - 1; c >= 0; c--) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value = null;
      }
    }
  }

  // === 聚合函数: 从 ProductInterest 级别汇总到联系人级别 ===
  static String _aggBrands(Contact c) {
    final fromPI = c.productInterests
        .where((p) => p.interested && p.currentBrand.isNotEmpty)
        .map((p) => '${p.productName}:${p.currentBrand}')
        .join('; ');
    if (fromPI.isNotEmpty) return fromPI;
    return c.currentBrands; // 向后兼容
  }

  static String _aggVolume(Contact c) {
    final fromPI = c.productInterests
        .where((p) => p.interested && p.currentMonthlyVolume.isNotEmpty)
        .map((p) => '${p.productName}:${p.currentMonthlyVolume}')
        .join('; ');
    if (fromPI.isNotEmpty) return fromPI;
    return c.currentMonthlyVolume;
  }

  static String _aggUnitPrice(Contact c) {
    final fromPI = c.productInterests
        .where((p) => p.interested && p.currentUnitPrice > 0)
        .map((p) => '${p.productName}:${Formatters.currency(p.currentUnitPrice)}')
        .join('; ');
    if (fromPI.isNotEmpty) return fromPI;
    return c.currentUnitPrice > 0 ? Formatters.currency(c.currentUnitPrice) : '';
  }

  static String _aggEffects(Contact c) {
    final fromPI = c.productInterests
        .where((p) => p.interested && p.desiredEffects.isNotEmpty)
        .map((p) => p.desiredEffects)
        .toSet()
        .join('; ');
    if (fromPI.isNotEmpty) return fromPI;
    return c.desiredEffects;
  }

  static String _priceTypeLabel(CrmProvider crm, Contact c) {
    final rel = c.myRelation;
    if (rel == MyRelationType.agent) return '代理价';
    if (rel == MyRelationType.clinic) return '诊所价';
    if (rel == MyRelationType.retailer) return '零售价';
    if (c.entityType == EntityType.tier1Agent || c.entityType == EntityType.tier2Agent) return '代理价';
    if (c.entityType == EntityType.distributor || c.entityType == EntityType.daigou) return '代理价';
    if (c.entityType == EntityType.clinic || c.entityType == EntityType.medAesthetic) return '诊所价';
    return '零售价';
  }
}
