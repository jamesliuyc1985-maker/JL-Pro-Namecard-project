/// 检测/质检(QC) 记录
/// 关联库存: 送检 → 出库(检测), 合格回库 → 入库(检测合格)
class QcStatus {
  static const pending = 'pending';         // 待送检
  static const submitted = 'submitted';     // 已送检(占用库存)
  static const inProgress = 'in_progress';  // 检测中(占用库存)
  static const passed = 'passed';           // 合格(库存回归)
  static const failed = 'failed';           // 不合格(库存报废)
  static const cancelled = 'cancelled';     // 取消

  static String label(String s) {
    switch (s) {
      case pending: return '待送检';
      case submitted: return '已送检';
      case inProgress: return '检测中';
      case passed: return '合格';
      case failed: return '不合格';
      case cancelled: return '已取消';
      default: return s;
    }
  }

  /// 是否占用库存
  static bool isOccupying(String s) => s == submitted || s == inProgress;

  /// 活跃状态
  static const activeStatuses = [pending, submitted, inProgress];
}

class QcRecord {
  String id;
  String productId;
  String productName;
  String productCode;
  int quantity;             // 送检数量
  String status;            // QcStatus
  String testType;          // 检测类型: stability(稳定性), purity(纯度), sterility(无菌), comprehensive(综合)
  String testLab;           // 检测机构
  String batchNumber;       // 批次号
  String notes;             // 备注
  String result;            // 检测结果摘要
  DateTime createdAt;
  DateTime? submittedAt;    // 送检时间
  DateTime? completedAt;    // 完成时间
  String linkedInventoryOutId;  // 关联的出库记录ID(送检出库)
  String linkedInventoryInId;   // 关联的入库记录ID(合格回库)

  QcRecord({
    required this.id,
    required this.productId,
    required this.productName,
    this.productCode = '',
    required this.quantity,
    this.status = 'pending',
    this.testType = 'comprehensive',
    this.testLab = '',
    this.batchNumber = '',
    this.notes = '',
    this.result = '',
    DateTime? createdAt,
    this.submittedAt,
    this.completedAt,
    this.linkedInventoryOutId = '',
    this.linkedInventoryInId = '',
  }) : createdAt = createdAt ?? DateTime.now();

  /// 是否正在占用库存
  bool get isOccupyingStock => QcStatus.isOccupying(status);

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'quantity': quantity,
    'status': status,
    'test_type': testType,
    'test_lab': testLab,
    'batch_number': batchNumber,
    'notes': notes,
    'result': result,
    'created_at': createdAt.toIso8601String(),
    'submitted_at': submittedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'linked_inventory_out_id': linkedInventoryOutId,
    'linked_inventory_in_id': linkedInventoryInId,
  };

  factory QcRecord.fromJson(Map<String, dynamic> json) => QcRecord(
    id: json['id'] as String? ?? '',
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    productCode: json['product_code'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'pending',
    testType: json['test_type'] as String? ?? 'comprehensive',
    testLab: json['test_lab'] as String? ?? '',
    batchNumber: json['batch_number'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    result: json['result'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at']) : null,
    completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    linkedInventoryOutId: json['linked_inventory_out_id'] as String? ?? '',
    linkedInventoryInId: json['linked_inventory_in_id'] as String? ?? '',
  );

  static String testTypeLabel(String t) {
    switch (t) {
      case 'stability': return '稳定性检测';
      case 'purity': return '纯度检测';
      case 'sterility': return '无菌检测';
      case 'comprehensive': return '综合检测';
      case 'appearance': return '外观检测';
      case 'potency': return '效价检测';
      default: return t;
    }
  }
}
