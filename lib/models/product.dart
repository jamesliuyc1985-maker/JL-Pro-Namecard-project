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
  String priceType; // agent, clinic, retail
  List<OrderItem> items;
  double totalAmount;
  String currency;
  String notes;
  String deliveryAddress; // 配送地址
  String shippingMethod; // 配送方式: express, sea, air, pickup
  String paymentTerms; // 付款条件: prepaid, cod, net30, net60
  String dealStage; // 关联的交易阶段
  String contactPhone; // 客户电话
  String contactCompany; // 客户公司
  DateTime? expectedDeliveryDate; // 预计交付日期
  DateTime createdAt;
  DateTime updatedAt;

  SalesOrder({
    required this.id,
    required this.contactId,
    required this.contactName,
    this.status = 'draft',
    this.priceType = 'retail',
    List<OrderItem>? items,
    this.totalAmount = 0,
    this.currency = 'JPY',
    this.notes = '',
    this.deliveryAddress = '',
    this.shippingMethod = '',
    this.paymentTerms = '',
    this.dealStage = '',
    this.contactPhone = '',
    this.contactCompany = '',
    this.expectedDeliveryDate,
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
    'price_type': priceType,
    'items': items.map((i) => i.toJson()).toList(),
    'total_amount': totalAmount,
    'currency': currency,
    'notes': notes,
    'delivery_address': deliveryAddress,
    'shipping_method': shippingMethod,
    'payment_terms': paymentTerms,
    'deal_stage': dealStage,
    'contact_phone': contactPhone,
    'contact_company': contactCompany,
    'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
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
      priceType: json['price_type'] as String? ?? 'retail',
      items: parsedItems,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'JPY',
      notes: json['notes'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      shippingMethod: json['shipping_method'] as String? ?? '',
      paymentTerms: json['payment_terms'] as String? ?? '',
      dealStage: json['deal_stage'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      contactCompany: json['contact_company'] as String? ?? '',
      expectedDeliveryDate: json['expected_delivery_date'] != null ? DateTime.tryParse(json['expected_delivery_date']) : null,
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

  static String priceTypeLabel(String pt) {
    switch (pt) {
      case 'agent': return '代理价';
      case 'clinic': return '诊所价';
      case 'retail': return '零售价';
      default: return pt;
    }
  }

  static String shippingLabel(String s) {
    switch (s) {
      case 'express': return '快递';
      case 'sea': return '海运';
      case 'air': return '空运';
      case 'pickup': return '自提';
      default: return s.isEmpty ? '未指定' : s;
    }
  }

  static String paymentLabel(String s) {
    switch (s) {
      case 'prepaid': return '预付款';
      case 'cod': return '货到付款';
      case 'net30': return 'Net 30天';
      case 'net60': return 'Net 60天';
      default: return s.isEmpty ? '未指定' : s;
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
