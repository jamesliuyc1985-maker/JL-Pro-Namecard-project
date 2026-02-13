import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// SyncService: Hive (local) + Firestore (cloud) bi-directional sync.
///
/// Architecture:
///   1. Write-through: Every local write is persisted to Hive immediately,
///      and queued for async Firestore upload.
///   2. Pull sync: On demand or on startup, pull Firestore snapshots and
///      merge into Hive (last-write-wins by `updatedAt`).
///   3. Offline: The app always works offline using Hive. When network
///      resumes, pending writes are flushed to Firestore.
class SyncService extends ChangeNotifier {
  // === Hive Boxes ===
  static const _boxContacts       = 'contacts';
  static const _boxDeals          = 'deals';
  static const _boxInteractions   = 'interactions';
  static const _boxRelations      = 'relations';
  static const _boxProducts       = 'products';
  static const _boxOrders         = 'orders';
  static const _boxInventory      = 'inventory';
  static const _boxTeam           = 'team';
  static const _boxTasks          = 'tasks';
  static const _boxAssignments    = 'assignments';
  static const _boxFactories      = 'factories';
  static const _boxProduction     = 'production';
  static const _boxPendingWrites  = 'pending_writes';
  static const _boxMeta           = 'sync_meta';

  late Box<String> _contacts;
  late Box<String> _deals;
  late Box<String> _interactions;
  late Box<String> _relations;
  late Box<String> _products;
  late Box<String> _orders;
  late Box<String> _inventory;
  late Box<String> _team;
  late Box<String> _tasks;
  late Box<String> _assignments;
  late Box<String> _factories;
  late Box<String> _production;
  late Box<String> _pendingWrites;
  late Box<String> _meta;

  FirebaseFirestore? _db;
  bool _firestoreEnabled = false;
  bool _syncing = false;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  String? _lastError;
  String? get lastError => _lastError;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  int get pendingWriteCount => _pendingWrites.length;

  /// Initialize Hive boxes. Call once at app startup.
  Future<void> init() async {
    await Hive.initFlutter();
    _contacts     = await Hive.openBox<String>(_boxContacts);
    _deals        = await Hive.openBox<String>(_boxDeals);
    _interactions = await Hive.openBox<String>(_boxInteractions);
    _relations    = await Hive.openBox<String>(_boxRelations);
    _products     = await Hive.openBox<String>(_boxProducts);
    _orders       = await Hive.openBox<String>(_boxOrders);
    _inventory    = await Hive.openBox<String>(_boxInventory);
    _team         = await Hive.openBox<String>(_boxTeam);
    _tasks        = await Hive.openBox<String>(_boxTasks);
    _assignments  = await Hive.openBox<String>(_boxAssignments);
    _factories    = await Hive.openBox<String>(_boxFactories);
    _production   = await Hive.openBox<String>(_boxProduction);
    _pendingWrites= await Hive.openBox<String>(_boxPendingWrites);
    _meta         = await Hive.openBox<String>(_boxMeta);

    final ts = _meta.get('lastSyncTime');
    if (ts != null) _lastSyncTime = DateTime.tryParse(ts);

    if (kDebugMode) debugPrint('[SyncService] Hive initialized. Pending writes: ${_pendingWrites.length}');
  }

  /// Enable Firestore sync. Call after Firebase.initializeApp.
  void enableFirestore() {
    _firestoreEnabled = true;
    _db = FirebaseFirestore.instance;
    if (kDebugMode) debugPrint('[SyncService] Firestore enabled');
    // Flush any pending writes
    _flushPendingWrites();
  }

  // =========================================================
  //  LOCAL CRUD (Hive write-through + queue Firestore write)
  // =========================================================

  Box<String> _boxFor(String collection) {
    switch (collection) {
      case 'contacts':      return _contacts;
      case 'deals':         return _deals;
      case 'interactions':  return _interactions;
      case 'relations':     return _relations;
      case 'products':      return _products;
      case 'sales_orders':  return _orders;
      case 'inventory':     return _inventory;
      case 'team':          return _team;
      case 'tasks':         return _tasks;
      case 'assignments':   return _assignments;
      case 'factories':     return _factories;
      case 'production':    return _production;
      default: throw ArgumentError('Unknown collection: $collection');
    }
  }

  /// Write a document locally (Hive) and queue Firestore write.
  Future<void> put(String collection, String docId, Map<String, dynamic> data) async {
    final box = _boxFor(collection);
    final json = jsonEncode(data);
    await box.put(docId, json);
    _queueWrite(collection, docId, 'put');
  }

  /// Delete a document locally and queue Firestore delete.
  Future<void> delete(String collection, String docId) async {
    final box = _boxFor(collection);
    await box.delete(docId);
    _queueWrite(collection, docId, 'delete');
  }

  /// Read all documents from a local Hive box.
  List<Map<String, dynamic>> getAll(String collection) {
    final box = _boxFor(collection);
    return box.values.map((v) {
      try { return jsonDecode(v) as Map<String, dynamic>; } catch (_) { return <String, dynamic>{}; }
    }).where((m) => m.isNotEmpty).toList();
  }

  /// Read a single document.
  Map<String, dynamic>? get(String collection, String docId) {
    final box = _boxFor(collection);
    final v = box.get(docId);
    if (v == null) return null;
    try { return jsonDecode(v) as Map<String, dynamic>; } catch (_) { return null; }
  }

  // =========================================================
  //  PENDING WRITE QUEUE
  // =========================================================

  void _queueWrite(String collection, String docId, String op) {
    final key = '${DateTime.now().millisecondsSinceEpoch}_${collection}_$docId';
    final payload = jsonEncode({'collection': collection, 'docId': docId, 'op': op});
    _pendingWrites.put(key, payload);
    notifyListeners();
    // Try flush immediately if online
    if (_firestoreEnabled) _flushPendingWrites();
  }

  Future<void> _flushPendingWrites() async {
    if (!_firestoreEnabled || _db == null || _pendingWrites.isEmpty) return;

    final keys = _pendingWrites.keys.toList();
    for (final key in keys) {
      final raw = _pendingWrites.get(key as String);
      if (raw == null) continue;
      try {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        final collection = payload['collection'] as String;
        final docId = payload['docId'] as String;
        final op = payload['op'] as String;

        if (op == 'delete') {
          await _db!.collection(collection).doc(docId).delete();
        } else {
          final localData = get(collection, docId);
          if (localData != null) {
            await _db!.collection(collection).doc(docId).set(localData);
          }
        }
        await _pendingWrites.delete(key);
      } catch (e) {
        if (kDebugMode) debugPrint('[SyncService] Flush error for $key: $e');
        // Leave in queue for retry
        break;
      }
    }
    notifyListeners();
  }

  // =========================================================
  //  FULL CLOUD SYNC (Pull + Merge)
  // =========================================================

  /// Pull all Firestore collections and merge into Hive.
  /// Strategy: last-write-wins based on `updatedAt` field.
  Future<void> syncFromCloud() async {
    if (!_firestoreEnabled || _db == null) {
      _status = SyncStatus.error;
      _lastError = 'Firestore未启用';
      notifyListeners();
      return;
    }
    if (_syncing) return;
    _syncing = true;
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // First flush pending writes
      await _flushPendingWrites();

      // Pull each collection
      const collections = ['contacts', 'deals', 'interactions', 'relations', 'products', 'sales_orders', 'inventory', 'team', 'tasks', 'assignments', 'factories', 'production'];
      for (final col in collections) {
        await _pullCollection(col);
      }

      _lastSyncTime = DateTime.now();
      await _meta.put('lastSyncTime', _lastSyncTime!.toIso8601String());
      _status = SyncStatus.success;
      if (kDebugMode) debugPrint('[SyncService] Full sync complete at $_lastSyncTime');
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      if (kDebugMode) debugPrint('[SyncService] Sync error: $e');
    }

    _syncing = false;
    notifyListeners();
  }

  Future<void> _pullCollection(String collection) async {
    try {
      final snap = await _db!.collection(collection).get().timeout(const Duration(seconds: 8));
      final box = _boxFor(collection);

      for (final doc in snap.docs) {
        final remoteData = doc.data();
        final localJson = box.get(doc.id);

        if (localJson == null) {
          // New from cloud — always accept
          await box.put(doc.id, jsonEncode(remoteData));
        } else {
          // Merge: compare updatedAt (last-write-wins)
          final localData = jsonDecode(localJson) as Map<String, dynamic>;
          final localTimeStr = localData['updatedAt']?.toString() ?? localData['updated_at']?.toString() ?? '';
          final remoteTimeStr = remoteData['updatedAt']?.toString() ?? remoteData['updated_at']?.toString() ?? '';
          final localTime = DateTime.tryParse(localTimeStr);
          final remoteTime = DateTime.tryParse(remoteTimeStr);

          if (localTime == null && remoteTime == null) {
            // Both lack updatedAt — remote wins (cloud is source of truth for cross-device)
            await box.put(doc.id, jsonEncode(remoteData));
          } else if (localTime == null) {
            // Local has no timestamp — remote wins
            await box.put(doc.id, jsonEncode(remoteData));
          } else if (remoteTime == null) {
            // Remote has no timestamp — keep local (it's newer since it has timestamp)
          } else if (remoteTime.isAfter(localTime)) {
            await box.put(doc.id, jsonEncode(remoteData));
          }
        }
      }
      if (kDebugMode) debugPrint('[SyncService] Pulled $collection: ${snap.docs.length} docs');
    } catch (e) {
      if (kDebugMode) debugPrint('[SyncService] Pull $collection error: $e');
    }
  }

  /// Push all local data to Firestore (full overwrite).
  Future<void> pushToCloud() async {
    if (!_firestoreEnabled || _db == null) return;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      const collections = ['contacts', 'deals', 'interactions', 'relations', 'products', 'sales_orders', 'inventory', 'team', 'tasks', 'assignments', 'factories', 'production'];
      for (final col in collections) {
        final box = _boxFor(col);
        for (final key in box.keys) {
          final val = box.get(key as String);
          if (val == null) continue;
          try {
            final data = jsonDecode(val) as Map<String, dynamic>;
            await _db!.collection(col).doc(key).set(data);
          } catch (_) {}
        }
      }
      _lastSyncTime = DateTime.now();
      await _meta.put('lastSyncTime', _lastSyncTime!.toIso8601String());
      _status = SyncStatus.success;
      // Clear pending writes after full push
      await _pendingWrites.clear();
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
    }
    notifyListeners();
  }

  /// Clear all local data (factory reset).
  Future<void> clearLocal() async {
    await _contacts.clear();
    await _deals.clear();
    await _interactions.clear();
    await _relations.clear();
    await _products.clear();
    await _orders.clear();
    await _inventory.clear();
    await _team.clear();
    await _tasks.clear();
    await _assignments.clear();
    await _factories.clear();
    await _production.clear();
    await _pendingWrites.clear();
    notifyListeners();
  }
}

enum SyncStatus { idle, syncing, success, error }
