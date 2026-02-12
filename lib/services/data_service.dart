import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/team.dart';
import '../models/task.dart';
import '../models/contact_assignment.dart';
import '../models/factory.dart';

/// DataService: Local-first + 可选 Firestore 云同步
class DataService {
  static const _uuid = Uuid();

  String _userId = 'local';
  void setUserId(String uid) => _userId = uid;
  String get userId => _userId;

  /// Firestore 开关
  bool _firestoreEnabled = false;
  FirebaseFirestore? _db;
  bool get isFirestoreEnabled => _firestoreEnabled;

  void enableFirestore() {
    _firestoreEnabled = true;
    _db = FirebaseFirestore.instance;
    if (kDebugMode) debugPrint('[DataService] Firestore enabled');
  }

  // ========== Local caches ==========
  List<Contact> _contactsCache = [];
  List<Deal> _dealsCache = [];
  List<Interaction> _interactionsCache = [];
  List<ContactRelation> _relationsCache = [];
  List<Product> _productsCache = [];
  List<SalesOrder> _ordersCache = [];
  final List<InventoryRecord> _inventoryCache = [];
  final List<TeamMember> _teamCache = [];
  final List<Task> _taskCache = [];
  final List<ContactAssignment> _assignmentCache = [];
  final List<ProductionFactory> _factoryCache = [];
  final List<ProductionOrder> _productionCache = [];

  // ========== Team CRUD ==========
  List<TeamMember> getAllTeamMembers() => List.from(_teamCache);
  TeamMember? getTeamMember(String id) {
    try { return _teamCache.firstWhere((m) => m.id == id); } catch (_) { return null; }
  }
  Future<void> addTeamMember(TeamMember member) async {
    _teamCache.add(member);
  }
  Future<void> updateTeamMember(TeamMember member) async {
    final idx = _teamCache.indexWhere((m) => m.id == member.id);
    if (idx >= 0) _teamCache[idx] = member;
  }
  Future<void> deleteTeamMember(String id) async {
    _teamCache.removeWhere((m) => m.id == id);
  }

  // ========== Task CRUD ==========
  List<Task> getAllTasks() => List.from(_taskCache);
  List<Task> getTasksByAssignee(String assigneeId) =>
      _taskCache.where((t) => t.assigneeId == assigneeId).toList();
  List<Task> getTasksByDate(DateTime date) =>
      _taskCache.where((t) => t.dueDate.year == date.year && t.dueDate.month == date.month && t.dueDate.day == date.day).toList();
  Future<void> addTask(Task task) async {
    _taskCache.add(task);
  }
  Future<void> updateTask(Task task) async {
    final idx = _taskCache.indexWhere((t) => t.id == task.id);
    if (idx >= 0) _taskCache[idx] = task;
  }
  Future<void> deleteTask(String id) async {
    _taskCache.removeWhere((t) => t.id == id);
  }

  // ========== Contact Assignment CRUD ==========
  List<ContactAssignment> getAllAssignments() => List.from(_assignmentCache);
  List<ContactAssignment> getAssignmentsByContact(String contactId) =>
      _assignmentCache.where((a) => a.contactId == contactId).toList();
  List<ContactAssignment> getAssignmentsByMember(String memberId) =>
      _assignmentCache.where((a) => a.memberId == memberId).toList();
  Future<void> addAssignment(ContactAssignment assignment) async {
    _assignmentCache.add(assignment);
  }
  Future<void> updateAssignment(ContactAssignment assignment) async {
    final idx = _assignmentCache.indexWhere((a) => a.id == assignment.id);
    if (idx >= 0) _assignmentCache[idx] = assignment;
  }
  Future<void> deleteAssignment(String id) async {
    _assignmentCache.removeWhere((a) => a.id == id);
  }

  // ========== Factory CRUD ==========
  List<ProductionFactory> getAllFactories() => List.from(_factoryCache);
  ProductionFactory? getFactory(String id) {
    try { return _factoryCache.firstWhere((f) => f.id == id); } catch (_) { return null; }
  }
  Future<void> addFactory(ProductionFactory factory) async {
    _factoryCache.add(factory);
  }
  Future<void> updateFactory(ProductionFactory factory) async {
    final idx = _factoryCache.indexWhere((f) => f.id == factory.id);
    if (idx >= 0) _factoryCache[idx] = factory;
  }
  Future<void> deleteFactory(String id) async {
    _factoryCache.removeWhere((f) => f.id == id);
  }

  // ========== ProductionOrder CRUD ==========
  List<ProductionOrder> getAllProductionOrders() => List.from(_productionCache);
  ProductionOrder? getProductionOrder(String id) {
    try { return _productionCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
  List<ProductionOrder> getProductionByFactory(String factoryId) =>
      _productionCache.where((p) => p.factoryId == factoryId).toList();
  List<ProductionOrder> getProductionByProduct(String productId) =>
      _productionCache.where((p) => p.productId == productId).toList();
  List<ProductionOrder> getProductionByStatus(String status) =>
      _productionCache.where((p) => p.status == status).toList();
  List<ProductionOrder> getActiveProductions() =>
      _productionCache.where((p) => ProductionStatus.activeStatuses.contains(p.status)).toList();
  Future<void> addProductionOrder(ProductionOrder order) async {
    _productionCache.add(order);
  }
  Future<void> updateProductionOrder(ProductionOrder order) async {
    final idx = _productionCache.indexWhere((p) => p.id == order.id);
    if (idx >= 0) _productionCache[idx] = order;
  }
  Future<void> deleteProductionOrder(String id) async {
    _productionCache.removeWhere((p) => p.id == id);
  }

  // ========== Completed Tasks History ==========
  List<Task> getCompletedTasks() =>
      _taskCache.where((t) => t.phase == TaskPhase.completed).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));
  List<Task> getTasksByPhase(TaskPhase phase) =>
      _taskCache.where((t) => t.phase == phase).toList();
  Map<String, double> getWorkloadStats() {
    final stats = <String, double>{};
    for (final t in _taskCache) {
      stats[t.assigneeName] = (stats[t.assigneeName] ?? 0) + (t.actualHours > 0 ? t.actualHours : t.estimatedHours);
    }
    return stats;
  }

  // ========== Init (纯本地，加载种子数据) ==========
  Future<void> init() async {
    _productsCache = _builtInProducts();
    _factoryCache.addAll(_builtInFactories());
    _teamCache.addAll(_builtInTeam());
    _contactsCache = _builtInContacts();
    _dealsCache = _builtInDeals();
    _relationsCache = _builtInRelations();
    if (kDebugMode) {
      debugPrint('[DataService] Loaded: ${_contactsCache.length} contacts, ${_dealsCache.length} deals, ${_relationsCache.length} relations, ${_productsCache.length} products');
    }
  }

  // ========== Contact CRUD ==========
  List<Contact> getAllContacts() => List.from(_contactsCache);
  Contact? getContact(String id) {
    try { return _contactsCache.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }
  Future<void> saveContact(Contact contact) async {
    final idx = _contactsCache.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) { _contactsCache[idx] = contact; } else { _contactsCache.add(contact); }
    _firestoreWrite('contacts', contact.id, contact.toJson());
  }
  Future<void> deleteContact(String id) async {
    _contactsCache.removeWhere((c) => c.id == id);
    _interactionsCache.removeWhere((i) => i.contactId == id);
    _relationsCache.removeWhere((r) => r.fromContactId == id || r.toContactId == id);
    _firestoreDelete('contacts', id);
  }

  // ========== Relation CRUD ==========
  List<ContactRelation> getAllRelations() => List.from(_relationsCache);
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relationsCache.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();
  Future<void> saveRelation(ContactRelation relation) async {
    final idx = _relationsCache.indexWhere((r) => r.id == relation.id);
    if (idx >= 0) { _relationsCache[idx] = relation; } else { _relationsCache.add(relation); }
    _firestoreWrite('relations', relation.id, relation.toJson());
  }
  Future<void> deleteRelation(String id) async {
    _relationsCache.removeWhere((r) => r.id == id);
    _firestoreDelete('relations', id);
  }

  // ========== Deal CRUD ==========
  List<Deal> getAllDeals() => List.from(_dealsCache);
  List<Deal> getDealsByStage(DealStage stage) => _dealsCache.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _dealsCache.where((d) => d.contactId == contactId).toList();
  Future<void> saveDeal(Deal deal) async {
    final idx = _dealsCache.indexWhere((d) => d.id == deal.id);
    if (idx >= 0) { _dealsCache[idx] = deal; } else { _dealsCache.add(deal); }
    _firestoreWrite('deals', deal.id, deal.toJson());
  }
  Future<void> deleteDeal(String id) async {
    _dealsCache.removeWhere((d) => d.id == id);
    _firestoreDelete('deals', id);
  }

  // ========== Interaction CRUD ==========
  List<Interaction> getAllInteractions() => List.from(_interactionsCache);
  List<Interaction> getInteractionsByContact(String contactId) =>
      _interactionsCache.where((i) => i.contactId == contactId).toList();
  Future<void> saveInteraction(Interaction interaction) async {
    final idx = _interactionsCache.indexWhere((i) => i.id == interaction.id);
    if (idx >= 0) { _interactionsCache[idx] = interaction; } else { _interactionsCache.add(interaction); }
    _firestoreWrite('interactions', interaction.id, interaction.toJson());
  }
  Future<void> deleteInteraction(String id) async {
    _interactionsCache.removeWhere((i) => i.id == id);
    _firestoreDelete('interactions', id);
  }

  // ========== Product CRUD ==========
  List<Product> getAllProducts() => List.from(_productsCache);
  List<Product> getProductsByCategory(String category) => _productsCache.where((p) => p.category == category).toList();
  Product? getProduct(String id) {
    try { return _productsCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
  Future<void> saveProduct(Product product) async {
    final idx = _productsCache.indexWhere((p) => p.id == product.id);
    if (idx >= 0) { _productsCache[idx] = product; } else { _productsCache.add(product); }
    _firestoreWrite('products', product.id, product.toJson());
  }
  Future<void> deleteProduct(String id) async {
    _productsCache.removeWhere((p) => p.id == id);
    _firestoreDelete('products', id);
  }

  // ========== Sales Order CRUD ==========
  List<SalesOrder> getAllOrders() => List.from(_ordersCache);
  List<SalesOrder> getOrdersByContact(String contactId) => _ordersCache.where((o) => o.contactId == contactId).toList();
  Future<void> saveOrder(SalesOrder order) async {
    final idx = _ordersCache.indexWhere((o) => o.id == order.id);
    if (idx >= 0) { _ordersCache[idx] = order; } else { _ordersCache.add(order); }
    _firestoreWrite('sales_orders', order.id, order.toJson());
  }
  Future<void> deleteOrder(String id) async {
    _ordersCache.removeWhere((o) => o.id == id);
    _firestoreDelete('sales_orders', id);
  }

  // ========== Inventory CRUD ==========
  List<InventoryRecord> getAllInventory() => List.from(_inventoryCache);
  List<InventoryRecord> getInventoryByProduct(String productId) =>
      _inventoryCache.where((r) => r.productId == productId).toList();
  Future<void> addInventoryRecord(InventoryRecord record) async {
    _inventoryCache.add(record);
  }
  Future<void> deleteInventoryRecord(String id) async {
    _inventoryCache.removeWhere((r) => r.id == id);
  }

  List<InventoryStock> getInventoryStocks() {
    final stockMap = <String, InventoryStock>{};
    for (final p in _productsCache) {
      stockMap[p.id] = InventoryStock(
        productId: p.id, productName: p.name, productCode: p.code, currentStock: 0,
      );
    }
    for (final r in _inventoryCache) {
      final stock = stockMap[r.productId];
      if (stock != null) {
        if (r.type == 'in') { stock.currentStock += r.quantity; }
        else if (r.type == 'out') { stock.currentStock -= r.quantity; }
        else if (r.type == 'adjust') { stock.currentStock = r.quantity; }
      }
    }
    return stockMap.values.toList();
  }

  // ========== Stats ==========
  Map<String, dynamic> getStats() {
    final contacts = _contactsCache;
    final deals = _dealsCache;
    final activeDeals = deals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost).toList();
    final closedDeals = deals.where((d) => d.stage == DealStage.completed).toList();
    double pipelineValue = 0;
    for (final d in activeDeals) { pipelineValue += d.amount; }
    double closedValue = 0;
    for (final d in closedDeals) { closedValue += d.amount; }
    double salesTotal = 0;
    int orderCount = _ordersCache.where((o) => o.status == 'completed').length;
    for (final o in _ordersCache.where((o) => o.status == 'completed')) { salesTotal += o.totalAmount; }
    final industryCount = <Industry, int>{};
    for (final c in contacts) { industryCount[c.industry] = (industryCount[c.industry] ?? 0) + 1; }
    final stageCount = <DealStage, int>{};
    for (final d in deals) { stageCount[d.stage] = (stageCount[d.stage] ?? 0) + 1; }
    return {
      'totalContacts': contacts.length, 'activeDeals': activeDeals.length,
      'pipelineValue': pipelineValue, 'closedValue': closedValue,
      'closedDeals': closedDeals.length,
      'winRate': deals.isNotEmpty ? (closedDeals.length / deals.length * 100) : 0.0,
      'industryCount': industryCount, 'stageCount': stageCount,
      'hotContacts': contacts.where((c) => c.strength == RelationshipStrength.hot).length,
      'totalProducts': _productsCache.length, 'totalOrders': _ordersCache.length,
      'completedOrders': orderCount, 'salesTotal': salesTotal,
      'totalInventoryRecords': _inventoryCache.length,
      'totalFactories': _factoryCache.length,
      'activeFactories': _factoryCache.where((f) => f.isActive).length,
      'totalProductionOrders': _productionCache.length,
      'activeProductions': _productionCache.where((p) => ProductionStatus.activeStatuses.contains(p.status)).length,
      'completedProductions': _productionCache.where((p) => p.status == ProductionStatus.completed).length,
    };
  }

  String generateId() => _uuid.v4();

  // ========== Firestore 辅助方法 ==========

  /// 后台写入 Firestore（不阻塞 UI）
  void _firestoreWrite(String collection, String docId, Map<String, dynamic> data) {
    if (!_firestoreEnabled || _db == null) return;
    _db!.collection(collection).doc(docId).set(data).catchError((e) {
      if (kDebugMode) debugPrint('[DataService] Firestore write error ($collection/$docId): $e');
    });
  }

  void _firestoreDelete(String collection, String docId) {
    if (!_firestoreEnabled || _db == null) return;
    _db!.collection(collection).doc(docId).delete().catchError((e) {
      if (kDebugMode) debugPrint('[DataService] Firestore delete error ($collection/$docId): $e');
    });
  }

  /// 从 Firestore 拉取数据到本地缓存
  Future<void> syncFromCloud() async {
    if (!_firestoreEnabled || _db == null) return;
    try {
      // 联系人
      final contactSnap = await _db!.collection('contacts').get();
      if (contactSnap.docs.isNotEmpty) {
        _contactsCache = contactSnap.docs.map((d) {
          try { return Contact.fromJson(d.data()); } catch (_) { return null; }
        }).whereType<Contact>().toList();
      }
      // Deal
      final dealSnap = await _db!.collection('deals').get();
      if (dealSnap.docs.isNotEmpty) {
        _dealsCache = dealSnap.docs.map((d) {
          try { return Deal.fromJson(d.data()); } catch (_) { return null; }
        }).whereType<Deal>().toList();
      }
      // Relations
      final relSnap = await _db!.collection('relations').get();
      if (relSnap.docs.isNotEmpty) {
        _relationsCache = relSnap.docs.map((d) {
          try { return ContactRelation.fromJson(d.data()); } catch (_) { return null; }
        }).whereType<ContactRelation>().toList();
      }
      // Products
      final prodSnap = await _db!.collection('products').get();
      if (prodSnap.docs.isNotEmpty) {
        _productsCache = prodSnap.docs.map((d) {
          try { return Product.fromJson(d.data()); } catch (_) { return null; }
        }).whereType<Product>().toList();
      }

      if (kDebugMode) {
        debugPrint('[DataService] Cloud sync: ${_contactsCache.length} contacts, ${_dealsCache.length} deals, ${_relationsCache.length} relations');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DataService] syncFromCloud error: $e');
    }
  }

  // ========== Built-in Product Catalog ==========
  List<Product> _builtInProducts() => [
    Product(id: 'prod-exo-001', code: 'NS-EX0-001', name: '外泌体原液 300亿', nameJa: 'エクソソーム原液 300億単位', category: 'exosome',
      description: '高纯度外泌体原液，含300亿单位外泌体粒子。适用于肌肤再生、抗老化治疗。',
      specification: '300億単位/瓶', unitsPerBox: 5, agentPrice: 30000, clinicPrice: 40000, retailPrice: 100000,
      agentTotalPrice: 150000, clinicTotalPrice: 200000, retailTotalPrice: 500000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴/局部注射', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-exo-002', code: 'NS-EX0-002', name: '外泌体原液 500亿', nameJa: 'エクソソーム原液 500億単位', category: 'exosome',
      description: '高浓度外泌体原液，含500亿单位外泌体粒子。',
      specification: '500億単位/瓶', unitsPerBox: 5, agentPrice: 45000, clinicPrice: 60000, retailPrice: 150000,
      agentTotalPrice: 225000, clinicTotalPrice: 300000, retailTotalPrice: 750000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴/局部注射', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-exo-003', code: 'NS-EX0-003', name: '外泌体原液 1000亿', nameJa: 'エクソソーム原液 1000億単位', category: 'exosome',
      description: '超高浓度外泌体原液，含1000亿单位外泌体粒子。顶级配方。',
      specification: '1000億単位/瓶', unitsPerBox: 5, agentPrice: 105000, clinicPrice: 140000, retailPrice: 350000,
      agentTotalPrice: 525000, clinicTotalPrice: 700000, retailTotalPrice: 1750000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴/局部注射', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-nad-001', code: 'NS-NAD-001', name: 'NAD+ 注射液 250mg', nameJa: 'NAD+ 注射液 250mg', category: 'nad',
      description: '高纯度NAD+注射液，每瓶含250mg NAD+。促进细胞能量代谢。',
      specification: '250mg/瓶', unitsPerBox: 5, agentPrice: 12000, clinicPrice: 16000, retailPrice: 40000,
      agentTotalPrice: 60000, clinicTotalPrice: 80000, retailTotalPrice: 200000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-nmn-001', code: 'NS-NMN-001', name: 'NMN 点鼻/吸入', nameJa: 'NMN 点鼻・吸入', category: 'nmn',
      description: 'NMN点鼻/吸入制剂。生物利用度高。',
      specification: '点鼻/吸入型', unitsPerBox: 1, agentPrice: 22000, clinicPrice: 32000, retailPrice: 60000,
      agentTotalPrice: 22000, clinicTotalPrice: 32000, retailTotalPrice: 60000,
      storageMethod: '常温保存', shelfLife: '2年', usage: '点鼻/吸入使用', notes: 'NMN 700mg配合'),
    Product(id: 'prod-nmn-002', code: 'NS-NMN-002', name: 'NMN 胶囊', nameJa: 'NMN カプセル', category: 'nmn',
      description: 'NMN口服胶囊。每粒含高纯度NMN。',
      specification: '胶囊型', unitsPerBox: 1, agentPrice: 9000, clinicPrice: 12000, retailPrice: 30000,
      agentTotalPrice: 9000, clinicTotalPrice: 12000, retailTotalPrice: 30000,
      storageMethod: '常温保存', shelfLife: '2年', usage: '每日1-2粒，口服'),
  ];

  List<ProductionFactory> _builtInFactories() => [
    ProductionFactory(
      id: 'factory-001', name: '株式会社シエン', nameJa: '株式会社シエン',
      address: '三重県津市木江町1番11号', representative: '池田 幹',
      description: '高端生物科技加工企业，核心冻干技术，专注再生医疗领域。',
      certifications: ['GMP', '再生医療加工'], capabilities: ['exosome', 'nad'],
      phone: '', email: '', isActive: true,
    ),
    ProductionFactory(
      id: 'factory-002', name: '株式会社ミズ・バラエティー', nameJa: '株式会社ミズ・バラエティー',
      address: '静岡県富士市今泉383-5', representative: '藤田 伸夫',
      description: '综合健康食品制造企业，持有多项国际认证。',
      certifications: ['ISO9001', 'ISO27001', 'ISO22716', 'JIHFS', 'PrivacyMark', 'GMP'],
      capabilities: ['nmn', 'skincare'], phone: '', email: '', isActive: true,
    ),
  ];

  List<TeamMember> _builtInTeam() => [
    TeamMember(id: 'member-001', name: 'James Liu', role: 'admin', email: 'james@dealnavigator.com'),
    TeamMember(id: 'member-002', name: '田中太郎', role: 'manager', email: 'tanaka@dealnavigator.com'),
    TeamMember(id: 'member-003', name: '王小明', role: 'member', email: 'xiaoming@dealnavigator.com'),
  ];

  List<Contact> _builtInContacts() {
    final now = DateTime.now();
    return [
      Contact(id: 'c-001', name: '张伟', company: '上海泰康医美', position: '总经理',
        phone: '+86-138-0000-1001', email: 'zhangwei@taikang.com', address: '上海市静安区',
        industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.agent,
        notes: '华东区总代理，月采购量稳定', tags: ['VIP', '代理'],
        createdAt: now.subtract(const Duration(days: 400)), lastContactedAt: now.subtract(const Duration(days: 1)),
        businessCategory: 'agent'),
      Contact(id: 'c-002', name: 'Dr. 田中美咲', nameReading: 'たなか みさき', company: '六本木スキンクリニック', position: '院长',
        phone: '+81-3-5555-0001', email: 'misaki@roppongi-skin.jp', address: '東京都港区六本木3-1-1',
        industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.clinic,
        notes: '月采购外泌体注射液20支', tags: ['诊所', '东京', 'VIP'],
        createdAt: now.subtract(const Duration(days: 380)), lastContactedAt: now.subtract(const Duration(hours: 6)),
        businessCategory: 'clinic'),
      Contact(id: 'c-003', name: '李明', company: '深圳健康优选', position: '采购总监',
        phone: '+86-135-0000-2002', email: 'liming@healthbest.cn', address: '深圳市南山区',
        industry: Industry.trading, strength: RelationshipStrength.warm, myRelation: MyRelationType.retailer,
        notes: '跨境电商渠道，NMN产品为主', tags: ['零售', '电商'],
        createdAt: now.subtract(const Duration(days: 340)), lastContactedAt: now.subtract(const Duration(days: 3)),
        businessCategory: 'retail'),
      Contact(id: 'c-004', name: '佐藤健一', nameReading: 'さとう けんいち', company: '东京美容协会', position: '理事',
        phone: '+81-3-6666-0001', email: 'sato.k@beauty-assoc.jp', address: '東京都渋谷区',
        industry: Industry.consulting, strength: RelationshipStrength.warm, myRelation: MyRelationType.advisor,
        notes: '行业资源介绍，关键人脉节点', tags: ['顾问', '东京'],
        createdAt: now.subtract(const Duration(days: 310)), lastContactedAt: now.subtract(const Duration(days: 22))),
      Contact(id: 'c-005', name: '王芳', company: '杭州悦颜医美', position: '运营总监',
        phone: '+86-139-0000-3003', email: 'wangfang@yueyan.com', address: '杭州市西湖区',
        industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.clinic,
        notes: '3家连锁诊所，月销稳定', tags: ['诊所', '杭州', 'VIP'],
        createdAt: now.subtract(const Duration(days: 270)), lastContactedAt: now.subtract(const Duration(days: 2)),
        businessCategory: 'clinic'),
      Contact(id: 'c-006', name: 'Mike Chen', company: 'Pacific Health Group', position: 'VP Business Dev',
        phone: '+1-415-555-0088', email: 'mchen@pacifichealth.com', address: 'San Francisco, CA',
        industry: Industry.trading, strength: RelationshipStrength.cool, myRelation: MyRelationType.agent,
        notes: '北美市场潜在代理', tags: ['北美', '开发中'],
        createdAt: now.subtract(const Duration(days: 175)), lastContactedAt: now.subtract(const Duration(days: 12)),
        businessCategory: 'agent'),
      Contact(id: 'c-007', name: '山本真由美', nameReading: 'やまもと まゆみ', company: '銀座ビューティーラボ', position: 'オーナー',
        phone: '+81-3-7777-0001', email: 'yamamoto@ginza-beauty.jp', address: '東京都中央区銀座5-1-1',
        industry: Industry.healthcare, strength: RelationshipStrength.warm, myRelation: MyRelationType.clinic,
        notes: '高端美容院，对外泌体面膜感兴趣', tags: ['诊所', '银座'],
        createdAt: now.subtract(const Duration(days: 160)), lastContactedAt: now.subtract(const Duration(days: 6)),
        businessCategory: 'clinic'),
      Contact(id: 'c-008', name: '赵大力', company: '成都康复堂', position: '合伙人',
        phone: '+86-136-0000-4004', email: 'zhaodl@kangfutang.cn', address: '成都市锦江区',
        industry: Industry.healthcare, strength: RelationshipStrength.cool, myRelation: MyRelationType.retailer,
        notes: '线下零售+社群团购', tags: ['零售', '成都'],
        createdAt: now.subtract(const Duration(days: 130)), lastContactedAt: now.subtract(const Duration(days: 17)),
        businessCategory: 'retail'),
      Contact(id: 'c-009', name: '金相哲', nameReading: '김상철', company: 'Seoul Derm Clinic', position: 'Director',
        phone: '+82-2-555-0099', email: 'kim@seoulderm.kr', address: '서울 강남구',
        industry: Industry.healthcare, strength: RelationshipStrength.cool, myRelation: MyRelationType.clinic,
        notes: '韩国皮肤科诊所，考察中', tags: ['诊所', '韩国'],
        createdAt: now.subtract(const Duration(days: 95)), lastContactedAt: now.subtract(const Duration(days: 28)),
        businessCategory: 'clinic'),
      Contact(id: 'c-010', name: '林志远', company: '台北生技股份有限公司', position: 'CEO',
        phone: '+886-2-8888-0001', email: 'lin@taipei-biotech.tw', address: '台北市信义区',
        industry: Industry.healthcare, strength: RelationshipStrength.warm, myRelation: MyRelationType.agent,
        notes: '台湾区NMN代理意向', tags: ['代理', '台湾'],
        createdAt: now.subtract(const Duration(days: 225)), lastContactedAt: now.subtract(const Duration(days: 4)),
        businessCategory: 'agent'),
    ];
  }

  List<Deal> _builtInDeals() {
    final now = DateTime.now();
    return [
      Deal(id: 'd-001', title: '上海泰康 外泌体300亿 代理批发', description: '华东区首批500瓶试销',
        contactId: 'c-001', contactName: '张伟', stage: DealStage.negotiation, amount: 7500000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 72)), expectedCloseDate: now.add(const Duration(days: 33)),
        updatedAt: now.subtract(const Duration(days: 1)), probability: 70, tags: ['代理', '华东']),
      Deal(id: 'd-002', title: '六本木诊所 注射液月度订单', description: '月度20支外泌体注射液',
        contactId: 'c-002', contactName: 'Dr. 田中美咲', stage: DealStage.ordered, amount: 2800000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 88)), expectedCloseDate: now.add(const Duration(days: 17)),
        updatedAt: now.subtract(const Duration(hours: 6)), probability: 95, tags: ['诊所', '月度']),
      Deal(id: 'd-003', title: '深圳健康优选 NMN跨境电商', description: 'NMN胶囊首批200瓶',
        contactId: 'c-003', contactName: '李明', stage: DealStage.proposal, amount: 1800000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 32)), expectedCloseDate: now.add(const Duration(days: 49)),
        updatedAt: now.subtract(const Duration(days: 3)), probability: 40, tags: ['零售', '电商']),
      Deal(id: 'd-004', title: '悦颜医美 外泌体面膜+注射液', description: '3家连锁诊所月度采购',
        contactId: 'c-005', contactName: '王芳', stage: DealStage.ordered, amount: 3000000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 114)), expectedCloseDate: now.add(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 2)), probability: 90, tags: ['诊所', '连锁']),
      Deal(id: 'd-005', title: 'Pacific Health 北美独家代理', description: '北美市场独家代理权谈判',
        contactId: 'c-006', contactName: 'Mike Chen', stage: DealStage.contacted, amount: 50000000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 22)), expectedCloseDate: now.add(const Duration(days: 139)),
        updatedAt: now.subtract(const Duration(days: 12)), probability: 15, tags: ['北美', '独家']),
      Deal(id: 'd-006', title: '银座美容院 面膜试用采购', description: '高端外泌体面膜试用装',
        contactId: 'c-007', contactName: '山本真由美', stage: DealStage.proposal, amount: 400000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 17)), expectedCloseDate: now.add(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 6)), probability: 55, tags: ['诊所', '面膜']),
      Deal(id: 'd-007', title: '台北生技 NMN Premium 台湾代理', description: '台湾区NMN全线产品独家代理',
        contactId: 'c-010', contactName: '林志远', stage: DealStage.negotiation, amount: 12000000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 58)), expectedCloseDate: now.add(const Duration(days: 64)),
        updatedAt: now.subtract(const Duration(days: 4)), probability: 50, tags: ['代理', '台湾']),
    ];
  }

  /// 预设联系人关系数据
  List<ContactRelation> _builtInRelations() => [
    // 张伟(c-001) ↔ 王芳(c-005): 行业同行，都是医美渠道
    ContactRelation(
      id: 'rel-001', fromContactId: 'c-001', toContactId: 'c-005',
      fromName: '张伟', toName: '王芳', relationType: '同行/同业',
      strength: RelationStrength.strong, isBidirectional: true,
      description: '华东医美圈核心人脉，互相推荐客户',
      tags: ['商业伙伴', '行业联盟'],
    ),
    // Dr.田中(c-002) ↔ 山本真由美(c-007): 东京美容圈同业
    ContactRelation(
      id: 'rel-002', fromContactId: 'c-002', toContactId: 'c-007',
      fromName: 'Dr. 田中美咲', toName: '山本真由美', relationType: '同行/同业',
      strength: RelationStrength.normal, isBidirectional: true,
      description: '东京美容医疗圈，偶尔转介客户',
      tags: ['商业伙伴', '同事'],
    ),
    // 佐藤(c-004) → 田中(c-002): 佐藤介绍田中
    ContactRelation(
      id: 'rel-003', fromContactId: 'c-004', toContactId: 'c-002',
      fromName: '佐藤健一', toName: 'Dr. 田中美咲', relationType: '介绍人-被介绍人',
      strength: RelationStrength.strong, isBidirectional: false,
      description: '佐藤理事将田中院长介绍给我们',
      tags: ['引荐人'],
    ),
    // 佐藤(c-004) → 山本(c-007): 佐藤也介绍了山本
    ContactRelation(
      id: 'rel-004', fromContactId: 'c-004', toContactId: 'c-007',
      fromName: '佐藤健一', toName: '山本真由美', relationType: '介绍人-被介绍人',
      strength: RelationStrength.normal, isBidirectional: false,
      description: '美容协会推荐银座Beauty Lab',
      tags: ['引荐人', '行业联盟'],
    ),
    // 张伟(c-001) ↔ 李明(c-003): 上下游关系
    ContactRelation(
      id: 'rel-005', fromContactId: 'c-001', toContactId: 'c-003',
      fromName: '张伟', toName: '李明', relationType: '客户-供应商',
      strength: RelationStrength.normal, isBidirectional: true,
      description: '张伟代理产品部分通过李明的电商渠道分销',
      tags: ['上下游', '商业伙伴'],
    ),
    // Mike Chen(c-006) ↔ 林志远(c-010): 海外同业
    ContactRelation(
      id: 'rel-006', fromContactId: 'c-006', toContactId: 'c-010',
      fromName: 'Mike Chen', toName: '林志远', relationType: '同行/同业',
      strength: RelationStrength.weak, isBidirectional: true,
      description: '北美-台湾保健品行业联系',
      tags: ['商业伙伴'],
    ),
    // 王芳(c-005) → 赵大力(c-008): 王芳介绍赵大力
    ContactRelation(
      id: 'rel-007', fromContactId: 'c-005', toContactId: 'c-008',
      fromName: '王芳', toName: '赵大力', relationType: '介绍人-被介绍人',
      strength: RelationStrength.normal, isBidirectional: false,
      description: '悦颜医美推荐成都康复堂作为线下渠道',
      tags: ['引荐人', '上下游'],
    ),
    // 金相哲(c-009) ↔ Dr.田中(c-002): 中日韩美容医疗交流
    ContactRelation(
      id: 'rel-008', fromContactId: 'c-009', toContactId: 'c-002',
      fromName: '金相哲', toName: 'Dr. 田中美咲', relationType: '同行/同业',
      strength: RelationStrength.weak, isBidirectional: true,
      description: '中日韩皮肤医疗学术交流认识',
      tags: ['行业联盟', '同事'],
    ),
    // 张伟(c-001) ↔ 林志远(c-010): 两岸代理商联盟
    ContactRelation(
      id: 'rel-009', fromContactId: 'c-001', toContactId: 'c-010',
      fromName: '张伟', toName: '林志远', relationType: '渠道伙伴',
      strength: RelationStrength.strong, isBidirectional: true,
      description: '华东+台湾联合代理战略伙伴',
      tags: ['商业伙伴', '行业联盟'],
    ),
    // 佐藤(c-004) ↔ 金相哲(c-009): 行业协会交流
    ContactRelation(
      id: 'rel-010', fromContactId: 'c-004', toContactId: 'c-009',
      fromName: '佐藤健一', toName: '金相哲', relationType: '行业协会',
      strength: RelationStrength.weak, isBidirectional: true,
      description: '亚洲美容医疗协会理事成员',
      tags: ['行业联盟'],
    ),
  ];
}
