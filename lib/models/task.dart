class Task {
  String id;
  String title;
  String description;
  String assigneeId;
  String assigneeName;
  String creatorId;
  String creatorName;
  String status; // pending, in_progress, completed, cancelled
  String priority; // low, medium, high, urgent
  DateTime dueDate;
  DateTime createdAt;
  DateTime updatedAt;
  double estimatedHours;
  double actualHours;
  String? contactId;
  String? dealId;
  List<String> tags;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.assigneeId,
    required this.assigneeName,
    this.creatorId = '',
    this.creatorName = '',
    this.status = 'pending',
    this.priority = 'medium',
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.estimatedHours = 0,
    this.actualHours = 0,
    this.contactId,
    this.dealId,
    List<String>? tags,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7)),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       tags = tags ?? [];

  static String statusLabel(String s) {
    switch (s) {
      case 'pending': return '待处理';
      case 'in_progress': return '进行中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return s;
    }
  }

  static String priorityLabel(String p) {
    switch (p) {
      case 'low': return '低';
      case 'medium': return '中';
      case 'high': return '高';
      case 'urgent': return '紧急';
      default: return p;
    }
  }
}
