import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';

class DataService {
  static const _uuid = Uuid();
  late SupabaseClient _client;

  // Cache for offline-like speed
  List<Contact> _contactsCache = [];
  List<Deal> _dealsCache = [];
  List<Interaction> _interactionsCache = [];
  List<ContactRelation> _relationsCache = [];
  bool _initialized = false;

  Future<void> init() async {
    _client = Supabase.instance.client;
    await _refreshAllCaches();
    _initialized = true;
  }

  Future<void> _refreshAllCaches() async {
    await Future.wait([
      _refreshContacts(),
      _refreshDeals(),
      _refreshInteractions(),
      _refreshRelations(),
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

  // ========== Contact CRUD ==========
  List<Contact> getAllContacts() => List.from(_contactsCache);

  Contact? getContact(String id) {
    try {
      return _contactsCache.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveContact(Contact contact) async {
    final dbData = _contactToDb(contact);
    await _client.from('contacts').upsert(dbData);
    await _refreshContacts();
  }

  Future<void> deleteContact(String id) async {
    await _client.from('contacts').delete().eq('id', id);
    await _refreshContacts();
  }

  // ========== Relation CRUD ==========
  List<ContactRelation> getAllRelations() => List.from(_relationsCache);

  List<ContactRelation> getRelationsForContact(String contactId) {
    return _relationsCache
        .where((r) => r.fromContactId == contactId || r.toContactId == contactId)
        .toList();
  }

  Future<void> saveRelation(ContactRelation relation) async {
    final dbData = _relationToDb(relation);
    await _client.from('relations').upsert(dbData);
    await _refreshRelations();
  }

  Future<void> deleteRelation(String id) async {
    await _client.from('relations').delete().eq('id', id);
    await _refreshRelations();
  }

  // ========== Deal CRUD ==========
  List<Deal> getAllDeals() => List.from(_dealsCache);

  List<Deal> getDealsByStage(DealStage stage) =>
      _dealsCache.where((d) => d.stage == stage).toList();

  List<Deal> getDealsByContact(String contactId) =>
      _dealsCache.where((d) => d.contactId == contactId).toList();

  Future<void> saveDeal(Deal deal) async {
    final dbData = _dealToDb(deal);
    await _client.from('deals').upsert(dbData);
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
    final dbData = _interactionToDb(interaction);
    await _client.from('interactions').upsert(dbData);
    await _refreshInteractions();
  }

  Future<void> deleteInteraction(String id) async {
    await _client.from('interactions').delete().eq('id', id);
    await _refreshInteractions();
  }

  // ========== Stats ==========
  Map<String, dynamic> getStats() {
    final contacts = _contactsCache;
    final deals = _dealsCache;
    final activeDeals = deals.where((d) => d.stage != DealStage.closed && d.stage != DealStage.lost).toList();
    final closedDeals = deals.where((d) => d.stage == DealStage.closed).toList();

    double pipelineValue = 0;
    for (final d in activeDeals) {
      pipelineValue += d.amount;
    }
    double closedValue = 0;
    for (final d in closedDeals) {
      closedValue += d.amount;
    }

    final industryCount = <Industry, int>{};
    for (final c in contacts) {
      industryCount[c.industry] = (industryCount[c.industry] ?? 0) + 1;
    }

    final stageCount = <DealStage, int>{};
    for (final d in deals) {
      stageCount[d.stage] = (stageCount[d.stage] ?? 0) + 1;
    }

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
    };
  }

  String generateId() => _uuid.v4();

  // Force refresh from cloud
  Future<void> syncFromCloud() async {
    await _refreshAllCaches();
  }

  // ========== DB <-> Model Converters ==========
  // Supabase uses snake_case, Dart uses camelCase

  Contact _contactFromDb(Map<String, dynamic> db) => Contact(
    id: db['id'] as String,
    name: db['name'] as String? ?? '',
    nameReading: db['name_reading'] as String? ?? '',
    company: db['company'] as String? ?? '',
    position: db['position'] as String? ?? '',
    phone: db['phone'] as String? ?? '',
    email: db['email'] as String? ?? '',
    address: db['address'] as String? ?? '',
    industry: Industry.values.firstWhere((e) => e.name == db['industry'], orElse: () => Industry.other),
    strength: RelationshipStrength.values.firstWhere((e) => e.name == db['strength'], orElse: () => RelationshipStrength.cool),
    myRelation: MyRelationType.values.firstWhere((e) => e.name == db['my_relation'], orElse: () => MyRelationType.other),
    notes: db['notes'] as String? ?? '',
    referredBy: db['referred_by'] as String? ?? '',
    createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
    lastContactedAt: DateTime.tryParse(db['last_contacted_at'] ?? '') ?? DateTime.now(),
    tags: (db['tags'] is List) ? List<String>.from(db['tags']) : [],
    avatarUrl: db['avatar_url'] as String?,
  );

  Map<String, dynamic> _contactToDb(Contact c) => {
    'id': c.id,
    'name': c.name,
    'name_reading': c.nameReading,
    'company': c.company,
    'position': c.position,
    'phone': c.phone,
    'email': c.email,
    'address': c.address,
    'industry': c.industry.name,
    'strength': c.strength.name,
    'my_relation': c.myRelation.name,
    'notes': c.notes,
    'referred_by': c.referredBy,
    'created_at': c.createdAt.toIso8601String(),
    'last_contacted_at': c.lastContactedAt.toIso8601String(),
    'tags': c.tags,
    'avatar_url': c.avatarUrl,
  };

  Deal _dealFromDb(Map<String, dynamic> db) => Deal(
    id: db['id'] as String,
    title: db['title'] as String? ?? '',
    description: db['description'] as String? ?? '',
    contactId: db['contact_id'] as String? ?? '',
    contactName: db['contact_name'] as String? ?? '',
    stage: DealStage.values.firstWhere((e) => e.name == db['stage'], orElse: () => DealStage.lead),
    amount: (db['amount'] as num?)?.toDouble() ?? 0,
    currency: db['currency'] as String? ?? 'JPY',
    createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
    expectedCloseDate: DateTime.tryParse(db['expected_close_date'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(db['updated_at'] ?? '') ?? DateTime.now(),
    probability: (db['probability'] as num?)?.toDouble() ?? 10,
    notes: db['notes'] as String? ?? '',
    tags: (db['tags'] is List) ? List<String>.from(db['tags']) : [],
  );

  Map<String, dynamic> _dealToDb(Deal d) => {
    'id': d.id,
    'title': d.title,
    'description': d.description,
    'contact_id': d.contactId,
    'contact_name': d.contactName,
    'stage': d.stage.name,
    'amount': d.amount,
    'currency': d.currency,
    'created_at': d.createdAt.toIso8601String(),
    'expected_close_date': d.expectedCloseDate.toIso8601String(),
    'updated_at': d.updatedAt.toIso8601String(),
    'probability': d.probability,
    'notes': d.notes,
    'tags': d.tags,
  };

  Interaction _interactionFromDb(Map<String, dynamic> db) => Interaction(
    id: db['id'] as String,
    contactId: db['contact_id'] as String? ?? '',
    contactName: db['contact_name'] as String? ?? '',
    type: InteractionType.values.firstWhere((e) => e.name == db['type'], orElse: () => InteractionType.other),
    title: db['title'] as String? ?? '',
    notes: db['notes'] as String? ?? '',
    date: DateTime.tryParse(db['date'] ?? '') ?? DateTime.now(),
    dealId: db['deal_id'] as String?,
  );

  Map<String, dynamic> _interactionToDb(Interaction i) => {
    'id': i.id,
    'contact_id': i.contactId,
    'contact_name': i.contactName,
    'type': i.type.name,
    'title': i.title,
    'notes': i.notes,
    'date': i.date.toIso8601String(),
    'deal_id': i.dealId,
  };

  ContactRelation _relationFromDb(Map<String, dynamic> db) => ContactRelation(
    id: db['id'] as String,
    fromContactId: db['from_contact_id'] as String? ?? '',
    toContactId: db['to_contact_id'] as String? ?? '',
    fromName: db['from_name'] as String? ?? '',
    toName: db['to_name'] as String? ?? '',
    relationType: db['relation_type'] as String? ?? '',
    description: db['description'] as String? ?? '',
    createdAt: DateTime.tryParse(db['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> _relationToDb(ContactRelation r) => {
    'id': r.id,
    'from_contact_id': r.fromContactId,
    'to_contact_id': r.toContactId,
    'from_name': r.fromName,
    'to_name': r.toName,
    'relation_type': r.relationType,
    'description': r.description,
    'created_at': r.createdAt.toIso8601String(),
  };
}
