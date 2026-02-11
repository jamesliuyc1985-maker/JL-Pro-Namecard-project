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
}
