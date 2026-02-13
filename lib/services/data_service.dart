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
import '../services/sync_service.dart';

/// DataService v22: 全量CRUD → Hive持久化 + Firestore云同步
/// 核心修改: 每个CRUD操作自动写入Hive，防止更新后数据消失
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
  List<InventoryRecord> _inventoryCache = [];
  List<TeamMember> _teamCache = [];
  List<Task> _taskCache = [];
  List<ContactAssignment> _assignmentCache = [];
  List<ProductionFactory> _factoryCache = [];
  List<ProductionOrder> _productionCache = [];

  // SyncService reference for Hive persistence
  SyncService? _syncService;
  void setSyncService(SyncService s) => _syncService = s;

  /// 通用Hive持久化辅助 - 每次CRUD自动调用
  Future<void> _persistToHive(String collection, String docId, Map<String, dynamic> data) async {
    try {
      // 统一注入 updatedAt 时间戳，确保多端同步 merge 正确
      final syncData = Map<String, dynamic>.from(data);
      syncData['updatedAt'] = DateTime.now().toIso8601String();
      await _syncService?.put(collection, docId, syncData);
    } catch (e) {
      if (kDebugMode) debugPrint('[DataService] Hive persist error ($collection/$docId): $e');
    }
  }

  Future<void> _deleteFromHive(String collection, String docId) async {
    try {
      await _syncService?.delete(collection, docId);
    } catch (e) {
      if (kDebugMode) debugPrint('[DataService] Hive delete error ($collection/$docId): $e');
    }
  }

  // ========== Team CRUD (with Hive) ==========
  List<TeamMember> getAllTeamMembers() => List.from(_teamCache);
  TeamMember? getTeamMember(String id) {
    try { return _teamCache.firstWhere((m) => m.id == id); } catch (_) { return null; }
  }
  Future<void> addTeamMember(TeamMember member) async {
    _teamCache.add(member);
    await _persistToHive('team', member.id, member.toJson());
    _firestoreWrite('team', member.id, member.toJson());
  }
  Future<void> updateTeamMember(TeamMember member) async {
    final idx = _teamCache.indexWhere((m) => m.id == member.id);
    if (idx >= 0) _teamCache[idx] = member;
    await _persistToHive('team', member.id, member.toJson());
    _firestoreWrite('team', member.id, member.toJson());
  }
  Future<void> deleteTeamMember(String id) async {
    _teamCache.removeWhere((m) => m.id == id);
    await _deleteFromHive('team', id);
    _firestoreDelete('team', id);
  }

  // ========== Task CRUD (with Hive) ==========
  List<Task> getAllTasks() => List.from(_taskCache);
  List<Task> getTasksByAssignee(String assigneeId) => _taskCache.where((t) => t.assigneeId == assigneeId).toList();
  List<Task> getTasksByDate(DateTime date) =>
      _taskCache.where((t) => t.dueDate.year == date.year && t.dueDate.month == date.month && t.dueDate.day == date.day).toList();
  Future<void> addTask(Task task) async {
    _taskCache.add(task);
    await _persistToHive('tasks', task.id, task.toJson());
    _firestoreWrite('tasks', task.id, task.toJson());
  }
  Future<void> updateTask(Task task) async {
    final idx = _taskCache.indexWhere((t) => t.id == task.id);
    if (idx >= 0) _taskCache[idx] = task;
    await _persistToHive('tasks', task.id, task.toJson());
    _firestoreWrite('tasks', task.id, task.toJson());
  }
  Future<void> deleteTask(String id) async {
    _taskCache.removeWhere((t) => t.id == id);
    await _deleteFromHive('tasks', id);
    _firestoreDelete('tasks', id);
  }

  // ========== Contact Assignment CRUD (with Hive) ==========
  List<ContactAssignment> getAllAssignments() => List.from(_assignmentCache);
  List<ContactAssignment> getAssignmentsByContact(String contactId) =>
      _assignmentCache.where((a) => a.contactId == contactId).toList();
  List<ContactAssignment> getAssignmentsByMember(String memberId) =>
      _assignmentCache.where((a) => a.memberId == memberId).toList();
  Future<void> addAssignment(ContactAssignment assignment) async {
    _assignmentCache.add(assignment);
    await _persistToHive('assignments', assignment.id, assignment.toJson());
    _firestoreWrite('assignments', assignment.id, assignment.toJson());
  }
  Future<void> updateAssignment(ContactAssignment assignment) async {
    final idx = _assignmentCache.indexWhere((a) => a.id == assignment.id);
    if (idx >= 0) _assignmentCache[idx] = assignment;
    await _persistToHive('assignments', assignment.id, assignment.toJson());
    _firestoreWrite('assignments', assignment.id, assignment.toJson());
  }
  Future<void> deleteAssignment(String id) async {
    _assignmentCache.removeWhere((a) => a.id == id);
    await _deleteFromHive('assignments', id);
    _firestoreDelete('assignments', id);
  }

  // ========== Factory CRUD (with Hive) ==========
  List<ProductionFactory> getAllFactories() => List.from(_factoryCache);
  ProductionFactory? getFactory(String id) {
    try { return _factoryCache.firstWhere((f) => f.id == id); } catch (_) { return null; }
  }
  Future<void> addFactory(ProductionFactory factory) async {
    _factoryCache.add(factory);
    await _persistToHive('factories', factory.id, factory.toJson());
    _firestoreWrite('factories', factory.id, factory.toJson());
  }
  Future<void> updateFactory(ProductionFactory factory) async {
    final idx = _factoryCache.indexWhere((f) => f.id == factory.id);
    if (idx >= 0) _factoryCache[idx] = factory;
    await _persistToHive('factories', factory.id, factory.toJson());
    _firestoreWrite('factories', factory.id, factory.toJson());
  }
  Future<void> deleteFactory(String id) async {
    _factoryCache.removeWhere((f) => f.id == id);
    await _deleteFromHive('factories', id);
    _firestoreDelete('factories', id);
  }

  // ========== ProductionOrder CRUD (with Hive) ==========
  List<ProductionOrder> getAllProductionOrders() => List.from(_productionCache);
  ProductionOrder? getProductionOrder(String id) {
    try { return _productionCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
  List<ProductionOrder> getProductionByFactory(String factoryId) => _productionCache.where((p) => p.factoryId == factoryId).toList();
  List<ProductionOrder> getProductionByProduct(String productId) => _productionCache.where((p) => p.productId == productId).toList();
  List<ProductionOrder> getProductionByStatus(String status) => _productionCache.where((p) => p.status == status).toList();
  List<ProductionOrder> getActiveProductions() => _productionCache.where((p) => ProductionStatus.activeStatuses.contains(p.status)).toList();
  Future<void> addProductionOrder(ProductionOrder order) async {
    _productionCache.add(order);
    await _persistToHive('production', order.id, order.toJson());
    _firestoreWrite('production', order.id, order.toJson());
  }
  Future<void> updateProductionOrder(ProductionOrder order) async {
    final idx = _productionCache.indexWhere((p) => p.id == order.id);
    if (idx >= 0) _productionCache[idx] = order;
    await _persistToHive('production', order.id, order.toJson());
    _firestoreWrite('production', order.id, order.toJson());
  }
  Future<void> deleteProductionOrder(String id) async {
    _productionCache.removeWhere((p) => p.id == id);
    await _deleteFromHive('production', id);
    _firestoreDelete('production', id);
  }

  // ========== Completed Tasks History ==========
  List<Task> getCompletedTasks() =>
      _taskCache.where((t) => t.phase == TaskPhase.completed).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));
  List<Task> getTasksByPhase(TaskPhase phase) => _taskCache.where((t) => t.phase == phase).toList();
  Map<String, double> getWorkloadStats() {
    final stats = <String, double>{};
    for (final t in _taskCache) {
      stats[t.assigneeName] = (stats[t.assigneeName] ?? 0) + (t.actualHours > 0 ? t.actualHours : t.estimatedHours);
    }
    return stats;
  }

  // ========== Init: 只加载系统配置（产品/工厂/团队），业务数据从云端拉取 ==========
  Future<void> init() async {
    // 系统配置：产品目录、工厂、团队（这些是固定配置不是业务数据）
    _productsCache = _builtInProducts();
    _factoryCache.addAll(_builtInFactories());
    _teamCache.addAll(_builtInTeam());
    // 业务数据（联系人/交易/关系/订单等）初始化为空
    // 登录后从 Firestore 拉取，确保所有用户看到同一份实时数据
    _contactsCache = [];
    _dealsCache = [];
    _relationsCache = [];
    _ordersCache = [];
    _inventoryCache = [];
    _interactionsCache = [];
    _taskCache = [];
    _assignmentCache = [];
    _productionCache = [];

    if (kDebugMode) {
      debugPrint('[DataService] Init: ${_productsCache.length} products, ${_factoryCache.length} factories, ${_teamCache.length} team (business data empty, awaiting cloud sync)');
    }
  }

  /// 从 Hive 恢复持久化数据
  /// 在 SyncService.init() 之后调用
  Future<void> loadFromHive(SyncService sync) async {
    _syncService = sync;

    // 业务数据: Hive有数据则加载，无则保持空（不回退到种子数据）
    _contactsCache = _loadCollection<Contact>(sync, 'contacts', Contact.fromJson) ?? [];
    _dealsCache = _loadCollection<Deal>(sync, 'deals', Deal.fromJson) ?? [];
    _interactionsCache = _loadCollection<Interaction>(sync, 'interactions', Interaction.fromJson) ?? [];
    _relationsCache = _loadCollection<ContactRelation>(sync, 'relations', ContactRelation.fromJson) ?? [];
    _ordersCache = _loadCollection<SalesOrder>(sync, 'sales_orders', SalesOrder.fromJson) ?? [];
    _inventoryCache = _loadCollection<InventoryRecord>(sync, 'inventory', InventoryRecord.fromJson) ?? [];
    _taskCache = _loadCollection<Task>(sync, 'tasks', Task.fromJson) ?? [];
    _assignmentCache = _loadCollection<ContactAssignment>(sync, 'assignments', ContactAssignment.fromJson) ?? [];
    _productionCache = _loadCollection<ProductionOrder>(sync, 'production', ProductionOrder.fromJson) ?? [];

    // 系统配置: Hive有数据则用Hive版本，无则保留内置
    final hiveProducts = _loadCollection<Product>(sync, 'products', Product.fromJson);
    if (hiveProducts != null && hiveProducts.isNotEmpty) _productsCache = hiveProducts;
    final hiveTeam = _loadCollection<TeamMember>(sync, 'team', TeamMember.fromJson);
    if (hiveTeam != null && hiveTeam.isNotEmpty) {
      _teamCache.clear();
      _teamCache.addAll(hiveTeam);
    }
    final hiveFactories = _loadCollection<ProductionFactory>(sync, 'factories', ProductionFactory.fromJson);
    if (hiveFactories != null && hiveFactories.isNotEmpty) {
      _factoryCache.clear();
      _factoryCache.addAll(hiveFactories);
    }

    if (kDebugMode) {
      debugPrint('[DataService] After Hive load: ${_contactsCache.length} contacts, ${_dealsCache.length} deals, ${_ordersCache.length} orders, ${_productsCache.length} products');
    }
  }

  /// 从 SyncService (Hive) 加载集合
  List<T>? _loadCollection<T>(SyncService sync, String collection, T Function(Map<String, dynamic>) fromJson) {
    try {
      final rawList = sync.getAll(collection);
      if (rawList.isEmpty) return null;
      final items = rawList.map((m) {
        try { return fromJson(m); } catch (_) { return null; }
      }).whereType<T>().toList();
      return items.isNotEmpty ? items : null;
    } catch (e) {
      if (kDebugMode) debugPrint('[DataService] Failed to load $collection from Hive: $e');
      return null;
    }
  }

  // ========== Contact CRUD (with Hive) ==========
  List<Contact> getAllContacts() => List.from(_contactsCache);
  Contact? getContact(String id) {
    try { return _contactsCache.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }
  Future<void> saveContact(Contact contact) async {
    final idx = _contactsCache.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) { _contactsCache[idx] = contact; } else { _contactsCache.add(contact); }
    await _persistToHive('contacts', contact.id, contact.toJson());
    _firestoreWrite('contacts', contact.id, contact.toJson());
  }
  Future<void> deleteContact(String id) async {
    _contactsCache.removeWhere((c) => c.id == id);
    _interactionsCache.removeWhere((i) => i.contactId == id);
    _relationsCache.removeWhere((r) => r.fromContactId == id || r.toContactId == id);
    await _deleteFromHive('contacts', id);
    _firestoreDelete('contacts', id);
  }

  // ========== Relation CRUD (with Hive) ==========
  List<ContactRelation> getAllRelations() => List.from(_relationsCache);
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relationsCache.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();
  Future<void> saveRelation(ContactRelation relation) async {
    final idx = _relationsCache.indexWhere((r) => r.id == relation.id);
    if (idx >= 0) { _relationsCache[idx] = relation; } else { _relationsCache.add(relation); }
    await _persistToHive('relations', relation.id, relation.toJson());
    _firestoreWrite('relations', relation.id, relation.toJson());
  }
  Future<void> deleteRelation(String id) async {
    _relationsCache.removeWhere((r) => r.id == id);
    await _deleteFromHive('relations', id);
    _firestoreDelete('relations', id);
  }

  // ========== Deal CRUD (with Hive) ==========
  List<Deal> getAllDeals() => List.from(_dealsCache);
  List<Deal> getDealsByStage(DealStage stage) => _dealsCache.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _dealsCache.where((d) => d.contactId == contactId).toList();
  Future<void> saveDeal(Deal deal) async {
    final idx = _dealsCache.indexWhere((d) => d.id == deal.id);
    if (idx >= 0) { _dealsCache[idx] = deal; } else { _dealsCache.add(deal); }
    await _persistToHive('deals', deal.id, deal.toJson());
    _firestoreWrite('deals', deal.id, deal.toJson());
  }
  Future<void> deleteDeal(String id) async {
    _dealsCache.removeWhere((d) => d.id == id);
    await _deleteFromHive('deals', id);
    _firestoreDelete('deals', id);
  }

  // ========== Interaction CRUD (with Hive) ==========
  List<Interaction> getAllInteractions() => List.from(_interactionsCache);
  List<Interaction> getInteractionsByContact(String contactId) =>
      _interactionsCache.where((i) => i.contactId == contactId).toList();
  Future<void> saveInteraction(Interaction interaction) async {
    final idx = _interactionsCache.indexWhere((i) => i.id == interaction.id);
    if (idx >= 0) { _interactionsCache[idx] = interaction; } else { _interactionsCache.add(interaction); }
    await _persistToHive('interactions', interaction.id, interaction.toJson());
    _firestoreWrite('interactions', interaction.id, interaction.toJson());
  }
  Future<void> deleteInteraction(String id) async {
    _interactionsCache.removeWhere((i) => i.id == id);
    await _deleteFromHive('interactions', id);
    _firestoreDelete('interactions', id);
  }

  // ========== Product CRUD (with Hive) ==========
  List<Product> getAllProducts() => List.from(_productsCache);
  List<Product> getProductsByCategory(String category) => _productsCache.where((p) => p.category == category).toList();
  Product? getProduct(String id) {
    try { return _productsCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
  Future<void> saveProduct(Product product) async {
    final idx = _productsCache.indexWhere((p) => p.id == product.id);
    if (idx >= 0) { _productsCache[idx] = product; } else { _productsCache.add(product); }
    await _persistToHive('products', product.id, product.toJson());
    _firestoreWrite('products', product.id, product.toJson());
  }
  Future<void> deleteProduct(String id) async {
    _productsCache.removeWhere((p) => p.id == id);
    await _deleteFromHive('products', id);
    _firestoreDelete('products', id);
  }

  // ========== Sales Order CRUD (with Hive) ==========
  List<SalesOrder> getAllOrders() => List.from(_ordersCache);
  List<SalesOrder> getOrdersByContact(String contactId) => _ordersCache.where((o) => o.contactId == contactId).toList();
  Future<void> saveOrder(SalesOrder order) async {
    final idx = _ordersCache.indexWhere((o) => o.id == order.id);
    if (idx >= 0) { _ordersCache[idx] = order; } else { _ordersCache.add(order); }
    await _persistToHive('sales_orders', order.id, order.toJson());
    _firestoreWrite('sales_orders', order.id, order.toJson());
  }
  Future<void> deleteOrder(String id) async {
    _ordersCache.removeWhere((o) => o.id == id);
    await _deleteFromHive('sales_orders', id);
    _firestoreDelete('sales_orders', id);
  }

  // ========== Inventory CRUD (with Hive) ==========
  List<InventoryRecord> getAllInventory() => List.from(_inventoryCache);
  List<InventoryRecord> getInventoryByProduct(String productId) =>
      _inventoryCache.where((r) => r.productId == productId).toList();
  Future<void> addInventoryRecord(InventoryRecord record) async {
    _inventoryCache.add(record);
    await _persistToHive('inventory', record.id, record.toJson());
    _firestoreWrite('inventory', record.id, record.toJson());
  }
  Future<void> deleteInventoryRecord(String id) async {
    _inventoryCache.removeWhere((r) => r.id == id);
    await _deleteFromHive('inventory', id);
    _firestoreDelete('inventory', id);
  }

  List<InventoryStock> getInventoryStocks() {
    final stockMap = <String, InventoryStock>{};
    for (final p in _productsCache) {
      stockMap[p.id] = InventoryStock(productId: p.id, productName: p.name, productCode: p.code, currentStock: 0);
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
    // 收款统计
    double totalPaid = 0;
    int paidOrderCount = 0;
    for (final o in _ordersCache) {
      totalPaid += o.paidAmount;
      if (o.isFullyPaid) paidOrderCount++;
    }
    return {
      'totalContacts': contacts.length, 'activeDeals': activeDeals.length,
      'pipelineValue': pipelineValue, 'closedValue': closedValue,
      'closedDeals': closedDeals.length,
      'winRate': deals.isNotEmpty ? (closedDeals.length / deals.length * 100) : 0.0,
      'industryCount': industryCount, 'stageCount': stageCount,
      'hotContacts': contacts.where((c) => c.strength == RelationshipStrength.hot).length,
      'totalProducts': _productsCache.length, 'totalOrders': _ordersCache.length,
      'completedOrders': orderCount, 'salesTotal': salesTotal,
      'totalPaid': totalPaid, 'paidOrderCount': paidOrderCount,
      'totalInventoryRecords': _inventoryCache.length,
      'totalFactories': _factoryCache.length,
      'activeFactories': _factoryCache.where((f) => f.isActive).length,
      'totalProductionOrders': _productionCache.length,
      'activeProductions': _productionCache.where((p) => ProductionStatus.activeStatuses.contains(p.status)).length,
      'completedProductions': _productionCache.where((p) => p.status == ProductionStatus.completed).length,
    };
  }

  String generateId() => _uuid.v4();

  // ========== 管理员备份/恢复 (Firestore backups 集合) ==========
  Future<void> saveBackup(String backupId, Map<String, dynamic> backupData) async {
    if (!_firestoreEnabled || _db == null) throw Exception('Firestore未启用');
    await _db!.collection('backups').doc(backupId).set(backupData)
        .timeout(const Duration(seconds: 25));
  }

  Future<List<Map<String, dynamic>>> getBackupList() async {
    if (!_firestoreEnabled || _db == null) throw Exception('Firestore未启用');
    final snap = await _db!.collection('backups')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get()
        .timeout(const Duration(seconds: 8));
    return snap.docs.map((d) => {
      'id': d.id,
      'timestamp': d.data()['timestamp'] as String? ?? '',
      'createdBy': d.data()['createdBy'] as String? ?? '',
      'summary': d.data()['summary'] as String? ?? '',
    }).toList();
  }

  Future<void> restoreFromBackup(String backupId) async {
    if (!_firestoreEnabled || _db == null) throw Exception('Firestore未启用');
    final doc = await _db!.collection('backups').doc(backupId).get()
        .timeout(const Duration(seconds: 15));
    if (!doc.exists) throw Exception('备份不存在');

    final data = doc.data()!['data'] as Map<String, dynamic>? ?? {};
    
    // 恢复每个集合
    if (data['contacts'] is List) {
      _contactsCache = (data['contacts'] as List).map((j) {
        try { return Contact.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<Contact>().toList();
    }
    if (data['deals'] is List) {
      _dealsCache = (data['deals'] as List).map((j) {
        try { return Deal.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<Deal>().toList();
    }
    if (data['relations'] is List) {
      _relationsCache = (data['relations'] as List).map((j) {
        try { return ContactRelation.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<ContactRelation>().toList();
    }
    if (data['products'] is List) {
      _productsCache = (data['products'] as List).map((j) {
        try { return Product.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<Product>().toList();
    }
    if (data['sales_orders'] is List) {
      _ordersCache = (data['sales_orders'] as List).map((j) {
        try { return SalesOrder.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<SalesOrder>().toList();
    }
    if (data['interactions'] is List) {
      _interactionsCache = (data['interactions'] as List).map((j) {
        try { return Interaction.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<Interaction>().toList();
    }
    if (data['inventory'] is List) {
      _inventoryCache = (data['inventory'] as List).map((j) {
        try { return InventoryRecord.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<InventoryRecord>().toList();
    }
    if (data['team'] is List) {
      _teamCache = (data['team'] as List).map((j) {
        try { return TeamMember.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<TeamMember>().toList();
    }
    if (data['tasks'] is List) {
      _taskCache = (data['tasks'] as List).map((j) {
        try { return Task.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<Task>().toList();
    }
    if (data['assignments'] is List) {
      _assignmentCache = (data['assignments'] as List).map((j) {
        try { return ContactAssignment.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<ContactAssignment>().toList();
    }
    if (data['factories'] is List) {
      _factoryCache = (data['factories'] as List).map((j) {
        try { return ProductionFactory.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<ProductionFactory>().toList();
    }
    if (data['production'] is List) {
      _productionCache = (data['production'] as List).map((j) {
        try { return ProductionOrder.fromJson(j as Map<String, dynamic>); } catch (_) { return null; }
      }).whereType<ProductionOrder>().toList();
    }

    if (kDebugMode) debugPrint('[DataService] Restored from backup: $backupId');
  }

  // ========== Firestore 辅助方法 ==========
  void _firestoreWrite(String collection, String docId, Map<String, dynamic> data) {
    if (!_firestoreEnabled || _db == null) return;
    // 统一注入 updatedAt 时间戳，确保多端同步 merge 正确
    final syncData = Map<String, dynamic>.from(data);
    syncData['updatedAt'] = DateTime.now().toIso8601String();
    _db!.collection(collection).doc(docId).set(syncData).catchError((e) {
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
    const t = Duration(seconds: 8);

    Future<List<T>> pullCol<T>(String col, T Function(Map<String, dynamic>) fromJson) async {
      try {
        final snap = await _db!.collection(col).get().timeout(t);
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) {
            try { return fromJson(d.data()); } catch (_) { return null; }
          }).whereType<T>().toList();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[DataService] syncFromCloud pull $col error: $e');
      }
      return [];
    }

    try {
      // 云端数据直接替换本地（包括空数据 = 清空本地）
      _contactsCache = await pullCol<Contact>('contacts', Contact.fromJson);
      _dealsCache = await pullCol<Deal>('deals', Deal.fromJson);
      _relationsCache = await pullCol<ContactRelation>('relations', ContactRelation.fromJson);
      _ordersCache = await pullCol<SalesOrder>('sales_orders', SalesOrder.fromJson);
      _inventoryCache = await pullCol<InventoryRecord>('inventory', InventoryRecord.fromJson);
      _interactionsCache = await pullCol<Interaction>('interactions', Interaction.fromJson);
      _assignmentCache = await pullCol<ContactAssignment>('assignments', ContactAssignment.fromJson);
      _productionCache = await pullCol<ProductionOrder>('production', ProductionOrder.fromJson);

      // 产品/工厂/团队：云端有则替换，无则保留内置配置
      var prods = await pullCol<Product>('products', Product.fromJson);
      if (prods.isNotEmpty) _productsCache = prods;

      var team = await pullCol<TeamMember>('team', TeamMember.fromJson);
      if (team.isNotEmpty) _teamCache = team;

      var tasks = await pullCol<Task>('tasks', Task.fromJson);
      if (tasks.isNotEmpty) _taskCache = tasks;

      var facs = await pullCol<ProductionFactory>('factories', ProductionFactory.fromJson);
      if (facs.isNotEmpty) _factoryCache = facs;

      if (kDebugMode) {
        debugPrint('[DataService] Cloud sync complete: ${_contactsCache.length} contacts, ${_dealsCache.length} deals, ${_ordersCache.length} orders');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DataService] syncFromCloud error: $e');
    }
  }

  // ========== 按PDF定价表更新的产品目录 (Regenecolla製品定価表) ==========
  List<Product> _builtInProducts() => [
    Product(id: 'prod-exo-001', code: 'NS-EX0-001', name: '外泌体冻干粉 300亿', nameJa: 'エクソソーム凍結乾燥粉末 300億単位', category: 'exosome',
      description: '高纯度外泌体冻干粉，含300亿单位外泌体粒子(臍帯由来)。适用于肌肤再生、抗老化治疗。',
      specification: '300億単位/瓶', unitsPerBox: 5,
      agentPrice: 30000, clinicPrice: 40000, retailPrice: 100000,
      agentTotalPrice: 150000, clinicTotalPrice: 200000, retailTotalPrice: 500000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴/局部注射',
      notes: '代理折扣30%、诊所折扣40% | 点滴/注射用フリーズドライシリーズ'),
    Product(id: 'prod-exo-002', code: 'NS-EX0-002', name: '外泌体冻干粉 500亿', nameJa: 'エクソソーム凍結乾燥粉末 500億単位', category: 'exosome',
      description: '高浓度外泌体冻干粉，含500亿单位外泌体粒子(臍帯由来)。',
      specification: '500億単位/瓶', unitsPerBox: 5,
      agentPrice: 45000, clinicPrice: 60000, retailPrice: 150000,
      agentTotalPrice: 225000, clinicTotalPrice: 300000, retailTotalPrice: 750000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴/局部注射',
      notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-exo-003', code: 'NS-EX0-003', name: '外泌体冻干粉 1000亿', nameJa: 'エクソソーム凍結乾燥粉末 1000億単位', category: 'exosome',
      description: '超高浓度外泌体冻干粉，含1000亿单位外泌体粒子(臍帯由来)。顶级配方。',
      specification: '1000億単位/瓶', unitsPerBox: 5,
      agentPrice: 105000, clinicPrice: 140000, retailPrice: 350000,
      agentTotalPrice: 525000, clinicTotalPrice: 700000, retailTotalPrice: 1750000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴/局部注射',
      notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-nad-001', code: 'NS-NAD-001', name: 'NAD+ 注射液 250mg', nameJa: 'NAD+ 注射液 250mg', category: 'nad',
      description: '高纯度NAD+注射液，每瓶含250mg NAD+。促进细胞能量代谢。',
      specification: '250mg/瓶', unitsPerBox: 5,
      agentPrice: 12000, clinicPrice: 16000, retailPrice: 40000,
      agentTotalPrice: 60000, clinicTotalPrice: 80000, retailTotalPrice: 200000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脉注射/点滴',
      notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-nmn-001', code: 'NS-NMN-001', name: 'NMN 点鼻/吸入 700mg', nameJa: 'NMN 点鼻・吸入 700mg', category: 'nmn',
      description: 'NMN700mg点鼻/吸入制剂。4バイアルNMN + 4バイアル溶剤。生物利用度高。',
      specification: '4バイアルNMN+4バイアル溶剤', unitsPerBox: 1,
      agentPrice: 22000, clinicPrice: 32000, retailPrice: 60000,
      agentTotalPrice: 22000, clinicTotalPrice: 32000, retailTotalPrice: 60000,
      storageMethod: '常温保存', shelfLife: '2年', usage: '点鼻/吸入使用',
      notes: 'NMN 700mg配合 | 包装: 4バイアルNMN＋4バイアル溶剤'),
    Product(id: 'prod-nmn-002', code: 'NS-NMN-002', name: 'NMN 胶囊 15000', nameJa: 'NMNサプリメント15000 カプセル', category: 'nmn',
      description: 'NMN口服胶囊 (NMNサプリメント15000)。每盒含高纯度NMN。',
      specification: 'カプセル/盒', unitsPerBox: 1,
      agentPrice: 9000, clinicPrice: 12000, retailPrice: 30000,
      agentTotalPrice: 9000, clinicTotalPrice: 12000, retailTotalPrice: 20000,
      storageMethod: '常温保存', shelfLife: '2年', usage: '每日1-2粒，口服',
      notes: 'NMNサプリメント15000 | 销售总价¥20,000(PDF定价)'),
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

  // 种子业务数据已移除 - 所有业务数据（联系人/交易/关系）从Firestore云端获取
  // 确保多用户协作时数据一致性
}
