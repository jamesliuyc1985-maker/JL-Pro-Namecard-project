import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/team.dart';
import '../models/task.dart';
import '../models/contact_assignment.dart';
import '../models/factory.dart';
import '../services/data_service.dart';

class CrmProvider extends ChangeNotifier {
  final DataService _dataService;
  List<Contact> _contacts = [];
  List<Deal> _deals = [];
  List<Interaction> _interactions = [];
  List<ContactRelation> _relations = [];
  List<Product> _products = [];
  List<SalesOrder> _orders = [];
  List<InventoryRecord> _inventoryRecords = [];
  List<TeamMember> _teamMembers = [];
  List<Task> _tasks = [];
  List<ContactAssignment> _assignments = [];
  List<ProductionFactory> _factories = [];
  List<ProductionOrder> _productionOrders = [];
  Industry? _selectedIndustry;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _syncStatus;

  CrmProvider(this._dataService);

  List<Contact> get contacts {
    var list = List<Contact>.from(_contacts);
    if (_selectedIndustry != null) {
      list = list.where((c) => c.industry == _selectedIndustry).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.company.toLowerCase().contains(q) ||
          c.nameReading.toLowerCase().contains(q) ||
          c.position.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<Contact> get allContacts => _contacts;
  List<Deal> get deals => _deals;
  List<Interaction> get interactions => _interactions;
  List<ContactRelation> get relations => _relations;
  List<Product> get products => _products;
  List<SalesOrder> get orders => _orders;
  List<InventoryRecord> get inventoryRecords => _inventoryRecords;
  List<InventoryStock> get inventoryStocks => _dataService.getInventoryStocks();
  List<TeamMember> get teamMembers => _teamMembers;
  List<Task> get tasks => _tasks;
  List<ContactAssignment> get assignments => _assignments;
  List<ProductionFactory> get factories => _factories;
  List<ProductionOrder> get productionOrders => _productionOrders;
  Industry? get selectedIndustry => _selectedIndustry;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get syncStatus => _syncStatus;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _contacts = _dataService.getAllContacts();
      _deals = _dataService.getAllDeals();
      _interactions = _dataService.getAllInteractions();
      _relations = _dataService.getAllRelations();
      _products = _dataService.getAllProducts();
      _orders = _dataService.getAllOrders();
      _inventoryRecords = _dataService.getAllInventory();
      _teamMembers = _dataService.getAllTeamMembers();
      _tasks = _dataService.getAllTasks();
      _assignments = _dataService.getAllAssignments();
      _factories = _dataService.getAllFactories();
      _productionOrders = _dataService.getAllProductionOrders();
      _syncStatus = null;
    } catch (e) {
      _syncStatus = 'Loading failed: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncFromCloud() async {
    _isLoading = true;
    _syncStatus = '正在同步...';
    notifyListeners();
    try {
      await _dataService.syncFromCloud();
      await loadAll();
      _syncStatus = '同步成功';
    } catch (e) {
      _syncStatus = '同步失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  void setIndustryFilter(Industry? industry) {
    _selectedIndustry = industry == _selectedIndustry ? null : industry;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Map<String, dynamic> get stats => _dataService.getStats();

  // Contact
  Future<void> addContact(Contact contact) async { await _dataService.saveContact(contact); await loadAll(); }
  Future<void> updateContact(Contact contact) async { await _dataService.saveContact(contact); await loadAll(); }
  Future<void> deleteContact(String id) async { await _dataService.deleteContact(id); await loadAll(); }
  Contact? getContact(String id) => _dataService.getContact(id);

  // Relations
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relations.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();
  Future<void> addRelation(ContactRelation relation) async { await _dataService.saveRelation(relation); await loadAll(); }
  Future<void> deleteRelation(String id) async { await _dataService.deleteRelation(id); await loadAll(); }

  // Deal
  List<Deal> getDealsByStage(DealStage stage) => _deals.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _deals.where((d) => d.contactId == contactId).toList();
  Future<void> addDeal(Deal deal) async { await _dataService.saveDeal(deal); await loadAll(); }
  Future<void> updateDeal(Deal deal) async { await _dataService.saveDeal(deal); await loadAll(); }
  Future<void> deleteDeal(String id) async { await _dataService.deleteDeal(id); await loadAll(); }

  Future<void> moveDealStage(String dealId, DealStage newStage) async {
    final deal = _deals.firstWhere((d) => d.id == dealId);
    deal.stage = newStage;
    deal.updatedAt = DateTime.now();
    if (newStage == DealStage.completed) { deal.probability = 100; }
    if (newStage == DealStage.lost) { deal.probability = 0; }
    await _dataService.saveDeal(deal);
    await loadAll();
  }

  // Interaction
  List<Interaction> getInteractionsByContact(String contactId) =>
      _interactions.where((i) => i.contactId == contactId).toList();
  Future<void> addInteraction(Interaction interaction) async {
    await _dataService.saveInteraction(interaction);
    final contact = _dataService.getContact(interaction.contactId);
    if (contact != null) {
      contact.lastContactedAt = DateTime.now();
      await _dataService.saveContact(contact);
    }
    await loadAll();
  }
  Future<void> deleteInteraction(String id) async { await _dataService.deleteInteraction(id); await loadAll(); }

  // Product
  Product? getProduct(String id) => _dataService.getProduct(id);
  List<Product> getProductsByCategory(String category) => _products.where((p) => p.category == category).toList();
  Future<void> addProduct(Product product) async { await _dataService.saveProduct(product); await loadAll(); }
  Future<void> deleteProduct(String id) async { await _dataService.deleteProduct(id); await loadAll(); }

  // Sales Order
  List<SalesOrder> getOrdersByContact(String contactId) => _orders.where((o) => o.contactId == contactId).toList();
  Future<void> addOrder(SalesOrder order) async { await _dataService.saveOrder(order); await loadAll(); }
  Future<void> updateOrder(SalesOrder order) async { await _dataService.saveOrder(order); await loadAll(); }
  Future<void> deleteOrder(String id) async { await _dataService.deleteOrder(id); await loadAll(); }

  // Create order + deal + deduct inventory
  Future<void> createOrderWithDeal(SalesOrder order) async {
    await _dataService.saveOrder(order);
    // Create linked deal
    final deal = Deal(
      id: generateId(),
      title: '订单: ${order.contactName}',
      description: order.items.map((i) => '${i.productName} x${i.quantity}').join(', '),
      contactId: order.contactId,
      contactName: order.contactName,
      stage: DealStage.ordered,
      amount: order.totalAmount,
      orderId: order.id,
      probability: 70,
    );
    await _dataService.saveDeal(deal);
    // Deduct inventory
    for (final item in order.items) {
      await _dataService.addInventoryRecord(InventoryRecord(
        id: generateId(),
        productId: item.productId,
        productName: item.productName,
        productCode: item.productCode,
        type: 'out',
        quantity: item.quantity,
        reason: '销售出库 - ${order.contactName}',
      ));
    }
    await loadAll();
  }

  // Inventory
  List<InventoryRecord> getInventoryByProduct(String productId) =>
      _inventoryRecords.where((r) => r.productId == productId).toList();
  Future<void> addInventoryRecord(InventoryRecord record) async {
    await _dataService.addInventoryRecord(record);
    _inventoryRecords = _dataService.getAllInventory();
    notifyListeners();
  }
  Future<void> deleteInventoryRecord(String id) async {
    await _dataService.deleteInventoryRecord(id);
    _inventoryRecords = _dataService.getAllInventory();
    notifyListeners();
  }

  int getProductStock(String productId) {
    final stocks = _dataService.getInventoryStocks();
    try { return stocks.firstWhere((s) => s.productId == productId).currentStock; } catch (_) { return 0; }
  }

  // Team
  TeamMember? getTeamMember(String id) => _dataService.getTeamMember(id);
  Future<void> addTeamMember(TeamMember member) async {
    await _dataService.addTeamMember(member);
    _teamMembers = _dataService.getAllTeamMembers();
    notifyListeners();
  }
  Future<void> updateTeamMember(TeamMember member) async {
    await _dataService.updateTeamMember(member);
    _teamMembers = _dataService.getAllTeamMembers();
    notifyListeners();
  }
  Future<void> deleteTeamMember(String id) async {
    await _dataService.deleteTeamMember(id);
    _teamMembers = _dataService.getAllTeamMembers();
    notifyListeners();
  }

  // Task
  List<Task> getTasksByAssignee(String assigneeId) => _tasks.where((t) => t.assigneeId == assigneeId).toList();
  List<Task> getTasksByDate(DateTime date) =>
      _tasks.where((t) => t.dueDate.year == date.year && t.dueDate.month == date.month && t.dueDate.day == date.day).toList();
  List<Task> getTasksByPhase(TaskPhase phase) => _dataService.getTasksByPhase(phase);
  List<Task> getCompletedTasks() => _dataService.getCompletedTasks();
  Map<String, double> get workloadStats => _dataService.getWorkloadStats();

  Future<void> addTask(Task task) async {
    await _dataService.addTask(task);
    _tasks = _dataService.getAllTasks();
    notifyListeners();
  }
  Future<void> updateTask(Task task) async {
    await _dataService.updateTask(task);
    _tasks = _dataService.getAllTasks();
    notifyListeners();
  }
  Future<void> deleteTask(String id) async {
    await _dataService.deleteTask(id);
    _tasks = _dataService.getAllTasks();
    notifyListeners();
  }

  // Contact Assignment
  List<ContactAssignment> getAssignmentsByContact(String contactId) =>
      _assignments.where((a) => a.contactId == contactId).toList();
  List<ContactAssignment> getAssignmentsByMember(String memberId) =>
      _assignments.where((a) => a.memberId == memberId).toList();

  Future<void> addAssignment(ContactAssignment assignment) async {
    await _dataService.addAssignment(assignment);
    _assignments = _dataService.getAllAssignments();
    notifyListeners();
  }
  Future<void> updateAssignment(ContactAssignment assignment) async {
    await _dataService.updateAssignment(assignment);
    _assignments = _dataService.getAllAssignments();
    notifyListeners();
  }
  Future<void> deleteAssignment(String id) async {
    await _dataService.deleteAssignment(id);
    _assignments = _dataService.getAllAssignments();
    notifyListeners();
  }

  String generateId() => _dataService.generateId();

  // ========== Factory ==========
  ProductionFactory? getFactory(String id) => _dataService.getFactory(id);
  List<ProductionFactory> get activeFactories => _factories.where((f) => f.isActive).toList();

  Future<void> addFactory(ProductionFactory factory) async {
    await _dataService.addFactory(factory);
    _factories = _dataService.getAllFactories();
    notifyListeners();
  }
  Future<void> updateFactory(ProductionFactory factory) async {
    await _dataService.updateFactory(factory);
    _factories = _dataService.getAllFactories();
    notifyListeners();
  }
  Future<void> deleteFactory(String id) async {
    await _dataService.deleteFactory(id);
    _factories = _dataService.getAllFactories();
    notifyListeners();
  }

  // ========== Production Order ==========
  List<ProductionOrder> getProductionByFactory(String factoryId) =>
      _productionOrders.where((p) => p.factoryId == factoryId).toList();
  List<ProductionOrder> getProductionByProduct(String productId) =>
      _productionOrders.where((p) => p.productId == productId).toList();
  List<ProductionOrder> getProductionByStatus(String status) =>
      _productionOrders.where((p) => p.status == status).toList();
  List<ProductionOrder> get activeProductions =>
      _productionOrders.where((p) => ProductionStatus.activeStatuses.contains(p.status)).toList();

  Future<void> addProductionOrder(ProductionOrder order) async {
    await _dataService.addProductionOrder(order);
    _productionOrders = _dataService.getAllProductionOrders();
    notifyListeners();
  }

  Future<void> updateProductionOrder(ProductionOrder order) async {
    await _dataService.updateProductionOrder(order);
    _productionOrders = _dataService.getAllProductionOrders();
    notifyListeners();
  }

  Future<void> deleteProductionOrder(String id) async {
    await _dataService.deleteProductionOrder(id);
    _productionOrders = _dataService.getAllProductionOrders();
    notifyListeners();
  }

  /// 生产状态推进 + 三方联动
  /// planned -> materials -> producing -> quality -> completed
  /// completed 时自动创建入库记录
  Future<void> moveProductionStatus(String orderId, String newStatus) async {
    final order = _productionOrders.firstWhere((p) => p.id == orderId);
    order.status = newStatus;
    order.updatedAt = DateTime.now();

    if (newStatus == ProductionStatus.producing && order.startedDate == null) {
      order.startedDate = DateTime.now();
    }

    if (newStatus == ProductionStatus.completed) {
      order.completedDate = DateTime.now();
      // 三方联动: 生产完成 -> 自动入库
      if (!order.inventoryLinked) {
        final invId = generateId();
        final record = InventoryRecord(
          id: invId,
          productId: order.productId,
          productName: order.productName,
          productCode: order.productCode,
          type: 'in',
          quantity: order.quantity,
          reason: '生产入库 - ${order.factoryName}',
          notes: '批次: ${order.batchNumber.isNotEmpty ? order.batchNumber : order.id.substring(0, 8)}',
        );
        await _dataService.addInventoryRecord(record);
        order.inventoryLinked = true;
        order.linkedInventoryId = invId;
        _inventoryRecords = _dataService.getAllInventory();
      }
    }

    await _dataService.updateProductionOrder(order);
    _productionOrders = _dataService.getAllProductionOrders();
    notifyListeners();
  }

  /// 生产统计
  Map<String, dynamic> get productionStats {
    final active = activeProductions;
    int totalPlanned = 0;
    for (final p in active) { totalPlanned += p.quantity; }
    final completed = _productionOrders.where((p) => p.status == ProductionStatus.completed);
    int totalCompleted = 0;
    for (final p in completed) { totalCompleted += p.quantity; }
    return {
      'activeOrders': active.length,
      'totalPlannedQty': totalPlanned,
      'completedOrders': completed.length,
      'totalCompletedQty': totalCompleted,
      'factoryCount': _factories.where((f) => f.isActive).length,
    };
  }
}
