enum InteractionType {
  meeting('会议'),
  call('电话'),
  email('邮件'),
  dinner('饭局'),
  introduction('引荐'),
  other('其他');

  final String label;
  const InteractionType(this.label);
}

class Interaction {
  final String id;
  String contactId;
  String contactName;
  InteractionType type;
  String title;
  String notes;
  DateTime date;
  String? dealId;

  Interaction({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.type,
    required this.title,
    this.notes = '',
    DateTime? date,
    this.dealId,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': contactId,
        'contactName': contactName,
        'type': type.name,
        'title': title,
        'notes': notes,
        'date': date.toIso8601String(),
        'dealId': dealId,
      };

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id'] as String,
        contactId: json['contactId'] as String,
        contactName: json['contactName'] as String,
        type: InteractionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => InteractionType.other,
        ),
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        dealId: json['dealId'] as String?,
      );
}
