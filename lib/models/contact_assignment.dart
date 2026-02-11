/// Work stage that a team member has with a contact
enum ContactWorkStage {
  lead('线索'),
  contacted('已接触'),
  ongoing('持续接触'),
  negotiation('谈判中'),
  ordered('下订单'),
  closed('已成交');

  final String label;
  const ContactWorkStage(this.label);
}

/// Assignment of a team member to work with a contact at a specific stage
class ContactAssignment {
  final String id;
  String memberId;
  String memberName;
  String contactId;
  String contactName;
  ContactWorkStage stage;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  ContactAssignment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.contactId,
    required this.contactName,
    this.stage = ContactWorkStage.lead,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'memberId': memberId, 'memberName': memberName,
    'contactId': contactId, 'contactName': contactName,
    'stage': stage.name, 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ContactAssignment.fromJson(Map<String, dynamic> json) => ContactAssignment(
    id: json['id'] as String? ?? '',
    memberId: json['memberId'] as String? ?? '',
    memberName: json['memberName'] as String? ?? '',
    contactId: json['contactId'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    stage: ContactWorkStage.values.firstWhere((e) => e.name == json['stage'], orElse: () => ContactWorkStage.lead),
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
  );
}
