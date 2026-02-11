class ProductCategory {
  static const exosome = 'exosome';
  static const nad = 'nad';
  static const nmn = 'nmn';
  static const skincare = 'skincare';

  static String label(String cat) {
    switch (cat) {
      case exosome: return '外泌体';
      case nad: return 'NAD+';
      case nmn: return 'NMN';
      case skincare: return '美容';
      default: return cat;
    }
  }
}

class Product {
  String id;
  String code;
  String name;
  String nameJa;
  String category;
  String description;
  String specification;
  int unitsPerBox;
  double agentPrice;
  double clinicPrice;
  double retailPrice;
  double agentTotalPrice;
  double clinicTotalPrice;
  double retailTotalPrice;
  String storageMethod;
  String shelfLife;
  String usage;
  String notes;
  DateTime createdAt;

  Product({
    required this.id,
    required this.code,
    required this.name,
    this.nameJa = '',
    required this.category,
    this.description = '',
    this.specification = '',
    this.unitsPerBox = 5,
    this.agentPrice = 0,
    this.clinicPrice = 0,
    this.retailPrice = 0,
    this.agentTotalPrice = 0,
    this.clinicTotalPrice = 0,
    this.retailTotalPrice = 0,
    this.storageMethod = '',
    this.shelfLife = '',
    this.usage = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'name_ja': nameJa,
    'category': category,
    'description': description,
    'specification': specification,
    'units_per_box': unitsPerBox,
    'agent_price': agentPrice,
    'clinic_price': clinicPrice,
    'retail_price': retailPrice,
    'agent_total_price': agentTotalPrice,
    'clinic_total_price': clinicTotalPrice,
    'retail_total_price': retailTotalPrice,
    'storage_method': storageMethod,
    'shelf_life': shelfLife,
    'usage': usage,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nameJa: json['name_ja'] as String? ?? '',
    category: json['category'] as String? ?? 'exosome',
    description: json['description'] as String? ?? '',
    specification: json['specification'] as String? ?? '',
    unitsPerBox: (json['units_per_box'] as num?)?.toInt() ?? 5,
    agentPrice: (json['agent_price'] as num?)?.toDouble() ?? 0,
    clinicPrice: (json['clinic_price'] as num?)?.toDouble() ?? 0,
    retailPrice: (json['retail_price'] as num?)?.toDouble() ?? 0,
    agentTotalPrice: (json['agent_total_price'] as num?)?.toDouble() ?? 0,
    clinicTotalPrice: (json['clinic_total_price'] as num?)?.toDouble() ?? 0,
    retailTotalPrice: (json['retail_total_price'] as num?)?.toDouble() ?? 0,
    storageMethod: json['storage_method'] as String? ?? '',
    shelfLife: json['shelf_life'] as String? ?? '',
    usage: json['usage'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class SalesOrder {
  String id;
  String contactId;
  String contactName;
  String status; // draft, confirmed, shipped, completed, cancelled
  List<OrderItem> items;
  double totalAmount;
  String currency;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  SalesOrder({
    required this.id,
    required this.contactId,
    required this.contactName,
    this.status = 'draft',
    List<OrderItem>? items,
    this.totalAmount = 0,
    this.currency = 'JPY',
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : items = items ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  void recalculate() {
    totalAmount = 0;
    for (final item in items) {
      totalAmount += item.subtotal;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contact_id': contactId,
    'contact_name': contactName,
    'status': status,
    'items': items.map((i) => i.toJson()).toList(),
    'total_amount': totalAmount,
    'currency': currency,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'];
    List<OrderItem> parsedItems = [];
    if (itemsList is List) {
      parsedItems = itemsList.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList();
    }
    return SalesOrder(
      id: json['id'] as String? ?? '',
      contactId: json['contact_id'] as String? ?? '',
      contactName: json['contact_name'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      items: parsedItems,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'JPY',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'draft': return '草稿';
      case 'confirmed': return '已确认';
      case 'shipped': return '已发货';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return s;
    }
  }
}

class OrderItem {
  String productId;
  String productName;
  String productCode;
  int quantity;
  double unitPrice;
  double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    this.productCode = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.subtotal = 0,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'quantity': quantity,
    'unit_price': unitPrice,
    'subtotal': subtotal,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    productCode: json['product_code'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
  );
}
