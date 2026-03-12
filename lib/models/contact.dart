import 'package:flutter/material.dart';

enum Industry {
  finance('金融', Icons.account_balance, Color(0xFF6C5CE7)),
  realEstate('地产', Icons.apartment, Color(0xFF0984E3)),
  healthcare('医疗', Icons.local_hospital, Color(0xFFE17055)),
  consulting('咨询', Icons.psychology, Color(0xFF00B894)),
  foodBeverage('餐饮', Icons.restaurant, Color(0xFFFDAA5B)),
  construction('建设', Icons.construction, Color(0xFF636E72)),
  technology('科技', Icons.computer, Color(0xFF74B9FF)),
  trading('贸易', Icons.public, Color(0xFFFF7675)),
  legal('法律', Icons.gavel, Color(0xFFA29BFE)),
  other('其他', Icons.business, Color(0xFFDFE6E9));

  final String label;
  final IconData icon;
  final Color color;
  const Industry(this.label, this.icon, this.color);
}

enum RelationshipStrength {
  hot('核心', Colors.red, 3),
  warm('密切', Colors.orange, 2),
  cool('一般', Colors.blue, 1),
  cold('浅交', Colors.grey, 0);

  final String label;
  final Color color;
  final int value;
  const RelationshipStrength(this.label, this.color, this.value);
}

/// 与我的关系类型
enum MyRelationType {
  partner('合伙人', Color(0xFFE17055)),
  client('客户', Color(0xFF0984E3)),
  investor('投资方', Color(0xFF6C5CE7)),
  advisor('顾问', Color(0xFF00B894)),
  supplier('供应商', Color(0xFFFDAA5B)),
  agent('代理商', Color(0xFFFF6348)),
  clinic('诊所', Color(0xFF1ABC9C)),
  retailer('零售商', Color(0xFFE056A0)),
  friend('朋友', Color(0xFF74B9FF)),
  referral('被推荐人', Color(0xFFA29BFE)),
  colleague('同事/同行', Color(0xFF636E72)),
  other('其他', Color(0xFFDFE6E9));

  final String label;
  final Color color;
  const MyRelationType(this.label, this.color);

  /// 是否属于医疗产品业务渠道
  bool get isMedChannel => this == agent || this == clinic || this == retailer;
}

// ========== 主体类型 ==========
enum EntityType {
  medAesthetic('医美机构', Icons.spa, Color(0xFFE17055)),
  clinic('诊所', Icons.local_hospital, Color(0xFF1ABC9C)),
  tier1Agent('一级代理', Icons.star, Color(0xFFFF6348)),
  tier2Agent('二级代理', Icons.star_half, Color(0xFFFFA502)),
  daigou('代购', Icons.shopping_bag, Color(0xFF6C5CE7)),
  distributor('经销商', Icons.store, Color(0xFF0984E3)),
  personal('个人', Icons.person, Color(0xFF74B9FF)),
  other('其他', Icons.business, Color(0xFFDFE6E9));

  final String label;
  final IconData icon;
  final Color color;
  const EntityType(this.label, this.icon, this.color);
}

// ========== 意向合作模式 ==========
enum CoopMode {
  wholesale('批发', Color(0xFFE17055)),
  daigou('代购', Color(0xFF6C5CE7)),
  agency('代理', Color(0xFF0984E3)),
  retail('零售', Color(0xFF00B894)),
  other('其他', Color(0xFFDFE6E9));

  final String label;
  final Color color;
  const CoopMode(this.label, this.color);
}

// ========== 单产品兴趣 (含品牌/用量/单价/功效等逐产品维度) ==========
class ProductInterest {
  String productId;    // 关联产品ID (prod-exo-001等)
  String productName;  // 产品名称 (冗余存储方便展示)
  bool interested;     // 是否感兴趣
  int monthlyQty;      // 月潜在采购量(瓶)
  double budgetUnit;   // 目标单价预算(日元)
  double budgetMonthly;// 月度预算(日元)
  String notes;        // 单产品备注
  // === v26.3: 从Contact级别合并到逐产品级别 ===
  String currentBrand;         // 该产品目前在用品牌
  String currentMonthlyVolume; // 该产品现有月均采购/使用量
  double currentUnitPrice;     // 该产品现有采购单价(日元)
  String desiredEffects;       // 该产品期望主要功效

  ProductInterest({
    required this.productId,
    required this.productName,
    this.interested = false,
    this.monthlyQty = 0,
    this.budgetUnit = 0,
    this.budgetMonthly = 0,
    this.notes = '',
    this.currentBrand = '',
    this.currentMonthlyVolume = '',
    this.currentUnitPrice = 0,
    this.desiredEffects = '',
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'interested': interested,
    'monthlyQty': monthlyQty,
    'budgetUnit': budgetUnit,
    'budgetMonthly': budgetMonthly,
    'notes': notes,
    'currentBrand': currentBrand,
    'currentMonthlyVolume': currentMonthlyVolume,
    'currentUnitPrice': currentUnitPrice,
    'desiredEffects': desiredEffects,
  };

  factory ProductInterest.fromJson(Map<String, dynamic> json) => ProductInterest(
    productId: json['productId'] as String? ?? '',
    productName: json['productName'] as String? ?? '',
    interested: json['interested'] as bool? ?? false,
    monthlyQty: (json['monthlyQty'] as num?)?.toInt() ?? 0,
    budgetUnit: (json['budgetUnit'] as num?)?.toDouble() ?? 0,
    budgetMonthly: (json['budgetMonthly'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String? ?? '',
    currentBrand: json['currentBrand'] as String? ?? '',
    currentMonthlyVolume: json['currentMonthlyVolume'] as String? ?? '',
    currentUnitPrice: (json['currentUnitPrice'] as num?)?.toDouble() ?? 0,
    desiredEffects: json['desiredEffects'] as String? ?? '',
  );
}

class Contact {
  final String id;
  String name;
  String nameReading;
  String company;
  String position;
  String phone;
  String email;
  String address;
  Industry industry;
  RelationshipStrength strength;
  MyRelationType myRelation;
  String notes;
  String referredBy;
  DateTime createdAt;
  DateTime lastContactedAt;
  List<String> tags;
  String? avatarUrl;
  String? businessCategory; // agent, clinic, retail
  String nationality; // 国籍

  // ========== 新增: 业务画像字段 ==========
  String region;                // 2. 所在地区
  EntityType entityType;        // 3. 主体类型
  String contactPerson;         // 4. 负责人(如果与name不同)
  String contactPersonPhone;    // 4. 负责人联系方式
  bool hasUsedExosome;          // 5. 是否使用过外泌体/NAD+等同类产品
  String currentBrands;         // 6. 目前在用产品品牌
  String currentMonthlyVolume;  // 7. 现有月均采购/使用量
  double currentUnitPrice;      // 8. 现有采购单价(日元)
  String desiredEffects;        // 9. 期望外泌体主要功效
  String coopModeStr;           // 12. 意向合作模式(存字符串允许多选)
  List<String> decisionFactors; // 13. 采购决策重点(价格/效果/合规等)
  String industryResources;     // 14. 可对接的行业资源
  String otherNeeds;            // 15. 其他需求
  String coverageMarkets;       // 覆盖市场(日本/中国/东南亚等)

  // ========== 新增: 逐产品兴趣 (覆盖需求10/11/15中的具体量) ==========
  List<ProductInterest> productInterests;

  Contact({
    required this.id,
    required this.name,
    this.nameReading = '',
    required this.company,
    this.position = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.industry = Industry.other,
    this.strength = RelationshipStrength.cool,
    this.myRelation = MyRelationType.other,
    this.notes = '',
    this.referredBy = '',
    DateTime? createdAt,
    DateTime? lastContactedAt,
    List<String>? tags,
    this.avatarUrl,
    this.businessCategory,
    this.nationality = '',
    // 新增字段默认值
    this.region = '',
    this.entityType = EntityType.other,
    this.contactPerson = '',
    this.contactPersonPhone = '',
    this.hasUsedExosome = false,
    this.currentBrands = '',
    this.currentMonthlyVolume = '',
    this.currentUnitPrice = 0,
    this.desiredEffects = '',
    this.coopModeStr = '',
    List<String>? decisionFactors,
    this.industryResources = '',
    this.otherNeeds = '',
    this.coverageMarkets = '',
    List<ProductInterest>? productInterests,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastContactedAt = lastContactedAt ?? DateTime.now(),
        tags = tags ?? [],
        decisionFactors = decisionFactors ?? [],
        productInterests = productInterests ?? [];

  // === 便利 getter ===
  /// 月潜在采购总量(所有感兴趣产品)
  int get totalMonthlyPotential =>
      productInterests.where((p) => p.interested).fold(0, (s, p) => s + p.monthlyQty);

  /// 月度总预算
  double get totalMonthlyBudget =>
      productInterests.where((p) => p.interested).fold(0.0, (s, p) => s + p.budgetMonthly);

  /// 感兴趣的产品数量
  int get interestedProductCount =>
      productInterests.where((p) => p.interested).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameReading': nameReading,
        'company': company,
        'position': position,
        'phone': phone,
        'email': email,
        'address': address,
        'industry': industry.name,
        'strength': strength.name,
        'myRelation': myRelation.name,
        'notes': notes,
        'referredBy': referredBy,
        'createdAt': createdAt.toIso8601String(),
        'lastContactedAt': lastContactedAt.toIso8601String(),
        'tags': tags,
        'avatarUrl': avatarUrl,
        'businessCategory': businessCategory,
        'nationality': nationality,
        // 新增字段
        'region': region,
        'entityType': entityType.name,
        'contactPerson': contactPerson,
        'contactPersonPhone': contactPersonPhone,
        'hasUsedExosome': hasUsedExosome,
        'currentBrands': currentBrands,
        'currentMonthlyVolume': currentMonthlyVolume,
        'currentUnitPrice': currentUnitPrice,
        'desiredEffects': desiredEffects,
        'coopModeStr': coopModeStr,
        'decisionFactors': decisionFactors,
        'industryResources': industryResources,
        'otherNeeds': otherNeeds,
        'coverageMarkets': coverageMarkets,
        'productInterests': productInterests.map((p) => p.toJson()).toList(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        nameReading: json['nameReading'] as String? ?? '',
        company: json['company'] as String,
        position: json['position'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        industry: Industry.values.firstWhere(
          (e) => e.name == json['industry'],
          orElse: () => Industry.other,
        ),
        strength: RelationshipStrength.values.firstWhere(
          (e) => e.name == json['strength'],
          orElse: () => RelationshipStrength.cool,
        ),
        myRelation: MyRelationType.values.firstWhere(
          (e) => e.name == json['myRelation'],
          orElse: () => MyRelationType.other,
        ),
        notes: json['notes'] as String? ?? '',
        referredBy: json['referredBy'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        lastContactedAt:
            DateTime.tryParse(json['lastContactedAt'] ?? '') ?? DateTime.now(),
        tags: List<String>.from(json['tags'] ?? []),
        avatarUrl: json['avatarUrl'] as String?,
        businessCategory: json['businessCategory'] as String?,
        nationality: json['nationality'] as String? ?? '',
        // 新增字段
        region: json['region'] as String? ?? '',
        entityType: EntityType.values.firstWhere(
          (e) => e.name == json['entityType'],
          orElse: () => EntityType.other,
        ),
        contactPerson: json['contactPerson'] as String? ?? '',
        contactPersonPhone: json['contactPersonPhone'] as String? ?? '',
        hasUsedExosome: json['hasUsedExosome'] as bool? ?? false,
        currentBrands: json['currentBrands'] as String? ?? '',
        currentMonthlyVolume: json['currentMonthlyVolume'] as String? ?? '',
        currentUnitPrice: (json['currentUnitPrice'] as num?)?.toDouble() ?? 0,
        desiredEffects: json['desiredEffects'] as String? ?? '',
        coopModeStr: json['coopModeStr'] as String? ?? '',
        decisionFactors: List<String>.from(json['decisionFactors'] ?? []),
        industryResources: json['industryResources'] as String? ?? '',
        otherNeeds: json['otherNeeds'] as String? ?? '',
        coverageMarkets: json['coverageMarkets'] as String? ?? '',
        productInterests: (json['productInterests'] as List?)
            ?.map((p) => ProductInterest.fromJson(p as Map<String, dynamic>))
            .toList() ?? [],
      );
}

/// 关系强度
enum RelationStrength {
  strong('紧密', Color(0xFFE17055), 3),
  normal('一般', Color(0xFF74B9FF), 2),
  weak('疏远', Color(0xFF636E72), 1);

  final String label;
  final Color color;
  final int value;
  const RelationStrength(this.label, this.color, this.value);
}

/// 联系人之间的关系
class ContactRelation {
  final String id;
  String fromContactId;
  String toContactId;
  String fromName;
  String toName;
  String relationType;
  RelationStrength strength;
  bool isBidirectional;
  String description;
  List<String> tags;
  DateTime createdAt;

  ContactRelation({
    required this.id,
    required this.fromContactId,
    required this.toContactId,
    required this.fromName,
    required this.toName,
    required this.relationType,
    this.strength = RelationStrength.normal,
    this.isBidirectional = true,
    this.description = '',
    List<String>? tags,
    DateTime? createdAt,
  }) : tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromContactId': fromContactId,
        'toContactId': toContactId,
        'fromName': fromName,
        'toName': toName,
        'relationType': relationType,
        'strength': strength.name,
        'isBidirectional': isBidirectional,
        'description': description,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ContactRelation.fromJson(Map<String, dynamic> json) =>
      ContactRelation(
        id: json['id'] as String,
        fromContactId: json['fromContactId'] as String,
        toContactId: json['toContactId'] as String,
        fromName: json['fromName'] as String? ?? '',
        toName: json['toName'] as String? ?? '',
        relationType: json['relationType'] as String? ?? '',
        strength: RelationStrength.values.firstWhere(
          (e) => e.name == json['strength'], orElse: () => RelationStrength.normal,
        ),
        isBidirectional: json['isBidirectional'] as bool? ?? true,
        description: json['description'] as String? ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  static const List<String> presetRelationTypes = [
    '合伙人', '客户-供应商', '同行/同业', '上下级', '校友',
    '朋友', '家族/亲属', '投资人-创业者', '介绍人-被介绍人', '导师-学生',
    '渠道伙伴', '竞争对手', '行业协会',
  ];

  static const List<String> presetTags = [
    '商业伙伴', '私人关系', '上下游', '竞争对手', '投资关系',
    '引荐人', '校友', '同事', '家族', '行业联盟',
  ];

  static Color tagColor(String tag) {
    switch (tag) {
      case '商业伙伴': return const Color(0xFF0984E3);
      case '私人关系': return const Color(0xFFE17055);
      case '上下游': return const Color(0xFF00B894);
      case '竞争对手': return const Color(0xFFFF6348);
      case '投资关系': return const Color(0xFF6C5CE7);
      case '引荐人': return const Color(0xFFA29BFE);
      case '校友': return const Color(0xFF74B9FF);
      case '同事': return const Color(0xFF636E72);
      case '家族': return const Color(0xFFFDAA5B);
      case '行业联盟': return const Color(0xFF00CEC9);
      default: return const Color(0xFFDFE6E9);
    }
  }
}
