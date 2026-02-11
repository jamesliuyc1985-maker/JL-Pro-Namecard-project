import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/team.dart';
import '../models/task.dart';
import '../models/contact_assignment.dart';
import '../models/factory.dart';

class DataService {
  static const _uuid = Uuid();
  late FirebaseFirestore _db;

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
    await _db.collection('team_members').doc(member.id).set(member.toJson());
  }
  Future<void> updateTeamMember(TeamMember member) async {
    final idx = _teamCache.indexWhere((m) => m.id == member.id);
    if (idx >= 0) _teamCache[idx] = member;
    await _db.collection('team_members').doc(member.id).set(member.toJson());
  }
  Future<void> deleteTeamMember(String id) async {
    _teamCache.removeWhere((m) => m.id == id);
    await _db.collection('team_members').doc(id).delete();
  }

  // ========== Task CRUD ==========
  List<Task> getAllTasks() => List.from(_taskCache);
  List<Task> getTasksByAssignee(String assigneeId) =>
      _taskCache.where((t) => t.assigneeId == assigneeId).toList();
  List<Task> getTasksByDate(DateTime date) =>
      _taskCache.where((t) => t.dueDate.year == date.year && t.dueDate.month == date.month && t.dueDate.day == date.day).toList();
  Future<void> addTask(Task task) async {
    _taskCache.add(task);
    await _db.collection('tasks').doc(task.id).set(task.toJson());
  }
  Future<void> updateTask(Task task) async {
    final idx = _taskCache.indexWhere((t) => t.id == task.id);
    if (idx >= 0) _taskCache[idx] = task;
    await _db.collection('tasks').doc(task.id).set(task.toJson());
  }
  Future<void> deleteTask(String id) async {
    _taskCache.removeWhere((t) => t.id == id);
    await _db.collection('tasks').doc(id).delete();
  }

  // ========== Contact Assignment CRUD ==========
  List<ContactAssignment> getAllAssignments() => List.from(_assignmentCache);
  List<ContactAssignment> getAssignmentsByContact(String contactId) =>
      _assignmentCache.where((a) => a.contactId == contactId).toList();
  List<ContactAssignment> getAssignmentsByMember(String memberId) =>
      _assignmentCache.where((a) => a.memberId == memberId).toList();
  Future<void> addAssignment(ContactAssignment assignment) async {
    _assignmentCache.add(assignment);
    await _db.collection('assignments').doc(assignment.id).set(assignment.toJson());
  }
  Future<void> updateAssignment(ContactAssignment assignment) async {
    final idx = _assignmentCache.indexWhere((a) => a.id == assignment.id);
    if (idx >= 0) _assignmentCache[idx] = assignment;
    await _db.collection('assignments').doc(assignment.id).set(assignment.toJson());
  }
  Future<void> deleteAssignment(String id) async {
    _assignmentCache.removeWhere((a) => a.id == id);
    await _db.collection('assignments').doc(id).delete();
  }

  // ========== Factory CRUD ==========
  List<ProductionFactory> getAllFactories() => List.from(_factoryCache);
  ProductionFactory? getFactory(String id) {
    try { return _factoryCache.firstWhere((f) => f.id == id); } catch (_) { return null; }
  }
  Future<void> addFactory(ProductionFactory factory) async {
    _factoryCache.add(factory);
    await _db.collection('factories').doc(factory.id).set(factory.toJson());
  }
  Future<void> updateFactory(ProductionFactory factory) async {
    final idx = _factoryCache.indexWhere((f) => f.id == factory.id);
    if (idx >= 0) _factoryCache[idx] = factory;
    await _db.collection('factories').doc(factory.id).set(factory.toJson());
  }
  Future<void> deleteFactory(String id) async {
    _factoryCache.removeWhere((f) => f.id == id);
    await _db.collection('factories').doc(id).delete();
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
    await _db.collection('production_orders').doc(order.id).set(order.toJson());
  }
  Future<void> updateProductionOrder(ProductionOrder order) async {
    final idx = _productionCache.indexWhere((p) => p.id == order.id);
    if (idx >= 0) _productionCache[idx] = order;
    await _db.collection('production_orders').doc(order.id).set(order.toJson());
  }
  Future<void> deleteProductionOrder(String id) async {
    _productionCache.removeWhere((p) => p.id == id);
    await _db.collection('production_orders').doc(id).delete();
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

  // ========== Init ==========
  Future<void> init() async {
    _db = FirebaseFirestore.instance;
    await _refreshAllCaches();
  }

  Future<void> _refreshAllCaches() async {
    await Future.wait([
      _refreshContacts(),
      _refreshDeals(),
      _refreshInteractions(),
      _refreshRelations(),
      _refreshProducts(),
      _refreshOrders(),
      _refreshTeamMembers(),
      _refreshTasks(),
      _refreshAssignments(),
      _refreshFactories(),
      _refreshProductionOrders(),
      _refreshInventory(),
    ]);
  }

  Future<void> _refreshContacts() async {
    try {
      final snap = await _db.collection('contacts').get();
      _contactsCache = snap.docs.map((d) => _contactFromDb(d.data())).toList();
      _contactsCache.sort((a, b) => b.lastContactedAt.compareTo(a.lastContactedAt));
    } catch (_) {}
  }

  Future<void> _refreshDeals() async {
    try {
      final snap = await _db.collection('deals').get();
      _dealsCache = snap.docs.map((d) => _dealFromDb(d.data())).toList();
      _dealsCache.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {}
  }

  Future<void> _refreshInteractions() async {
    try {
      final snap = await _db.collection('interactions').get();
      _interactionsCache = snap.docs.map((d) => _interactionFromDb(d.data())).toList();
      _interactionsCache.sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {}
  }

  Future<void> _refreshRelations() async {
    try {
      final snap = await _db.collection('relations').get();
      _relationsCache = snap.docs.map((d) => _relationFromDb(d.data())).toList();
    } catch (_) {}
  }

  Future<void> _refreshProducts() async {
    try {
      final snap = await _db.collection('products').get();
      if (snap.docs.isNotEmpty) {
        _productsCache = snap.docs.map((d) => Product.fromJson(d.data())).toList();
      } else {
        _productsCache = _builtInProducts();
        // Save built-in products to Firestore
        for (final p in _productsCache) {
          await _db.collection('products').doc(p.id).set(p.toJson());
        }
      }
    } catch (_) {
      if (_productsCache.isEmpty) _productsCache = _builtInProducts();
    }
    if (_factoryCache.isEmpty) {
      try {
        final snap = await _db.collection('factories').get();
        if (snap.docs.isNotEmpty) {
          _factoryCache.addAll(snap.docs.map((d) {
            final data = d.data();
            return ProductionFactory(
              id: data['id'] as String? ?? d.id,
              name: data['name'] as String? ?? '',
              nameJa: data['nameJa'] as String? ?? '',
              address: data['address'] as String? ?? '',
              representative: data['representative'] as String? ?? '',
              description: data['description'] as String? ?? '',
              certifications: List<String>.from(data['certifications'] ?? []),
              capabilities: List<String>.from(data['capabilities'] ?? []),
              phone: data['phone'] as String? ?? '',
              email: data['email'] as String? ?? '',
              isActive: data['isActive'] as bool? ?? true,
            );
          }));
        } else {
          _factoryCache.addAll(_builtInFactories());
          for (final f in _factoryCache) {
            await _db.collection('factories').doc(f.id).set(f.toJson());
          }
        }
      } catch (_) {
        if (_factoryCache.isEmpty) _factoryCache.addAll(_builtInFactories());
      }
    }
  }

  Future<void> _refreshOrders() async {
    try {
      final snap = await _db.collection('sales_orders').get();
      _ordersCache = snap.docs.map((d) => SalesOrder.fromJson(d.data())).toList();
      _ordersCache.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {}
  }

  Future<void> _refreshTeamMembers() async {
    try {
      final snap = await _db.collection('team_members').get();
      _teamCache.clear();
      _teamCache.addAll(snap.docs.map((d) => TeamMember.fromJson(d.data())));
    } catch (_) {}
  }

  Future<void> _refreshTasks() async {
    try {
      final snap = await _db.collection('tasks').get();
      _taskCache.clear();
      _taskCache.addAll(snap.docs.map((d) => Task.fromJson(d.data())));
    } catch (_) {}
  }

  Future<void> _refreshAssignments() async {
    try {
      final snap = await _db.collection('assignments').get();
      _assignmentCache.clear();
      _assignmentCache.addAll(snap.docs.map((d) => ContactAssignment.fromJson(d.data())));
    } catch (_) {}
  }

  Future<void> _refreshFactories() async {
    // Handled in _refreshProducts
  }

  Future<void> _refreshProductionOrders() async {
    try {
      final snap = await _db.collection('production_orders').get();
      _productionCache.clear();
      _productionCache.addAll(snap.docs.map((d) => ProductionOrder.fromJson(d.data())));
    } catch (_) {}
  }

  Future<void> _refreshInventory() async {
    try {
      final snap = await _db.collection('inventory').get();
      _inventoryCache.clear();
      _inventoryCache.addAll(snap.docs.map((d) => InventoryRecord.fromJson(d.data())));
    } catch (_) {}
  }

  // ========== Contact CRUD ==========
  List<Contact> getAllContacts() => List.from(_contactsCache);
  Contact? getContact(String id) {
    try { return _contactsCache.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }
  Future<void> saveContact(Contact contact) async {
    await _db.collection('contacts').doc(contact.id).set(_contactToDb(contact));
    final idx = _contactsCache.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) { _contactsCache[idx] = contact; } else { _contactsCache.add(contact); }
  }
  Future<void> deleteContact(String id) async {
    await _db.collection('contacts').doc(id).delete();
    _contactsCache.removeWhere((c) => c.id == id);
    // Clean up related data
    final interactions = _interactionsCache.where((i) => i.contactId == id).toList();
    for (final i in interactions) {
      await _db.collection('interactions').doc(i.id).delete();
    }
    _interactionsCache.removeWhere((i) => i.contactId == id);
    final relations = _relationsCache.where((r) => r.fromContactId == id || r.toContactId == id).toList();
    for (final r in relations) {
      await _db.collection('relations').doc(r.id).delete();
    }
    _relationsCache.removeWhere((r) => r.fromContactId == id || r.toContactId == id);
  }

  // ========== Relation CRUD ==========
  List<ContactRelation> getAllRelations() => List.from(_relationsCache);
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relationsCache.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();
  Future<void> saveRelation(ContactRelation relation) async {
    await _db.collection('relations').doc(relation.id).set(_relationToDb(relation));
    final idx = _relationsCache.indexWhere((r) => r.id == relation.id);
    if (idx >= 0) { _relationsCache[idx] = relation; } else { _relationsCache.add(relation); }
  }
  Future<void> deleteRelation(String id) async {
    await _db.collection('relations').doc(id).delete();
    _relationsCache.removeWhere((r) => r.id == id);
  }

  // ========== Deal CRUD ==========
  List<Deal> getAllDeals() => List.from(_dealsCache);
  List<Deal> getDealsByStage(DealStage stage) => _dealsCache.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _dealsCache.where((d) => d.contactId == contactId).toList();
  Future<void> saveDeal(Deal deal) async {
    await _db.collection('deals').doc(deal.id).set(_dealToDb(deal));
    final idx = _dealsCache.indexWhere((d) => d.id == deal.id);
    if (idx >= 0) { _dealsCache[idx] = deal; } else { _dealsCache.add(deal); }
  }
  Future<void> deleteDeal(String id) async {
    await _db.collection('deals').doc(id).delete();
    _dealsCache.removeWhere((d) => d.id == id);
  }

  // ========== Interaction CRUD ==========
  List<Interaction> getAllInteractions() => List.from(_interactionsCache);
  List<Interaction> getInteractionsByContact(String contactId) =>
      _interactionsCache.where((i) => i.contactId == contactId).toList();
  Future<void> saveInteraction(Interaction interaction) async {
    await _db.collection('interactions').doc(interaction.id).set(_interactionToDb(interaction));
    final idx = _interactionsCache.indexWhere((i) => i.id == interaction.id);
    if (idx >= 0) { _interactionsCache[idx] = interaction; } else { _interactionsCache.add(interaction); }
  }
  Future<void> deleteInteraction(String id) async {
    await _db.collection('interactions').doc(id).delete();
    _interactionsCache.removeWhere((i) => i.id == id);
  }

  // ========== Product CRUD ==========
  List<Product> getAllProducts() => List.from(_productsCache);
  List<Product> getProductsByCategory(String category) => _productsCache.where((p) => p.category == category).toList();
  Product? getProduct(String id) {
    try { return _productsCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
  Future<void> saveProduct(Product product) async {
    await _db.collection('products').doc(product.id).set(product.toJson());
    final idx = _productsCache.indexWhere((p) => p.id == product.id);
    if (idx >= 0) { _productsCache[idx] = product; } else { _productsCache.add(product); }
  }
  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
    _productsCache.removeWhere((p) => p.id == id);
  }

  // ========== Sales Order CRUD ==========
  List<SalesOrder> getAllOrders() => List.from(_ordersCache);
  List<SalesOrder> getOrdersByContact(String contactId) => _ordersCache.where((o) => o.contactId == contactId).toList();
  Future<void> saveOrder(SalesOrder order) async {
    await _db.collection('sales_orders').doc(order.id).set(order.toJson());
    final idx = _ordersCache.indexWhere((o) => o.id == order.id);
    if (idx >= 0) { _ordersCache[idx] = order; } else { _ordersCache.add(order); }
  }
  Future<void> deleteOrder(String id) async {
    await _db.collection('sales_orders').doc(id).delete();
    _ordersCache.removeWhere((o) => o.id == id);
  }

  // ========== Inventory CRUD ==========
  List<InventoryRecord> getAllInventory() => List.from(_inventoryCache);
  List<InventoryRecord> getInventoryByProduct(String productId) =>
      _inventoryCache.where((r) => r.productId == productId).toList();
  Future<void> addInventoryRecord(InventoryRecord record) async {
    _inventoryCache.add(record);
    await _db.collection('inventory').doc(record.id).set(record.toJson());
  }
  Future<void> deleteInventoryRecord(String id) async {
    _inventoryCache.removeWhere((r) => r.id == id);
    await _db.collection('inventory').doc(id).delete();
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
  Future<void> syncFromCloud() async => await _refreshAllCaches();

  // ========== Built-in Product Catalog ==========
  List<Product> _builtInProducts() => [
    Product(id: 'prod-exo-001', code: 'NS-EX0-001', name: '\u5916\u6ccc\u4f53\u539f\u6db2 300\u5104', nameJa: '\u30a8\u30af\u30bd\u30bd\u30fc\u30e0\u539f\u6db2 300\u5104\u5358\u4f4d', category: 'exosome',
      description: '\u9ad8\u7d14\u5ea6\u5916\u6ccc\u4f53\u539f\u6db2\uff0c\u542b300\u5104\u5358\u4f4d\u5916\u6ccc\u4f53\u7c92\u5b50\u3002\u9069\u7528\u4e8e\u808c\u819a\u518d\u751f\u3001\u6297\u8001\u5316\u6cbb\u7642\u3002\u63a1\u7528\u5148\u9032\u7684\u8d85\u96e2\u5fc3\u5206\u96e2\u6280\u8853\uff0c\u78ba\u4fdd\u9ad8\u7d14\u5ea6\u548c\u9ad8\u6d3b\u6027\u3002',
      specification: '300\u5104\u5358\u4f4d/\u74f6', unitsPerBox: 5, agentPrice: 30000, clinicPrice: 40000, retailPrice: 100000,
      agentTotalPrice: 150000, clinicTotalPrice: 200000, retailTotalPrice: 500000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4/\u5c40\u90e8\u6ce8\u5c04', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-exo-002', code: 'NS-EX0-002', name: '\u5916\u6ccc\u4f53\u539f\u6db2 500\u5104', nameJa: '\u30a8\u30af\u30bd\u30bd\u30fc\u30e0\u539f\u6db2 500\u5104\u5358\u4f4d', category: 'exosome',
      description: '\u9ad8\u6fc3\u5ea6\u5916\u6ccc\u4f53\u539f\u6db2\uff0c\u542b500\u5104\u5358\u4f4d\u5916\u6ccc\u4f53\u7c92\u5b50\u3002\u66f4\u9ad8\u6d53\u5ea6\u914d\u65b9\uff0c\u9069\u7528\u4e8e\u6df1\u5c64\u808c\u819a\u4fee\u5fa9\u548c\u518d\u751f\u91ab\u7642\u3002',
      specification: '500\u5104\u5358\u4f4d/\u74f6', unitsPerBox: 5, agentPrice: 45000, clinicPrice: 60000, retailPrice: 150000,
      agentTotalPrice: 225000, clinicTotalPrice: 300000, retailTotalPrice: 750000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4/\u5c40\u90e8\u6ce8\u5c04', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-exo-003', code: 'NS-EX0-003', name: '\u5916\u6ccc\u4f53\u539f\u6db2 1000\u5104', nameJa: '\u30a8\u30af\u30bd\u30bd\u30fc\u30e0\u539f\u6db2 1000\u5104\u5358\u4f4d', category: 'exosome',
      description: '\u8d85\u9ad8\u6fc3\u5ea6\u5916\u6ccc\u4f53\u539f\u6db2\uff0c\u542b1000\u5104\u5358\u4f4d\u5916\u6ccc\u4f53\u7c92\u5b50\u3002\u9802\u7d1a\u914d\u65b9\uff0c\u5c08\u696d\u91ab\u7642\u6a5f\u69cb\u9996\u9078\u3002',
      specification: '1000\u5104\u5358\u4f4d/\u74f6', unitsPerBox: 5, agentPrice: 105000, clinicPrice: 140000, retailPrice: 350000,
      agentTotalPrice: 525000, clinicTotalPrice: 700000, retailTotalPrice: 1750000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4/\u5c40\u90e8\u6ce8\u5c04', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-nad-001', code: 'NS-NAD-001', name: 'NAD+ \u6ce8\u5c04\u6db2 250mg', nameJa: 'NAD+ \u6ce8\u5c04\u6db2 250mg', category: 'nad',
      description: '\u9ad8\u7d14\u5ea6NAD+\u6ce8\u5c04\u6db2\uff0c\u6bcf\u74f6\u542b250mg NAD+\u3002\u4fc3\u9032\u7d30\u80de\u80fd\u91cf\u4ee3\u8b1d\uff0c\u6297\u8870\u8001\u6838\u5fc3\u6210\u5206\u3002',
      specification: '250mg/\u74f6', unitsPerBox: 5, agentPrice: 12000, clinicPrice: 16000, retailPrice: 40000,
      agentTotalPrice: 60000, clinicTotalPrice: 80000, retailTotalPrice: 200000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-nmn-001', code: 'NS-NMN-001', name: 'NMN \u70b9\u9f3b/\u5438\u5165', nameJa: 'NMN \u70b9\u9f3b\u30fb\u5438\u5165', category: 'nmn',
      description: 'NMN\u70b9\u9f3b/\u5438\u5165\u5236\u5242\u3002\u901a\u904e\u9f3b\u8154/\u5438\u5165\u65b9\u5f0f\u76f4\u63a5\u5438\u6536\uff0c\u751f\u7269\u5229\u7528\u5ea6\u9ad8\u3002\u9069\u7528\u4e8e\u65e5\u5e38\u4fdd\u5065\u548c\u6297\u8870\u8001\u3002',
      specification: '\u70b9\u9f3b/\u5438\u5165\u578b', unitsPerBox: 1, agentPrice: 22000, clinicPrice: 32000, retailPrice: 60000,
      agentTotalPrice: 22000, clinicTotalPrice: 32000, retailTotalPrice: 60000,
      storageMethod: '\u5e38\u6e29\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u70b9\u9f3b/\u5438\u5165\u4f7f\u7528', notes: 'NMN 700mg\u914d\u5408'),
    Product(id: 'prod-nmn-002', code: 'NS-NMN-002', name: 'NMN \u80f6\u56ca', nameJa: 'NMN \u30ab\u30d7\u30bb\u30eb', category: 'nmn',
      description: 'NMN\u53e3\u670d\u80f6\u56ca\u3002\u6bcf\u7c92\u542b\u9ad8\u7d14\u5ea6NMN\uff0c\u65b9\u4fbf\u65e5\u5e38\u670d\u7528\u3002\u652f\u6301NAD+\u6c34\u5e73\u63d0\u5347\uff0c\u4fc3\u9032\u7d30\u80de\u4fee\u5fa9\u548c\u80fd\u91cf\u4ee3\u8b1d\u3002',
      specification: '\u80f6\u56ca\u578b', unitsPerBox: 1, agentPrice: 9000, clinicPrice: 12000, retailPrice: 30000,
      agentTotalPrice: 9000, clinicTotalPrice: 12000, retailTotalPrice: 30000,
      storageMethod: '\u5e38\u6e29\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u6bcf\u65e51-2\u7c92\uff0c\u53e3\u670d'),
  ];

  // ========== Built-in Factory Data ==========
  List<ProductionFactory> _builtInFactories() => [
    ProductionFactory(
      id: 'factory-001', name: '\u682a\u5f0f\u4f1a\u793e\u30b7\u30a8\u30f3', nameJa: '\u682a\u5f0f\u4f1a\u793e\u30b7\u30a8\u30f3',
      address: '\u4e09\u91cd\u770c\u6d25\u5e02\u6728\u6c5f\u753a1\u756a11\u53f7', representative: '\u6c60\u7530 \u5e79',
      description: '\u9ad8\u7aef\u751f\u7269\u79d1\u6280\u52a0\u5de5\u4f01\u696d\uff0c\u6838\u5fc3\u51bb\u5e72\u6280\u672f\uff0c\u4e13\u6ce8\u518d\u751f\u533b\u7597\u9886\u57df\u3002',
      certifications: ['GMP', '\u518d\u751f\u533b\u7597\u52a0\u5de5'], capabilities: ['exosome', 'nad'],
      phone: '', email: '', isActive: true,
    ),
    ProductionFactory(
      id: 'factory-002', name: '\u682a\u5f0f\u4f1a\u793e\u30df\u30ba\u30fb\u30d0\u30e9\u30a8\u30c6\u30a3\u30fc', nameJa: '\u682a\u5f0f\u4f1a\u793e\u30df\u30ba\u30fb\u30d0\u30e9\u30a8\u30c6\u30a3\u30fc',
      address: '\u9759\u5ca1\u770c\u5bcc\u58eb\u5e02\u4eca\u6cc9383-5', representative: '\u85e4\u7530 \u4f38\u592b',
      description: '\u7efc\u5408\u5065\u5eb7\u98df\u54c1\u5236\u9020\u4f01\u696d\uff0c\u6301\u6709\u591a\u9879\u56fd\u9645\u8ba4\u8bc1\u3002',
      certifications: ['ISO9001', 'ISO27001', 'ISO22716', 'JIHFS', 'PrivacyMark', 'GMP'],
      capabilities: ['nmn', 'skincare'], phone: '', email: '', isActive: true,
    ),
  ];

  // ========== DB <-> Model Converters ==========
  Contact _contactFromDb(Map<String, dynamic> db) => Contact(
    id: db['id'] as String? ?? '', name: db['name'] as String? ?? '', nameReading: db['name_reading'] as String? ?? '',
    company: db['company'] as String? ?? '', position: db['position'] as String? ?? '',
    phone: db['phone'] as String? ?? '', email: db['email'] as String? ?? '', address: db['address'] as String? ?? '',
    industry: Industry.values.firstWhere((e) => e.name == db['industry'], orElse: () => Industry.other),
    strength: RelationshipStrength.values.firstWhere((e) => e.name == db['strength'], orElse: () => RelationshipStrength.cool),
    myRelation: MyRelationType.values.firstWhere((e) => e.name == db['my_relation'], orElse: () => MyRelationType.other),
    notes: db['notes'] as String? ?? '', referredBy: db['referred_by'] as String? ?? '',
    createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
    lastContactedAt: DateTime.tryParse(db['last_contacted_at'] ?? '') ?? DateTime.now(),
    tags: (db['tags'] is List) ? List<String>.from(db['tags']) : [], avatarUrl: db['avatar_url'] as String?,
    businessCategory: db['business_category'] as String?,
  );

  Map<String, dynamic> _contactToDb(Contact c) => {
    'id': c.id, 'name': c.name, 'name_reading': c.nameReading, 'company': c.company, 'position': c.position,
    'phone': c.phone, 'email': c.email, 'address': c.address, 'industry': c.industry.name, 'strength': c.strength.name,
    'my_relation': c.myRelation.name, 'notes': c.notes, 'referred_by': c.referredBy,
    'created_at': c.createdAt.toIso8601String(), 'last_contacted_at': c.lastContactedAt.toIso8601String(),
    'tags': c.tags, 'avatar_url': c.avatarUrl, 'business_category': c.businessCategory,
  };

  Deal _dealFromDb(Map<String, dynamic> db) => Deal(
    id: db['id'] as String? ?? '', title: db['title'] as String? ?? '', description: db['description'] as String? ?? '',
    contactId: db['contact_id'] as String? ?? '', contactName: db['contact_name'] as String? ?? '',
    stage: DealStage.values.firstWhere((e) => e.name == db['stage'], orElse: () => DealStage.lead),
    amount: (db['amount'] as num?)?.toDouble() ?? 0, currency: db['currency'] as String? ?? 'JPY',
    createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
    expectedCloseDate: DateTime.tryParse(db['expected_close_date'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(db['updated_at'] ?? '') ?? DateTime.now(),
    probability: (db['probability'] as num?)?.toDouble() ?? 10, notes: db['notes'] as String? ?? '',
    tags: (db['tags'] is List) ? List<String>.from(db['tags']) : [],
  );

  Map<String, dynamic> _dealToDb(Deal d) => {
    'id': d.id, 'title': d.title, 'description': d.description, 'contact_id': d.contactId, 'contact_name': d.contactName,
    'stage': d.stage.name, 'amount': d.amount, 'currency': d.currency,
    'created_at': d.createdAt.toIso8601String(), 'expected_close_date': d.expectedCloseDate.toIso8601String(),
    'updated_at': d.updatedAt.toIso8601String(), 'probability': d.probability, 'notes': d.notes, 'tags': d.tags,
  };

  Interaction _interactionFromDb(Map<String, dynamic> db) => Interaction(
    id: db['id'] as String? ?? '', contactId: db['contact_id'] as String? ?? '', contactName: db['contact_name'] as String? ?? '',
    type: InteractionType.values.firstWhere((e) => e.name == db['type'], orElse: () => InteractionType.other),
    title: db['title'] as String? ?? '', notes: db['notes'] as String? ?? '',
    date: DateTime.tryParse(db['date'] ?? '') ?? DateTime.now(), dealId: db['deal_id'] as String?,
  );

  Map<String, dynamic> _interactionToDb(Interaction i) => {
    'id': i.id, 'contact_id': i.contactId, 'contact_name': i.contactName, 'type': i.type.name,
    'title': i.title, 'notes': i.notes, 'date': i.date.toIso8601String(), 'deal_id': i.dealId,
  };

  ContactRelation _relationFromDb(Map<String, dynamic> db) => ContactRelation(
    id: db['id'] as String? ?? '', fromContactId: db['from_contact_id'] as String? ?? '',
    toContactId: db['to_contact_id'] as String? ?? '', fromName: db['from_name'] as String? ?? '',
    toName: db['to_name'] as String? ?? '', relationType: db['relation_type'] as String? ?? '',
    description: db['description'] as String? ?? '', createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> _relationToDb(ContactRelation r) => {
    'id': r.id, 'from_contact_id': r.fromContactId, 'to_contact_id': r.toContactId,
    'from_name': r.fromName, 'to_name': r.toName, 'relation_type': r.relationType,
    'description': r.description, 'created_at': r.createdAt.toIso8601String(),
  };
}
