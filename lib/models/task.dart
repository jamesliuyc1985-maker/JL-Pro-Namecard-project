/// Task phases for workflow management
enum TaskPhase {
  assigned('分配', 0),
  preparing('准备中', 1),
  started('已启动', 2),
  ongoing('持续工作', 3),
  completed('已完成', 4);

  final String label;
  final int order;
  const TaskPhase(this.label, this.order);
}

class TaskHistory {
  final String fromPhase;
  final String toPhase;
  final DateTime timestamp;
  final String? note;

  TaskHistory({
    required this.fromPhase,
    required this.toPhase,
    DateTime? timestamp,
    this.note,
  }) : timestamp = timestamp ?? DateTime.now();
}

class Task {
  String id;
  String title;
  String description;
  String assigneeId;
  String assigneeName;
  String creatorId;
  String creatorName;
  String status; // kept for backwards compat: pending, in_progress, completed, cancelled
  TaskPhase phase; // new: assigned, preparing, started, ongoing, completed
  String priority; // low, medium, high, urgent
  DateTime dueDate;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;
  double estimatedHours;
  double actualHours;
  String? contactId;
  String? dealId;
  List<String> tags;
  List<TaskHistory> history;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.assigneeId,
    required this.assigneeName,
    this.creatorId = '',
    this.creatorName = '',
    this.status = 'pending',
    this.phase = TaskPhase.assigned,
    this.priority = 'medium',
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.estimatedHours = 0,
    this.actualHours = 0,
    this.contactId,
    this.dealId,
    List<String>? tags,
    List<TaskHistory>? history,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7)),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       tags = tags ?? [],
       history = history ?? [];

  /// Move to next phase and record history
  void moveToPhase(TaskPhase newPhase, {String? note}) {
    final old = phase;
    history.add(TaskHistory(fromPhase: old.label, toPhase: newPhase.label, note: note));
    phase = newPhase;
    updatedAt = DateTime.now();
    // sync status field
    if (newPhase == TaskPhase.completed) {
      status = 'completed';
      completedAt = DateTime.now();
    } else if (newPhase == TaskPhase.assigned) {
      status = 'pending';
    } else {
      status = 'in_progress';
    }
  }

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

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'assigneeId': assigneeId, 'assigneeName': assigneeName,
    'creatorId': creatorId, 'creatorName': creatorName,
    'status': status, 'phase': phase.name, 'priority': priority,
    'dueDate': dueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'estimatedHours': estimatedHours, 'actualHours': actualHours,
    'contactId': contactId, 'dealId': dealId, 'tags': tags,
    'history': history.map((h) => {
      'fromPhase': h.fromPhase, 'toPhase': h.toPhase,
      'timestamp': h.timestamp.toIso8601String(), 'note': h.note,
    }).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    assigneeId: json['assigneeId'] as String? ?? '',
    assigneeName: json['assigneeName'] as String? ?? '',
    creatorId: json['creatorId'] as String? ?? '',
    creatorName: json['creatorName'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    phase: TaskPhase.values.firstWhere((e) => e.name == json['phase'], orElse: () => TaskPhase.assigned),
    priority: json['priority'] as String? ?? 'medium',
    dueDate: DateTime.tryParse(json['dueDate'] ?? ''),
    createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
    estimatedHours: (json['estimatedHours'] as num?)?.toDouble() ?? 0,
    actualHours: (json['actualHours'] as num?)?.toDouble() ?? 0,
    contactId: json['contactId'] as String?,
    dealId: json['dealId'] as String?,
    tags: List<String>.from(json['tags'] ?? []),
    history: (json['history'] as List?)?.map((h) => TaskHistory(
      fromPhase: h['fromPhase'] as String? ?? '',
      toPhase: h['toPhase'] as String? ?? '',
      timestamp: DateTime.tryParse(h['timestamp'] ?? ''),
      note: h['note'] as String?,
    )).toList(),
  );
}
