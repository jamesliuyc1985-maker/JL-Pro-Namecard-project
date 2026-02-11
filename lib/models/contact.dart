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
  })  : createdAt = createdAt ?? DateTime.now(),
        lastContactedAt = lastContactedAt ?? DateTime.now(),
        tags = tags ?? [];

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
      );
}

/// 联系人之间的关系
class ContactRelation {
  final String id;
  String fromContactId;
  String toContactId;
  String fromName;
  String toName;
  String relationType; // 同事、合伙人、客户-供应商、朋友、校友等
  String description;
  DateTime createdAt;

  ContactRelation({
    required this.id,
    required this.fromContactId,
    required this.toContactId,
    required this.fromName,
    required this.toName,
    required this.relationType,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromContactId': fromContactId,
        'toContactId': toContactId,
        'fromName': fromName,
        'toName': toName,
        'relationType': relationType,
        'description': description,
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
        description: json['description'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
