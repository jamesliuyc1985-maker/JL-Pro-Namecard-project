enum DealStage {
  lead('线索', 0),
  contacted('已接触', 1),
  proposal('提案中', 2),
  negotiation('谈判中', 3),
  closed('已成交', 4),
  lost('已流失', 5);

  final String label;
  final int order;
  const DealStage(this.label, this.order);
}

class Deal {
  final String id;
  String title;
  String description;
  String contactId;
  String contactName;
  DealStage stage;
  double amount;
  String currency;
  DateTime createdAt;
  DateTime expectedCloseDate;
  DateTime updatedAt;
  double probability;
  String notes;
  List<String> tags;

  Deal({
    required this.id,
    required this.title,
    this.description = '',
    required this.contactId,
    required this.contactName,
    this.stage = DealStage.lead,
    this.amount = 0,
    this.currency = 'JPY',
    DateTime? createdAt,
    DateTime? expectedCloseDate,
    DateTime? updatedAt,
    this.probability = 10,
    this.notes = '',
    List<String>? tags,
  })  : createdAt = createdAt ?? DateTime.now(),
        expectedCloseDate =
            expectedCloseDate ?? DateTime.now().add(const Duration(days: 90)),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'contactId': contactId,
        'contactName': contactName,
        'stage': stage.name,
        'amount': amount,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
        'expectedCloseDate': expectedCloseDate.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'probability': probability,
        'notes': notes,
        'tags': tags,
      };

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        contactId: json['contactId'] as String,
        contactName: json['contactName'] as String,
        stage: DealStage.values.firstWhere(
          (e) => e.name == json['stage'],
          orElse: () => DealStage.lead,
        ),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'JPY',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        expectedCloseDate:
            DateTime.tryParse(json['expectedCloseDate'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
        probability: (json['probability'] as num?)?.toDouble() ?? 10,
        notes: json['notes'] as String? ?? '',
        tags: List<String>.from(json['tags'] ?? []),
      );
}
