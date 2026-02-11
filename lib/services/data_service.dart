import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../models/product.dart';
import '../models/inventory.dart';
import '../models/team.dart';
import '../models/task.dart';

class DataService {
  static const _uuid = Uuid();
  late SupabaseClient _client;

  List<Contact> _contactsCache = [];
  List<Deal> _dealsCache = [];
  List<Interaction> _interactionsCache = [];
  List<ContactRelation> _relationsCache = [];
  List<Product> _productsCache = [];
  List<SalesOrder> _ordersCache = [];
  final List<InventoryRecord> _inventoryCache = [];
  final List<TeamMember> _teamCache = [];
  final List<Task> _taskCache = [];
  bool _productsTableExists = false;
  bool _ordersTableExists = false;

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
    if (idx >= 0) { _teamCache[idx] = member; }
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
    if (idx >= 0) { _taskCache[idx] = task; }
  }

  Future<void> deleteTask(String id) async {
    _taskCache.removeWhere((t) => t.id == id);
  }

  Map<String, double> getWorkloadStats() {
    final stats = <String, double>{};
    for (final t in _taskCache) {
      stats[t.assigneeName] = (stats[t.assigneeName] ?? 0) + (t.actualHours > 0 ? t.actualHours : t.estimatedHours);
    }
    return stats;
  }

  Future<void> init() async {
    _client = Supabase.instance.client;
    await _checkTables();
    await _refreshAllCaches();
  }

  Future<void> _checkTables() async {
    try {
      await _client.from('products').select('id').limit(1);
      _productsTableExists = true;
    } catch (_) {
      _productsTableExists = false;
    }
    try {
      await _client.from('sales_orders').select('id').limit(1);
      _ordersTableExists = true;
    } catch (_) {
      _ordersTableExists = false;
    }
  }

  Future<void> _refreshAllCaches() async {
    await Future.wait([
      _refreshContacts(),
      _refreshDeals(),
      _refreshInteractions(),
      _refreshRelations(),
      _refreshProducts(),
      _refreshOrders(),
    ]);
  }

  Future<void> _refreshContacts() async {
    try {
      final data = await _client.from('contacts').select().order('last_contacted_at', ascending: false);
      _contactsCache = (data as List).map((e) => _contactFromDb(e)).toList();
    } catch (e) {
      if (_contactsCache.isEmpty) rethrow;
    }
  }

  Future<void> _refreshDeals() async {
    try {
      final data = await _client.from('deals').select().order('updated_at', ascending: false);
      _dealsCache = (data as List).map((e) => _dealFromDb(e)).toList();
    } catch (e) {
      if (_dealsCache.isEmpty) rethrow;
    }
  }

  Future<void> _refreshInteractions() async {
    try {
      final data = await _client.from('interactions').select().order('date', ascending: false);
      _interactionsCache = (data as List).map((e) => _interactionFromDb(e)).toList();
    } catch (e) {
      if (_interactionsCache.isEmpty) rethrow;
    }
  }

  Future<void> _refreshRelations() async {
    try {
      final data = await _client.from('relations').select();
      _relationsCache = (data as List).map((e) => _relationFromDb(e)).toList();
    } catch (e) {
      if (_relationsCache.isEmpty) rethrow;
    }
  }

  Future<void> _refreshProducts() async {
    if (_productsTableExists) {
      try {
        final data = await _client.from('products').select().order('code');
        _productsCache = (data as List).map((e) => Product.fromJson(e)).toList();
        return;
      } catch (_) {}
    }
    if (_productsCache.isEmpty) {
      _productsCache = _builtInProducts();
    }
  }

  Future<void> _refreshOrders() async {
    if (_ordersTableExists) {
      try {
        final data = await _client.from('sales_orders').select().order('updated_at', ascending: false);
        _ordersCache = (data as List).map((e) => SalesOrder.fromJson(e)).toList();
        return;
      } catch (_) {}
    }
  }

  // ========== Contact CRUD ==========
  List<Contact> getAllContacts() => List.from(_contactsCache);

  Contact? getContact(String id) {
    try { return _contactsCache.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  Future<void> saveContact(Contact contact) async {
    await _client.from('contacts').upsert(_contactToDb(contact));
    await _refreshContacts();
  }

  Future<void> deleteContact(String id) async {
    await _client.from('contacts').delete().eq('id', id);
    try {
      await _client.from('interactions').delete().eq('contact_id', id);
      await _client.from('relations').delete().or('from_contact_id.eq.$id,to_contact_id.eq.$id');
    } catch (_) {}
    await _refreshContacts();
    await _refreshInteractions();
    await _refreshRelations();
  }

  // ========== Relation CRUD ==========
  List<ContactRelation> getAllRelations() => List.from(_relationsCache);
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relationsCache.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();

  Future<void> saveRelation(ContactRelation relation) async {
    await _client.from('relations').upsert(_relationToDb(relation));
    await _refreshRelations();
  }

  Future<void> deleteRelation(String id) async {
    await _client.from('relations').delete().eq('id', id);
    await _refreshRelations();
  }

  // ========== Deal CRUD ==========
  List<Deal> getAllDeals() => List.from(_dealsCache);
  List<Deal> getDealsByStage(DealStage stage) => _dealsCache.where((d) => d.stage == stage).toList();
  List<Deal> getDealsByContact(String contactId) => _dealsCache.where((d) => d.contactId == contactId).toList();

  Future<void> saveDeal(Deal deal) async {
    await _client.from('deals').upsert(_dealToDb(deal));
    await _refreshDeals();
  }

  Future<void> deleteDeal(String id) async {
    await _client.from('deals').delete().eq('id', id);
    await _refreshDeals();
  }

  // ========== Interaction CRUD ==========
  List<Interaction> getAllInteractions() => List.from(_interactionsCache);
  List<Interaction> getInteractionsByContact(String contactId) =>
      _interactionsCache.where((i) => i.contactId == contactId).toList();

  Future<void> saveInteraction(Interaction interaction) async {
    await _client.from('interactions').upsert(_interactionToDb(interaction));
    await _refreshInteractions();
  }

  Future<void> deleteInteraction(String id) async {
    await _client.from('interactions').delete().eq('id', id);
    await _refreshInteractions();
  }

  // ========== Product CRUD ==========
  List<Product> getAllProducts() => List.from(_productsCache);
  List<Product> getProductsByCategory(String category) => _productsCache.where((p) => p.category == category).toList();
  Product? getProduct(String id) {
    try { return _productsCache.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }

  Future<void> saveProduct(Product product) async {
    if (_productsTableExists) {
      await _client.from('products').upsert(product.toJson());
      await _refreshProducts();
    } else {
      final idx = _productsCache.indexWhere((p) => p.id == product.id);
      if (idx >= 0) { _productsCache[idx] = product; } else { _productsCache.add(product); }
    }
  }

  Future<void> deleteProduct(String id) async {
    if (_productsTableExists) {
      await _client.from('products').delete().eq('id', id);
      await _refreshProducts();
    } else {
      _productsCache.removeWhere((p) => p.id == id);
    }
  }

  // ========== Sales Order CRUD ==========
  List<SalesOrder> getAllOrders() => List.from(_ordersCache);
  List<SalesOrder> getOrdersByContact(String contactId) => _ordersCache.where((o) => o.contactId == contactId).toList();

  Future<void> saveOrder(SalesOrder order) async {
    if (_ordersTableExists) {
      await _client.from('sales_orders').upsert(order.toJson());
      await _refreshOrders();
    } else {
      final idx = _ordersCache.indexWhere((o) => o.id == order.id);
      if (idx >= 0) { _ordersCache[idx] = order; } else { _ordersCache.add(order); }
    }
  }

  Future<void> deleteOrder(String id) async {
    if (_ordersTableExists) {
      await _client.from('sales_orders').delete().eq('id', id);
      await _refreshOrders();
    } else {
      _ordersCache.removeWhere((o) => o.id == id);
    }
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
        productId: p.id,
        productName: p.name,
        productCode: p.code,
        currentStock: 0,
      );
    }
    for (final r in _inventoryCache) {
      final stock = stockMap[r.productId];
      if (stock != null) {
        if (r.type == 'in') {
          stock.currentStock += r.quantity;
        } else if (r.type == 'out') {
          stock.currentStock -= r.quantity;
        } else if (r.type == 'adjust') {
          stock.currentStock = r.quantity;
        }
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
      'totalContacts': contacts.length,
      'activeDeals': activeDeals.length,
      'pipelineValue': pipelineValue,
      'closedValue': closedValue,
      'closedDeals': closedDeals.length,
      'winRate': deals.isNotEmpty ? (closedDeals.length / deals.length * 100) : 0.0,
      'industryCount': industryCount,
      'stageCount': stageCount,
      'hotContacts': contacts.where((c) => c.strength == RelationshipStrength.hot).length,
      'totalProducts': _productsCache.length,
      'totalOrders': _ordersCache.length,
      'completedOrders': orderCount,
      'salesTotal': salesTotal,
      'totalInventoryRecords': _inventoryCache.length,
    };
  }

  String generateId() => _uuid.v4();
  Future<void> syncFromCloud() async => await _refreshAllCaches();

  // ========== Built-in Product Catalog ==========
  List<Product> _builtInProducts() => [
    Product(id: 'prod-exo-001', code: 'NS-EX0-001', name: '外泌体原液 300億', nameJa: 'エクソソーム原液 300億単位', category: 'exosome',
      description: '高純度外泌体原液，含300億単位外泌体粒子。適用于肌膚再生、抗老化治療。採用先進的超離心分離技術，確保高純度和高活性。',
      specification: '300億単位/瓶', unitsPerBox: 5, agentPrice: 30000, clinicPrice: 40000, retailPrice: 100000,
      agentTotalPrice: 150000, clinicTotalPrice: 200000, retailTotalPrice: 500000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脈注射/点滴/局部注射', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-exo-002', code: 'NS-EX0-002', name: '外泌体原液 500億', nameJa: 'エクソソーム原液 500億単位', category: 'exosome',
      description: '高濃度外泌体原液，含500億単位外泌体粒子。更高浓度配方，適用于深層肌膚修復和再生醫療。',
      specification: '500億単位/瓶', unitsPerBox: 5, agentPrice: 45000, clinicPrice: 60000, retailPrice: 150000,
      agentTotalPrice: 225000, clinicTotalPrice: 300000, retailTotalPrice: 750000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脈注射/点滴/局部注射', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-exo-003', code: 'NS-EX0-003', name: '外泌体原液 1000億', nameJa: 'エクソソーム原液 1000億単位', category: 'exosome',
      description: '超高濃度外泌体原液，含1000億単位外泌体粒子。頂級配方，專業醫療機構首選。',
      specification: '1000億単位/瓶', unitsPerBox: 5, agentPrice: 105000, clinicPrice: 140000, retailPrice: 350000,
      agentTotalPrice: 525000, clinicTotalPrice: 700000, retailTotalPrice: 1750000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脈注射/点滴/局部注射', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-nad-001', code: 'NS-NAD-001', name: 'NAD+ 注射液 250mg', nameJa: 'NAD+ 注射液 250mg', category: 'nad',
      description: '高純度NAD+注射液，每瓶含250mg NAD+。促進細胞能量代謝，抗衰老核心成分。',
      specification: '250mg/瓶', unitsPerBox: 5, agentPrice: 12000, clinicPrice: 16000, retailPrice: 40000,
      agentTotalPrice: 60000, clinicTotalPrice: 80000, retailTotalPrice: 200000,
      storageMethod: '2-8°C 冷藏保存', shelfLife: '2年', usage: '静脈注射/点滴', notes: '代理折扣30%、诊所折扣40%'),
    Product(id: 'prod-nmn-001', code: 'NS-NMN-001', name: 'NMN 点鼻/吸入', nameJa: 'NMN 点鼻・吸入', category: 'nmn',
      description: 'NMN点鼻/吸入制剂。通過鼻腔/吸入方式直接吸收，生物利用度高。適用于日常保健和抗衰老。',
      specification: '点鼻/吸入型', unitsPerBox: 1, agentPrice: 22000, clinicPrice: 32000, retailPrice: 60000,
      agentTotalPrice: 22000, clinicTotalPrice: 32000, retailTotalPrice: 60000,
      storageMethod: '常温保存', shelfLife: '2年', usage: '点鼻/吸入使用', notes: 'NMN 700mg配合'),
    Product(id: 'prod-nmn-002', code: 'NS-NMN-002', name: 'NMN 胶囊', nameJa: 'NMN カプセル', category: 'nmn',
      description: 'NMN口服胶囊。每粒含高純度NMN，方便日常服用。支持NAD+水平提升，促進細胞修復和能量代謝。',
      specification: '胶囊型', unitsPerBox: 1, agentPrice: 9000, clinicPrice: 12000, retailPrice: 30000,
      agentTotalPrice: 9000, clinicTotalPrice: 12000, retailTotalPrice: 30000,
      storageMethod: '常温保存', shelfLife: '2年', usage: '每日1-2粒，口服'),
  ];

  // ========== DB <-> Model Converters ==========
  Contact _contactFromDb(Map<String, dynamic> db) => Contact(
    id: db['id'] as String, name: db['name'] as String? ?? '', nameReading: db['name_reading'] as String? ?? '',
    company: db['company'] as String? ?? '', position: db['position'] as String? ?? '',
    phone: db['phone'] as String? ?? '', email: db['email'] as String? ?? '', address: db['address'] as String? ?? '',
    industry: Industry.values.firstWhere((e) => e.name == db['industry'], orElse: () => Industry.other),
    strength: RelationshipStrength.values.firstWhere((e) => e.name == db['strength'], orElse: () => RelationshipStrength.cool),
    myRelation: MyRelationType.values.firstWhere((e) => e.name == db['my_relation'], orElse: () => MyRelationType.other),
    notes: db['notes'] as String? ?? '', referredBy: db['referred_by'] as String? ?? '',
    createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
    lastContactedAt: DateTime.tryParse(db['last_contacted_at'] ?? '') ?? DateTime.now(),
    tags: (db['tags'] is List) ? List<String>.from(db['tags']) : [], avatarUrl: db['avatar_url'] as String?,
  );

  Map<String, dynamic> _contactToDb(Contact c) => {
    'id': c.id, 'name': c.name, 'name_reading': c.nameReading, 'company': c.company, 'position': c.position,
    'phone': c.phone, 'email': c.email, 'address': c.address, 'industry': c.industry.name, 'strength': c.strength.name,
    'my_relation': c.myRelation.name, 'notes': c.notes, 'referred_by': c.referredBy,
    'created_at': c.createdAt.toIso8601String(), 'last_contacted_at': c.lastContactedAt.toIso8601String(),
    'tags': c.tags, 'avatar_url': c.avatarUrl,
  };

  Deal _dealFromDb(Map<String, dynamic> db) => Deal(
    id: db['id'] as String, title: db['title'] as String? ?? '', description: db['description'] as String? ?? '',
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
    id: db['id'] as String, contactId: db['contact_id'] as String? ?? '', contactName: db['contact_name'] as String? ?? '',
    type: InteractionType.values.firstWhere((e) => e.name == db['type'], orElse: () => InteractionType.other),
    title: db['title'] as String? ?? '', notes: db['notes'] as String? ?? '',
    date: DateTime.tryParse(db['date'] ?? '') ?? DateTime.now(), dealId: db['deal_id'] as String?,
  );

  Map<String, dynamic> _interactionToDb(Interaction i) => {
    'id': i.id, 'contact_id': i.contactId, 'contact_name': i.contactName, 'type': i.type.name,
    'title': i.title, 'notes': i.notes, 'date': i.date.toIso8601String(), 'deal_id': i.dealId,
  };

  ContactRelation _relationFromDb(Map<String, dynamic> db) => ContactRelation(
    id: db['id'] as String, fromContactId: db['from_contact_id'] as String? ?? '',
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
