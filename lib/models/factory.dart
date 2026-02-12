/// 工厂信息模型
class ProductionFactory {
  String id;
  String name;        // 公司名
  String nameJa;      // 日文名
  String address;     // 地址
  String representative; // 代表人
  String description; // 描述
  List<String> certifications; // 资质认证
  List<String> capabilities;   // 生产能力 (产品分类)
  String phone;
  String email;
  bool isActive;
  DateTime createdAt;

  ProductionFactory({
    required this.id,
    required this.name,
    this.nameJa = '',
    this.address = '',
    this.representative = '',
    this.description = '',
    List<String>? certifications,
    List<String>? capabilities,
    this.phone = '',
    this.email = '',
    this.isActive = true,
    DateTime? createdAt,
  }) : certifications = certifications ?? [],
       capabilities = capabilities ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ja': nameJa,
    'address': address,
    'representative': representative,
    'description': description,
    'certifications': certifications,
    'capabilities': capabilities,
    'phone': phone,
    'email': email,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  factory ProductionFactory.fromJson(Map<String, dynamic> json) => ProductionFactory(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nameJa: json['name_ja'] as String? ?? '',
    address: json['address'] as String? ?? '',
    representative: json['representative'] as String? ?? '',
    description: json['description'] as String? ?? '',
    certifications: (json['certifications'] is List) ? List<String>.from(json['certifications']) : [],
    capabilities: (json['capabilities'] is List) ? List<String>.from(json['capabilities']) : [],
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

/// 生产订单状态
class ProductionStatus {
  static const planned = 'planned';       // 计划中
  static const materials = 'materials';   // 备料中
  static const producing = 'producing';   // 生产中
  static const quality = 'quality';       // 质检中
  static const completed = 'completed';   // 已完成
  static const cancelled = 'cancelled';   // 已取消

  static String label(String s) {
    switch (s) {
      case planned: return '计划中';
      case materials: return '备料中';
      case producing: return '生产中';
      case quality: return '质检中';
      case completed: return '已完成';
      case cancelled: return '已取消';
      default: return s;
    }
  }

  static List<String> get activeStatuses => [planned, materials, producing, quality];
  static List<String> get allStatuses => [planned, materials, producing, quality, completed, cancelled];
}

/// 生产订单模型
class ProductionOrder {
  String id;
  String factoryId;
  String factoryName;
  String productId;
  String productName;
  String productCode;
  int quantity;            // 生产数量
  String status;           // ProductionStatus
  String batchNumber;      // 批次号
  DateTime plannedDate;    // 计划生产日期
  DateTime? startedDate;   // 实际开始日期
  DateTime? completedDate; // 完成日期
  String assigneeId;     // 指派的团队成员ID
  String assigneeName;   // 指派的团队成员名
  String notes;
  String qualityNotes;     // 质检备注
  double estimatedCost;    // 预估成本
  double actualCost;       // 实际成本
  bool inventoryLinked;    // 是否已关联入库
  String? linkedInventoryId; // 关联的入库记录ID
  DateTime createdAt;
  DateTime updatedAt;

  ProductionOrder({
    required this.id,
    required this.factoryId,
    required this.factoryName,
    required this.productId,
    required this.productName,
    this.productCode = '',
    required this.quantity,
    this.status = 'planned',
    this.batchNumber = '',
    DateTime? plannedDate,
    this.startedDate,
    this.completedDate,
    this.assigneeId = '',
    this.assigneeName = '',
    this.notes = '',
    this.qualityNotes = '',
    this.estimatedCost = 0,
    this.actualCost = 0,
    this.inventoryLinked = false,
    this.linkedInventoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : plannedDate = plannedDate ?? DateTime.now().add(const Duration(days: 7)),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'factory_id': factoryId,
    'factory_name': factoryName,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'quantity': quantity,
    'status': status,
    'batch_number': batchNumber,
    'planned_date': plannedDate.toIso8601String(),
    'started_date': startedDate?.toIso8601String(),
    'completed_date': completedDate?.toIso8601String(),
    'assignee_id': assigneeId,
    'assignee_name': assigneeName,
    'notes': notes,
    'quality_notes': qualityNotes,
    'estimated_cost': estimatedCost,
    'actual_cost': actualCost,
    'inventory_linked': inventoryLinked,
    'linked_inventory_id': linkedInventoryId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ProductionOrder.fromJson(Map<String, dynamic> json) => ProductionOrder(
    id: json['id'] as String? ?? '',
    factoryId: json['factory_id'] as String? ?? '',
    factoryName: json['factory_name'] as String? ?? '',
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    productCode: json['product_code'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'planned',
    batchNumber: json['batch_number'] as String? ?? '',
    plannedDate: DateTime.tryParse(json['planned_date'] ?? '') ?? DateTime.now(),
    startedDate: json['started_date'] != null ? DateTime.tryParse(json['started_date']) : null,
    completedDate: json['completed_date'] != null ? DateTime.tryParse(json['completed_date']) : null,
    assigneeId: json['assignee_id'] as String? ?? '',
    assigneeName: json['assignee_name'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    qualityNotes: json['quality_notes'] as String? ?? '',
    estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
    actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
    inventoryLinked: json['inventory_linked'] as bool? ?? false,
    linkedInventoryId: json['linked_inventory_id'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
  );
}
