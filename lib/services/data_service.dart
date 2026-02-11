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
  Future<void> addTeamMember(TeamMember member) async { _teamCache.add(member); }
  Future<void> updateTeamMember(TeamMember member) async {
    final idx = _teamCache.indexWhere((m) => m.id == member.id);
    if (idx >= 0) _teamCache[idx] = member;
  }
  Future<void> deleteTeamMember(String id) async { _teamCache.removeWhere((m) => m.id == id); }

  // ========== Task CRUD ==========
  List<Task> getAllTasks() => List.from(_taskCache);
  List<Task> getTasksByAssignee(String assigneeId) =>
      _taskCache.where((t) => t.assigneeId == assigneeId).toList();
  List<Task> getTasksByDate(DateTime date) =>
      _taskCache.where((t) => t.dueDate.year == date.year && t.dueDate.month == date.month && t.dueDate.day == date.day).toList();
  Future<void> addTask(Task task) async { _taskCache.add(task); }
  Future<void> updateTask(Task task) async {
    final idx = _taskCache.indexWhere((t) => t.id == task.id);
    if (idx >= 0) _taskCache[idx] = task;
  }
  Future<void> deleteTask(String id) async { _taskCache.removeWhere((t) => t.id == id); }

  // ========== Contact Assignment CRUD ==========
  List<ContactAssignment> getAllAssignments() => List.from(_assignmentCache);
  List<ContactAssignment> getAssignmentsByContact(String contactId) =>
      _assignmentCache.where((a) => a.contactId == contactId).toList();
  List<ContactAssignment> getAssignmentsByMember(String memberId) =>
      _assignmentCache.where((a) => a.memberId == memberId).toList();
  Future<void> addAssignment(ContactAssignment assignment) async { _assignmentCache.add(assignment); }
  Future<void> updateAssignment(ContactAssignment assignment) async {
    final idx = _assignmentCache.indexWhere((a) => a.id == assignment.id);
    if (idx >= 0) _assignmentCache[idx] = assignment;
  }
  Future<void> deleteAssignment(String id) async { _assignmentCache.removeWhere((a) => a.id == id); }

  // ========== Factory CRUD ==========
  List<ProductionFactory> getAllFactories() => List.from(_factoryCache);
  ProductionFactory? getFactory(String id) {
    try { return _factoryCache.firstWhere((f) => f.id == id); } catch (_) { return null; }
  }
  Future<void> addFactory(ProductionFactory factory) async { _factoryCache.add(factory); }
  Future<void> updateFactory(ProductionFactory factory) async {
    final idx = _factoryCache.indexWhere((f) => f.id == factory.id);
    if (idx >= 0) _factoryCache[idx] = factory;
  }
  Future<void> deleteFactory(String id) async { _factoryCache.removeWhere((f) => f.id == id); }

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
  Future<void> addProductionOrder(ProductionOrder order) async { _productionCache.add(order); }
  Future<void> updateProductionOrder(ProductionOrder order) async {
    final idx = _productionCache.indexWhere((p) => p.id == order.id);
    if (idx >= 0) _productionCache[idx] = order;
  }
  Future<void> deleteProductionOrder(String id) async { _productionCache.removeWhere((p) => p.id == id); }

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
    _productsCache = _builtInProducts();
    _factoryCache.addAll(_builtInFactories());
    _teamCache.addAll(_builtInTeam());
    _contactsCache = _builtInContacts();
    _dealsCache = _builtInDeals();
  }

  Future<void> syncFromCloud() async {
    // No-op in local mode
  }

  // ========== Contact CRUD ==========
  List<Contact> getAllContacts() => List.from(_contactsCache);
  Contact? getContact(String id) {
    try { return _contactsCache.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }
  Future<void> saveContact(Contact contact) async {
    final idx = _contactsCache.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) { _contactsCache[idx] = contact; } else { _contactsCache.add(contact); }
  }
  Future<void> deleteContact(String id) async {
    _contactsCache.removeWhere((c) => c.id == id);
    _interactionsCache.removeWhere((i) => i.contactId == id);
    _relationsCache.removeWhere((r) => r.fromContactId == id || r.toContactId == id);
  }

  // ========== Relation CRUD ==========
  List<ContactRelation> getAllRelations() => List.from(_relationsCache);
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relationsCache.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();
  Future<void> saveRelation(ContactRelation relation) async {
    final idx = _relationsCache.indexWhere((r) => r.id == relation.id);
    if (idx >= 0) { _relationsCache[idx] = relation; } else { _relationsCache.add(relation); }
  }
  Future<void> deleteRelation(String id) async { _relationsCache.removeWhere((r) => r.id == id); }

  // ========== Deal CRUD ==========
  List<Deal> getAllDeals() => List.from(_dealsCache);
  List<Deal> getDealsByStage(DealStage stage) => _dealsCache.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _dealsCache.where((d) => d.contactId == contactId).toList();
  Future<void> saveDeal(Deal deal) async {
    final idx = _dealsCache.indexWhere((d) => d.id == deal.id);
    if (idx >= 0) { _dealsCache[idx] = deal; } else { _dealsCache.add(deal); }
  }
  Future<void> deleteDeal(String id) async { _dealsCache.removeWhere((d) => d.id == id); }

  // ========== Interaction CRUD ==========
  List<Interaction> getAllInteractions() => List.from(_interactionsCache);
  List<Interaction> getInteractionsByContact(String contactId) =>
      _interactionsCache.where((i) => i.contactId == contactId).toList();
  Future<void> saveInteraction(Interaction interaction) async {
    final idx = _interactionsCache.indexWhere((i) => i.id == interaction.id);
    if (idx >= 0) { _interactionsCache[idx] = interaction; } else { _interactionsCache.add(interaction); }
  }
  Future<void> deleteInteraction(String id) async { _interactionsCache.removeWhere((i) => i.id == id); }

  // ========== Product CRUD ==========
  List<Product> getAllProducts() => List.from(_productsCache);
  List<Product> getProductsByCategory(String category) => _productsCache.where((p) => p.category == category).toList();
  Product? getProduct(String id) {
    try { return _productsCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
  Future<void> saveProduct(Product product) async {
    final idx = _productsCache.indexWhere((p) => p.id == product.id);
    if (idx >= 0) { _productsCache[idx] = product; } else { _productsCache.add(product); }
  }
  Future<void> deleteProduct(String id) async { _productsCache.removeWhere((p) => p.id == id); }

  // ========== Sales Order CRUD ==========
  List<SalesOrder> getAllOrders() => List.from(_ordersCache);
  List<SalesOrder> getOrdersByContact(String contactId) => _ordersCache.where((o) => o.contactId == contactId).toList();
  Future<void> saveOrder(SalesOrder order) async {
    final idx = _ordersCache.indexWhere((o) => o.id == order.id);
    if (idx >= 0) { _ordersCache[idx] = order; } else { _ordersCache.add(order); }
  }
  Future<void> deleteOrder(String id) async { _ordersCache.removeWhere((o) => o.id == id); }

  // ========== Inventory CRUD ==========
  List<InventoryRecord> getAllInventory() => List.from(_inventoryCache);
  List<InventoryRecord> getInventoryByProduct(String productId) =>
      _inventoryCache.where((r) => r.productId == productId).toList();
  Future<void> addInventoryRecord(InventoryRecord record) async { _inventoryCache.add(record); }
  Future<void> deleteInventoryRecord(String id) async { _inventoryCache.removeWhere((r) => r.id == id); }

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

  // ========== Built-in Product Catalog ==========
  List<Product> _builtInProducts() => [
    Product(id: 'prod-exo-001', code: 'NS-EX0-001', name: '\u5916\u6ccc\u4f53\u539f\u6db2 300\u5104', nameJa: '\u30a8\u30af\u30bd\u30bd\u30fc\u30e0\u539f\u6db2 300\u5104\u5358\u4f4d', category: 'exosome',
      description: '\u9ad8\u7d14\u5ea6\u5916\u6ccc\u4f53\u539f\u6db2\uff0c\u542b300\u5104\u5358\u4f4d\u5916\u6ccc\u4f53\u7c92\u5b50\u3002\u9069\u7528\u4e8e\u808c\u819a\u518d\u751f\u3001\u6297\u8001\u5316\u6cbb\u7597\u3002',
      specification: '300\u5104\u5358\u4f4d/\u74f6', unitsPerBox: 5, agentPrice: 30000, clinicPrice: 40000, retailPrice: 100000,
      agentTotalPrice: 150000, clinicTotalPrice: 200000, retailTotalPrice: 500000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4/\u5c40\u90e8\u6ce8\u5c04', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-exo-002', code: 'NS-EX0-002', name: '\u5916\u6ccc\u4f53\u539f\u6db2 500\u5104', nameJa: '\u30a8\u30af\u30bd\u30bd\u30fc\u30e0\u539f\u6db2 500\u5104\u5358\u4f4d', category: 'exosome',
      description: '\u9ad8\u6fc3\u5ea6\u5916\u6ccc\u4f53\u539f\u6db2\uff0c\u542b500\u5104\u5358\u4f4d\u5916\u6ccc\u4f53\u7c92\u5b50\u3002',
      specification: '500\u5104\u5358\u4f4d/\u74f6', unitsPerBox: 5, agentPrice: 45000, clinicPrice: 60000, retailPrice: 150000,
      agentTotalPrice: 225000, clinicTotalPrice: 300000, retailTotalPrice: 750000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4/\u5c40\u90e8\u6ce8\u5c04', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-exo-003', code: 'NS-EX0-003', name: '\u5916\u6ccc\u4f53\u539f\u6db2 1000\u5104', nameJa: '\u30a8\u30af\u30bd\u30bd\u30fc\u30e0\u539f\u6db2 1000\u5104\u5358\u4f4d', category: 'exosome',
      description: '\u8d85\u9ad8\u6fc3\u5ea6\u5916\u6ccc\u4f53\u539f\u6db2\uff0c\u542b1000\u5104\u5358\u4f4d\u5916\u6ccc\u4f53\u7c92\u5b50\u3002\u9802\u7d1a\u914d\u65b9\u3002',
      specification: '1000\u5104\u5358\u4f4d/\u74f6', unitsPerBox: 5, agentPrice: 105000, clinicPrice: 140000, retailPrice: 350000,
      agentTotalPrice: 525000, clinicTotalPrice: 700000, retailTotalPrice: 1750000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4/\u5c40\u90e8\u6ce8\u5c04', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-nad-001', code: 'NS-NAD-001', name: 'NAD+ \u6ce8\u5c04\u6db2 250mg', nameJa: 'NAD+ \u6ce8\u5c04\u6db2 250mg', category: 'nad',
      description: '\u9ad8\u7d14\u5ea6NAD+\u6ce8\u5c04\u6db2\uff0c\u6bcf\u74f6\u542b250mg NAD+\u3002\u4fc3\u9032\u7d30\u80de\u80fd\u91cf\u4ee3\u8b1d\u3002',
      specification: '250mg/\u74f6', unitsPerBox: 5, agentPrice: 12000, clinicPrice: 16000, retailPrice: 40000,
      agentTotalPrice: 60000, clinicTotalPrice: 80000, retailTotalPrice: 200000,
      storageMethod: '2-8\u00b0C \u51b7\u85cf\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u9759\u8108\u6ce8\u5c04/\u70b9\u6ef4', notes: '\u4ee3\u7406\u6298\u625830%\u3001\u8bca\u6240\u6298\u625840%'),
    Product(id: 'prod-nmn-001', code: 'NS-NMN-001', name: 'NMN \u70b9\u9f3b/\u5438\u5165', nameJa: 'NMN \u70b9\u9f3b\u30fb\u5438\u5165', category: 'nmn',
      description: 'NMN\u70b9\u9f3b/\u5438\u5165\u5236\u5242\u3002\u751f\u7269\u5229\u7528\u5ea6\u9ad8\u3002',
      specification: '\u70b9\u9f3b/\u5438\u5165\u578b', unitsPerBox: 1, agentPrice: 22000, clinicPrice: 32000, retailPrice: 60000,
      agentTotalPrice: 22000, clinicTotalPrice: 32000, retailTotalPrice: 60000,
      storageMethod: '\u5e38\u6e29\u4fdd\u5b58', shelfLife: '2\u5e74', usage: '\u70b9\u9f3b/\u5438\u5165\u4f7f\u7528', notes: 'NMN 700mg\u914d\u5408'),
    Product(id: 'prod-nmn-002', code: 'NS-NMN-002', name: 'NMN \u80f6\u56ca', nameJa: 'NMN \u30ab\u30d7\u30bb\u30eb', category: 'nmn',
      description: 'NMN\u53e3\u670d\u80f6\u56ca\u3002\u6bcf\u7c92\u542b\u9ad8\u7d14\u5ea6NMN\u3002',
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

  // ========== Built-in Team ==========
  List<TeamMember> _builtInTeam() => [
    TeamMember(id: 'member-001', name: 'James Liu', role: 'admin', email: 'james@dealnavigator.com'),
    TeamMember(id: 'member-002', name: '\u7530\u4e2d\u592a\u90ce', role: 'manager', email: 'tanaka@dealnavigator.com'),
    TeamMember(id: 'member-003', name: '\u738b\u5c0f\u660e', role: 'member', email: 'xiaoming@dealnavigator.com'),
  ];

  // ========== Built-in Contacts ==========
  List<Contact> _builtInContacts() {
    final now = DateTime.now();
    return [
      Contact(id: 'c-001', name: '\u5f20\u4f1f', company: '\u4e0a\u6d77\u6cf0\u5eb7\u533b\u7f8e', position: '\u603b\u7ecf\u7406',
        phone: '+86-138-0000-1001', email: 'zhangwei@taikang.com', address: '\u4e0a\u6d77\u5e02\u9759\u5b89\u533a',
        industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.agent,
        notes: '\u534e\u4e1c\u533a\u603b\u4ee3\u7406\uff0c\u6708\u91c7\u8d2d\u91cf\u7a33\u5b9a', tags: ['VIP', '\u4ee3\u7406'],
        createdAt: now.subtract(const Duration(days: 400)), lastContactedAt: now.subtract(const Duration(days: 1)),
        businessCategory: 'agent'),
      Contact(id: 'c-002', name: 'Dr. \u7530\u4e2d\u7f8e\u54b2', nameReading: '\u305f\u306a\u304b \u307f\u3055\u304d', company: '\u516d\u672c\u6728\u30b9\u30ad\u30f3\u30af\u30ea\u30cb\u30c3\u30af', position: '\u9662\u957f',
        phone: '+81-3-5555-0001', email: 'misaki@roppongi-skin.jp', address: '\u6771\u4eac\u90fd\u6e2f\u533a\u516d\u672c\u67283-1-1',
        industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.clinic,
        notes: '\u6708\u91c7\u8d2d\u5916\u6ccc\u4f53\u6ce8\u5c04\u6db220\u652f', tags: ['\u8bca\u6240', '\u4e1c\u4eac', 'VIP'],
        createdAt: now.subtract(const Duration(days: 380)), lastContactedAt: now.subtract(const Duration(hours: 6)),
        businessCategory: 'clinic'),
      Contact(id: 'c-003', name: '\u674e\u660e', company: '\u6df1\u5733\u5065\u5eb7\u4f18\u9009', position: '\u91c7\u8d2d\u603b\u76d1',
        phone: '+86-135-0000-2002', email: 'liming@healthbest.cn', address: '\u6df1\u5733\u5e02\u5357\u5c71\u533a',
        industry: Industry.trading, strength: RelationshipStrength.warm, myRelation: MyRelationType.retailer,
        notes: '\u8de8\u5883\u7535\u5546\u6e20\u9053\uff0cNMN\u4ea7\u54c1\u4e3a\u4e3b', tags: ['\u96f6\u552e', '\u7535\u5546'],
        createdAt: now.subtract(const Duration(days: 340)), lastContactedAt: now.subtract(const Duration(days: 3)),
        businessCategory: 'retail'),
      Contact(id: 'c-004', name: '\u4f50\u85e4\u5065\u4e00', nameReading: '\u3055\u3068\u3046 \u3051\u3093\u3044\u3061', company: '\u4e1c\u4eac\u7f8e\u5bb9\u534f\u4f1a', position: '\u7406\u4e8b',
        phone: '+81-3-6666-0001', email: 'sato.k@beauty-assoc.jp', address: '\u6771\u4eac\u90fd\u6e0b\u8c37\u533a',
        industry: Industry.consulting, strength: RelationshipStrength.warm, myRelation: MyRelationType.advisor,
        notes: '\u884c\u4e1a\u8d44\u6e90\u4ecb\u7ecd\uff0c\u5173\u952e\u4eba\u8109\u8282\u70b9', tags: ['\u987e\u95ee', '\u4e1c\u4eac'],
        createdAt: now.subtract(const Duration(days: 310)), lastContactedAt: now.subtract(const Duration(days: 22))),
      Contact(id: 'c-005', name: '\u738b\u82b3', company: '\u676d\u5dde\u60a6\u989c\u533b\u7f8e', position: '\u8fd0\u8425\u603b\u76d1',
        phone: '+86-139-0000-3003', email: 'wangfang@yueyan.com', address: '\u676d\u5dde\u5e02\u897f\u6e56\u533a',
        industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.clinic,
        notes: '3\u5bb6\u8fde\u9501\u8bca\u6240\uff0c\u6708\u9500\u7a33\u5b9a', tags: ['\u8bca\u6240', '\u676d\u5dde', 'VIP'],
        createdAt: now.subtract(const Duration(days: 270)), lastContactedAt: now.subtract(const Duration(days: 2)),
        businessCategory: 'clinic'),
      Contact(id: 'c-006', name: 'Mike Chen', company: 'Pacific Health Group', position: 'VP Business Dev',
        phone: '+1-415-555-0088', email: 'mchen@pacifichealth.com', address: 'San Francisco, CA',
        industry: Industry.trading, strength: RelationshipStrength.cool, myRelation: MyRelationType.agent,
        notes: '\u5317\u7f8e\u5e02\u573a\u6f5c\u5728\u4ee3\u7406', tags: ['\u5317\u7f8e', '\u5f00\u53d1\u4e2d'],
        createdAt: now.subtract(const Duration(days: 175)), lastContactedAt: now.subtract(const Duration(days: 12)),
        businessCategory: 'agent'),
      Contact(id: 'c-007', name: '\u5c71\u672c\u771f\u7531\u7f8e', nameReading: '\u3084\u307e\u3082\u3068 \u307e\u3086\u307f', company: '\u9280\u5ea7\u30d3\u30e5\u30fc\u30c6\u30a3\u30fc\u30e9\u30dc', position: '\u30aa\u30fc\u30ca\u30fc',
        phone: '+81-3-7777-0001', email: 'yamamoto@ginza-beauty.jp', address: '\u6771\u4eac\u90fd\u4e2d\u592e\u533a\u9280\u5ea75-1-1',
        industry: Industry.healthcare, strength: RelationshipStrength.warm, myRelation: MyRelationType.clinic,
        notes: '\u9ad8\u7aef\u7f8e\u5bb9\u9662\uff0c\u5bf9\u5916\u6ccc\u4f53\u9762\u819c\u611f\u5174\u8da3', tags: ['\u8bca\u6240', '\u94f6\u5ea7'],
        createdAt: now.subtract(const Duration(days: 160)), lastContactedAt: now.subtract(const Duration(days: 6)),
        businessCategory: 'clinic'),
      Contact(id: 'c-008', name: '\u8d75\u5927\u529b', company: '\u6210\u90fd\u5eb7\u590d\u5802', position: '\u5408\u4f19\u4eba',
        phone: '+86-136-0000-4004', email: 'zhaodl@kangfutang.cn', address: '\u6210\u90fd\u5e02\u9526\u6c5f\u533a',
        industry: Industry.healthcare, strength: RelationshipStrength.cool, myRelation: MyRelationType.retailer,
        notes: '\u7ebf\u4e0b\u96f6\u552e+\u793e\u7fa4\u56e2\u8d2d', tags: ['\u96f6\u552e', '\u6210\u90fd'],
        createdAt: now.subtract(const Duration(days: 130)), lastContactedAt: now.subtract(const Duration(days: 17)),
        businessCategory: 'retail'),
      Contact(id: 'c-009', name: '\u91d1\u76f8\u54f2', nameReading: '\uae40\uc0c1\ucca0', company: 'Seoul Derm Clinic', position: 'Director',
        phone: '+82-2-555-0099', email: 'kim@seoulderm.kr', address: '\uc11c\uc6b8 \uac15\ub0a8\uad6c',
        industry: Industry.healthcare, strength: RelationshipStrength.cool, myRelation: MyRelationType.clinic,
        notes: '\u97e9\u56fd\u76ae\u80a4\u79d1\u8bca\u6240\uff0c\u8003\u5bdf\u4e2d', tags: ['\u8bca\u6240', '\u97e9\u56fd'],
        createdAt: now.subtract(const Duration(days: 95)), lastContactedAt: now.subtract(const Duration(days: 28)),
        businessCategory: 'clinic'),
      Contact(id: 'c-010', name: '\u6797\u5fd7\u8fdc', company: '\u53f0\u5317\u751f\u6280\u80a1\u4efd\u6709\u9650\u516c\u53f8', position: 'CEO',
        phone: '+886-2-8888-0001', email: 'lin@taipei-biotech.tw', address: '\u53f0\u5317\u5e02\u4fe1\u4e49\u533a',
        industry: Industry.healthcare, strength: RelationshipStrength.warm, myRelation: MyRelationType.agent,
        notes: '\u53f0\u6e7e\u533aNMN\u4ee3\u7406\u610f\u5411', tags: ['\u4ee3\u7406', '\u53f0\u6e7e'],
        createdAt: now.subtract(const Duration(days: 225)), lastContactedAt: now.subtract(const Duration(days: 4)),
        businessCategory: 'agent'),
    ];
  }

  // ========== Built-in Deals ==========
  List<Deal> _builtInDeals() {
    final now = DateTime.now();
    return [
      Deal(id: 'd-001', title: '\u4e0a\u6d77\u6cf0\u5eb7 \u5916\u6ccc\u4f53300\u4ebf \u4ee3\u7406\u6279\u53d1', description: '\u534e\u4e1c\u533a\u9996\u6279500\u74f6\u8bd5\u9500',
        contactId: 'c-001', contactName: '\u5f20\u4f1f', stage: DealStage.negotiation, amount: 7500000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 72)), expectedCloseDate: now.add(const Duration(days: 33)),
        updatedAt: now.subtract(const Duration(days: 1)), probability: 70, tags: ['\u4ee3\u7406', '\u534e\u4e1c']),
      Deal(id: 'd-002', title: '\u516d\u672c\u6728\u8bca\u6240 \u6ce8\u5c04\u6db2\u6708\u5ea6\u8ba2\u5355', description: '\u6708\u5ea620\u652f\u5916\u6ccc\u4f53\u6ce8\u5c04\u6db2',
        contactId: 'c-002', contactName: 'Dr. \u7530\u4e2d\u7f8e\u54b2', stage: DealStage.ordered, amount: 2800000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 88)), expectedCloseDate: now.add(const Duration(days: 17)),
        updatedAt: now.subtract(const Duration(hours: 6)), probability: 95, tags: ['\u8bca\u6240', '\u6708\u5ea6']),
      Deal(id: 'd-003', title: '\u6df1\u5733\u5065\u5eb7\u4f18\u9009 NMN\u8de8\u5883\u7535\u5546', description: 'NMN\u80f6\u56ca\u9996\u6279200\u74f6',
        contactId: 'c-003', contactName: '\u674e\u660e', stage: DealStage.proposal, amount: 1800000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 32)), expectedCloseDate: now.add(const Duration(days: 49)),
        updatedAt: now.subtract(const Duration(days: 3)), probability: 40, tags: ['\u96f6\u552e', '\u7535\u5546']),
      Deal(id: 'd-004', title: '\u60a6\u989c\u533b\u7f8e \u5916\u6ccc\u4f53\u9762\u819c+\u6ce8\u5c04\u6db2', description: '3\u5bb6\u8fde\u9501\u8bca\u6240\u6708\u5ea6\u91c7\u8d2d',
        contactId: 'c-005', contactName: '\u738b\u82b3', stage: DealStage.ordered, amount: 3000000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 114)), expectedCloseDate: now.add(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 2)), probability: 90, tags: ['\u8bca\u6240', '\u8fde\u9501']),
      Deal(id: 'd-005', title: 'Pacific Health \u5317\u7f8e\u72ec\u5bb6\u4ee3\u7406', description: '\u5317\u7f8e\u5e02\u573a\u72ec\u5bb6\u4ee3\u7406\u6743\u8c08\u5224',
        contactId: 'c-006', contactName: 'Mike Chen', stage: DealStage.contacted, amount: 50000000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 22)), expectedCloseDate: now.add(const Duration(days: 139)),
        updatedAt: now.subtract(const Duration(days: 12)), probability: 15, tags: ['\u5317\u7f8e', '\u72ec\u5bb6']),
      Deal(id: 'd-006', title: '\u94f6\u5ea7\u7f8e\u5bb9\u9662 \u9762\u819c\u8bd5\u7528\u91c7\u8d2d', description: '\u9ad8\u7aef\u5916\u6ccc\u4f53\u9762\u819c\u8bd5\u7528\u88c5',
        contactId: 'c-007', contactName: '\u5c71\u672c\u771f\u7531\u7f8e', stage: DealStage.proposal, amount: 400000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 17)), expectedCloseDate: now.add(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 6)), probability: 55, tags: ['\u8bca\u6240', '\u9762\u819c']),
      Deal(id: 'd-007', title: '\u53f0\u5317\u751f\u6280 NMN Premium \u53f0\u6e7e\u4ee3\u7406', description: '\u53f0\u6e7e\u533aNMN\u5168\u7ebf\u4ea7\u54c1\u72ec\u5bb6\u4ee3\u7406',
        contactId: 'c-010', contactName: '\u6797\u5fd7\u8fdc', stage: DealStage.negotiation, amount: 12000000, currency: 'JPY',
        createdAt: now.subtract(const Duration(days: 58)), expectedCloseDate: now.add(const Duration(days: 64)),
        updatedAt: now.subtract(const Duration(days: 4)), probability: 50, tags: ['\u4ee3\u7406', '\u53f0\u6e7e']),
    ];
  }
}
