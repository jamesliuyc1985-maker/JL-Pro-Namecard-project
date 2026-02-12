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
import '../services/notification_service.dart';
import '../services/sync_service.dart';

class CrmProvider extends ChangeNotifier {
  final DataService _dataService;
  final SyncService _syncService;
  NotificationService? _notificationService;
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

  CrmProvider(this._dataService, this._syncService);

  void setNotificationService(NotificationService ns) { _notificationService = ns; }
  void setUserId(String uid) { _dataService.setUserId(uid); }

  void _notify(String title, String body, NotificationType type, {String? relatedId}) {
    _notificationService?.add(CrmNotification(
      id: generateId(), title: title, body: body, type: type, relatedId: relatedId,
    ));
  }

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

  // === SyncService accessors ===
  SyncService get syncService => _syncService;
  SyncStatus get syncState => _syncService.status;
  int get pendingWriteCount => _syncService.pendingWriteCount;
  DateTime? get lastSyncTime => _syncService.lastSyncTime;

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
      // 1. SyncService: Hive ↔ Firestore 双向同步
      await _syncService.syncFromCloud();
      // 2. DataService: 内存缓存从云端拉取
      await _dataService.syncFromCloud();
      await loadAll();
      _syncStatus = '同步成功 (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")})';
    } catch (e) {
      _syncStatus = '同步失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// 全量推送本地数据到云端
  Future<void> pushToCloud() async {
    _isLoading = true;
    _syncStatus = '正在上传...';
    notifyListeners();
    try {
      await _syncService.pushToCloud();
      _syncStatus = '上传成功 (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")})';
    } catch (e) {
      _syncStatus = '上传失败: $e';
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

  // Contact (with Hive sync)
  Future<void> addContact(Contact contact) async {
    await _dataService.saveContact(contact);
    await _syncService.put('contacts', contact.id, contact.toJson());
    await loadAll();
  }
  Future<void> updateContact(Contact contact) async {
    await _dataService.saveContact(contact);
    await _syncService.put('contacts', contact.id, contact.toJson());
    await loadAll();
  }
  Future<void> deleteContact(String id) async {
    await _dataService.deleteContact(id);
    await _syncService.delete('contacts', id);
    await loadAll();
  }
  Contact? getContact(String id) => _dataService.getContact(id);

  // Relations (with Hive sync)
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relations.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();
  Future<void> addRelation(ContactRelation relation) async {
    await _dataService.saveRelation(relation);
    await _syncService.put('relations', relation.id, relation.toJson());
    await loadAll();
  }
  Future<void> updateRelation(ContactRelation relation) async {
    await _dataService.saveRelation(relation);
    await _syncService.put('relations', relation.id, relation.toJson());
    await loadAll();
  }
  Future<void> deleteRelation(String id) async {
    await _dataService.deleteRelation(id);
    await _syncService.delete('relations', id);
    await loadAll();
  }

  // Deal (with Hive sync)
  List<Deal> getDealsByStage(DealStage stage) => _deals.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _deals.where((d) => d.contactId == contactId).toList();
  Future<void> addDeal(Deal deal) async {
    await _dataService.saveDeal(deal);
    await _syncService.put('deals', deal.id, deal.toJson());
    await loadAll();
  }
  Future<void> updateDeal(Deal deal) async {
    await _dataService.saveDeal(deal);
    await _syncService.put('deals', deal.id, deal.toJson());
    await loadAll();
  }
  Future<void> deleteDeal(String id) async {
    await _dataService.deleteDeal(id);
    await _syncService.delete('deals', id);
    await loadAll();
  }

  Future<void> moveDealStage(String dealId, DealStage newStage) async {
    final deal = _deals.firstWhere((d) => d.id == dealId);
    final oldLabel = deal.stage.label;
    deal.stage = newStage;
    deal.updatedAt = DateTime.now();
    if (newStage == DealStage.completed) { deal.probability = 100; }
    if (newStage == DealStage.lost) { deal.probability = 0; }
    await _dataService.saveDeal(deal);
    _notify('管线变动', '${deal.contactName}: $oldLabel → ${newStage.label} | ¥${deal.amount.toStringAsFixed(0)}',
      NotificationType.pipelineChange, relatedId: dealId);
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

  // Product (with Hive sync)
  Product? getProduct(String id) => _dataService.getProduct(id);
  List<Product> getProductsByCategory(String category) => _products.where((p) => p.category == category).toList();
  Future<void> addProduct(Product product) async {
    await _dataService.saveProduct(product);
    await _syncService.put('products', product.id, product.toJson());
    await loadAll();
  }
  Future<void> deleteProduct(String id) async {
    await _dataService.deleteProduct(id);
    await _syncService.delete('products', id);
    await loadAll();
  }

  // Sales Order (with Hive sync)
  List<SalesOrder> getOrdersByContact(String contactId) => _orders.where((o) => o.contactId == contactId).toList();
  Future<void> addOrder(SalesOrder order) async {
    await _dataService.saveOrder(order);
    await _syncService.put('sales_orders', order.id, order.toJson());
    await loadAll();
  }
  Future<void> updateOrder(SalesOrder order) async {
    await _dataService.saveOrder(order);
    await _syncService.put('sales_orders', order.id, order.toJson());
    await loadAll();
  }
  Future<void> deleteOrder(String id) async {
    await _dataService.deleteOrder(id);
    await _syncService.delete('sales_orders', id);
    await loadAll();
  }

  // Create order + deal (预定模式: 不扣库存, 出货时才扣)
  Future<void> createOrderWithDeal(SalesOrder order) async {
    order.status = 'confirmed'; // 预定状态
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
    _notify('新订单创建', '${order.contactName} 下单 ${order.items.length}项产品, 金额: ¥${order.totalAmount.toStringAsFixed(0)}',
      NotificationType.orderCreated, relatedId: order.id);
    await loadAll();
  }

  /// 出货: 扣减库存 + 更新订单状态 + 推进管线
  Future<void> shipOrder(String orderId) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    order.status = 'shipped';
    order.updatedAt = DateTime.now();
    await _dataService.saveOrder(order);
    // 出货时扣减库存
    for (final item in order.items) {
      await _dataService.addInventoryRecord(InventoryRecord(
        id: generateId(),
        productId: item.productId,
        productName: item.productName,
        productCode: item.productCode,
        type: 'out',
        quantity: item.quantity,
        reason: '出货 - ${order.contactName}',
      ));
    }
    // 同步推进关联Deal
    final linkedDeal = _deals.where((d) => d.orderId == orderId).toList();
    for (final deal in linkedDeal) {
      deal.stage = DealStage.shipped;
      deal.updatedAt = DateTime.now();
      await _dataService.saveDeal(deal);
    }
    _notify('订单已出货', '${order.contactName} 的订单已出货，库存已扣减',
      NotificationType.orderShipped, relatedId: orderId);
    _inventoryRecords = _dataService.getAllInventory();
    await loadAll();
  }

  /// 预定数量(已下单未出货)
  int getReservedStock(String productId) {
    int reserved = 0;
    for (final o in _orders) {
      if (o.status == 'confirmed' || o.status == 'draft') {
        for (final item in o.items) {
          if (item.productId == productId) reserved += item.quantity;
        }
      }
    }
    return reserved;
  }

  /// 联系人销售统计
  Map<String, dynamic> getContactSalesStats(String contactId) {
    final contactOrders = _orders.where((o) => o.contactId == contactId).toList();
    double totalAmount = 0;
    int totalOrders = contactOrders.length;
    int completedOrders = 0;
    double completedAmount = 0;
    for (final o in contactOrders) {
      totalAmount += o.totalAmount;
      if (o.status == 'completed') {
        completedOrders++;
        completedAmount += o.totalAmount;
      }
    }
    final contactDeals = _deals.where((d) => d.contactId == contactId).toList();
    int activeDeals = contactDeals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost).length;
    double pipelineValue = 0;
    for (final d in contactDeals.where((d) => d.stage != DealStage.completed && d.stage != DealStage.lost)) {
      pipelineValue += d.amount;
    }
    return {
      'totalOrders': totalOrders,
      'totalAmount': totalAmount,
      'completedOrders': completedOrders,
      'completedAmount': completedAmount,
      'activeDeals': activeDeals,
      'pipelineValue': pipelineValue,
      'orders': contactOrders,
    };
  }

  /// 有销售线索的联系人ID集合
  Set<String> get contactsWithSales {
    final ids = <String>{};
    for (final o in _orders) { ids.add(o.contactId); }
    for (final d in _deals) { ids.add(d.contactId); }
    return ids;
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
        _notify('生产完成', '${order.productName} x${order.quantity} 已完成生产并入库 (工厂: ${order.factoryName})',
          NotificationType.productionComplete, relatedId: order.id);
      }
    }

    await _dataService.updateProductionOrder(order);
    _productionOrders = _dataService.getAllProductionOrders();
    notifyListeners();
  }

  /// 按渠道(代理/诊所/零售)的销售统计
  Map<String, Map<String, dynamic>> get channelSalesStats {
    final result = <String, Map<String, dynamic>>{
      'agent': {'label': '代理', 'orders': 0, 'amount': 0.0, 'shipped': 0, 'completed': 0},
      'clinic': {'label': '诊所', 'orders': 0, 'amount': 0.0, 'shipped': 0, 'completed': 0},
      'retail': {'label': '零售', 'orders': 0, 'amount': 0.0, 'shipped': 0, 'completed': 0},
    };
    for (final o in _orders) {
      final ch = result[o.priceType] ?? result['retail']!;
      ch['orders'] = (ch['orders'] as int) + 1;
      ch['amount'] = (ch['amount'] as double) + o.totalAmount;
      if (o.status == 'shipped') ch['shipped'] = (ch['shipped'] as int) + 1;
      if (o.status == 'completed') ch['completed'] = (ch['completed'] as int) + 1;
    }
    return result;
  }

  /// 按管线阶段的Deal统计
  Map<DealStage, Map<String, dynamic>> get pipelineStageStats {
    final result = <DealStage, Map<String, dynamic>>{};
    for (final stage in DealStage.values) {
      final stageDeals = _deals.where((d) => d.stage == stage).toList();
      double total = 0;
      for (final d in stageDeals) { total += d.amount; }
      result[stage] = {'count': stageDeals.length, 'amount': total};
    }
    return result;
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
