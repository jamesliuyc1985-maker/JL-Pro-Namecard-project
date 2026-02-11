class InventoryRecord {
  String id;
  String productId;
  String productName;
  String productCode;
  String type; // in, out, adjust
  int quantity;
  String reason;
  String notes;
  DateTime createdAt;

  InventoryRecord({
    required this.id,
    required this.productId,
    required this.productName,
    this.productCode = '',
    required this.type,
    required this.quantity,
    this.reason = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'type': type,
    'quantity': quantity,
    'reason': reason,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory InventoryRecord.fromJson(Map<String, dynamic> json) => InventoryRecord(
    id: json['id'] as String? ?? '',
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    productCode: json['product_code'] as String? ?? '',
    type: json['type'] as String? ?? 'in',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    reason: json['reason'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  static String typeLabel(String t) {
    switch (t) {
      case 'in': return '入库';
      case 'out': return '出库';
      case 'adjust': return '调整';
      default: return t;
    }
  }
}

class InventoryStock {
  String productId;
  String productName;
  String productCode;
  int currentStock;

  InventoryStock({
    required this.productId,
    required this.productName,
    this.productCode = '',
    this.currentStock = 0,
  });
}
