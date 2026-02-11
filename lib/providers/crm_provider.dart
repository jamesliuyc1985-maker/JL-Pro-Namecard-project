import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';
import '../services/data_service.dart';

class CrmProvider extends ChangeNotifier {
  final DataService _dataService;
  List<Contact> _contacts = [];
  List<Deal> _deals = [];
  List<Interaction> _interactions = [];
  List<ContactRelation> _relations = [];
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
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.company.toLowerCase().contains(q) ||
              c.nameReading.toLowerCase().contains(q) ||
              c.position.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<Contact> get allContacts => _contacts;
  List<Deal> get deals => _deals;
  List<Interaction> get interactions => _interactions;
  List<ContactRelation> get relations => _relations;
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
      _syncStatus = null;
    } catch (e) {
      _syncStatus = '同步失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Pull latest data from Supabase cloud
  Future<void> syncFromCloud() async {
    _isLoading = true;
    _syncStatus = '正在同步...';
    notifyListeners();
    try {
      await _dataService.syncFromCloud();
      _contacts = _dataService.getAllContacts();
      _deals = _dataService.getAllDeals();
      _interactions = _dataService.getAllInteractions();
      _relations = _dataService.getAllRelations();
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
  Future<void> addContact(Contact contact) async {
    await _dataService.saveContact(contact);
    await loadAll();
  }

  Future<void> updateContact(Contact contact) async {
    await _dataService.saveContact(contact);
    await loadAll();
  }

  Future<void> deleteContact(String id) async {
    await _dataService.deleteContact(id);
    await loadAll();
  }

  Contact? getContact(String id) => _dataService.getContact(id);

  // Relations
  List<ContactRelation> getRelationsForContact(String contactId) =>
      _relations.where((r) => r.fromContactId == contactId || r.toContactId == contactId).toList();

  Future<void> addRelation(ContactRelation relation) async {
    await _dataService.saveRelation(relation);
    await loadAll();
  }

  Future<void> deleteRelation(String id) async {
    await _dataService.deleteRelation(id);
    await loadAll();
  }

  // Deal
  List<Deal> getDealsByStage(DealStage stage) =>
      _deals.where((d) => d.stage == stage).toList();

  List<Deal> getDealsByContact(String contactId) =>
      _deals.where((d) => d.contactId == contactId).toList();

  Future<void> addDeal(Deal deal) async {
    await _dataService.saveDeal(deal);
    await loadAll();
  }

  Future<void> updateDeal(Deal deal) async {
    await _dataService.saveDeal(deal);
    await loadAll();
  }

  Future<void> deleteDeal(String id) async {
    await _dataService.deleteDeal(id);
    await loadAll();
  }

  Future<void> moveDealStage(String dealId, DealStage newStage) async {
    final deal = _deals.firstWhere((d) => d.id == dealId);
    deal.stage = newStage;
    deal.updatedAt = DateTime.now();
    if (newStage == DealStage.closed) deal.probability = 100;
    if (newStage == DealStage.lost) deal.probability = 0;
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

  Future<void> deleteInteraction(String id) async {
    await _dataService.deleteInteraction(id);
    await loadAll();
  }

  String generateId() => _dataService.generateId();
}
