import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/firebase_providers.dart';

/// Firestore collection name constants
class FirestoreCollections {
  FirestoreCollections._();
  static const String admins = 'admins';
  static const String tournaments = 'tournaments';
  static const String seasons = 'seasons';
  static const String teams = 'teams';
  static const String players = 'players';
  static const String matches = 'matches';
  static const String standings = 'standings';
  static const String awards = 'awards';
  static const String registrations = 'registrations';
  static const String notifications = 'notifications';
  static const String playerStatistics = 'player_statistics';
  static const String teamStatistics = 'team_statistics';
  // Subcollections
  static const String matchEvents = 'events';
  static const String matchLineups = 'lineups';
}

/// Base Firestore service with generic CRUD
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  // --- Generic helpers ---

  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _db.collection(collection).add(data);
  }

  Future<void> setDocument(
    String collection,
    String id,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _db
        .collection(collection)
        .doc(id)
        .set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDocument(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection,
    String id,
  ) async {
    return await _db.collection(collection).doc(id).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> documentStream(
    String collection,
    String id,
  ) {
    return _db.collection(collection).doc(id).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(
    String collection, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    for (final filter in filters ?? []) {
      query = query.where(filter.field, isEqualTo: filter.isEqualTo, isGreaterThan: filter.isGreaterThan);
    }

    for (final order in orderBy ?? []) {
      query = query.orderBy(order.field, descending: order.descending);
    }

    if (limit != null) query = query.limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    return query.snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String collection, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        if (filter.isEqualTo != null) {
          query = query.where(filter.field, isEqualTo: filter.isEqualTo);
        } else if (filter.isGreaterThan != null) {
          query = query.where(filter.field, isGreaterThan: filter.isGreaterThan);
        } else if (filter.arrayContains != null) {
          query = query.where(filter.field, arrayContains: filter.arrayContains);
        }
      }
    }

    for (final order in orderBy ?? []) {
      query = query.orderBy(order.field, descending: order.descending);
    }

    if (limit != null) query = query.limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    return await query.get();
  }

  /// Batch write utility
  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _db.batch();
    for (final op in operations) {
      final ref = _db.collection(op.collection).doc(op.id);
      switch (op.type) {
        case BatchOperationType.set:
          batch.set(ref, op.data!, SetOptions(merge: op.merge));
        case BatchOperationType.update:
          batch.update(ref, op.data!);
        case BatchOperationType.delete:
          batch.delete(ref);
      }
    }
    await batch.commit();
  }

  /// Run a Firestore transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) {
    return _db.runTransaction(updateFunction);
  }

  /// Subcollection stream
  Stream<QuerySnapshot<Map<String, dynamic>>> subcollectionStream(
    String collection,
    String docId,
    String subcollection, {
    List<QueryOrder>? orderBy,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(collection)
        .doc(docId)
        .collection(subcollection);

    for (final order in orderBy ?? []) {
      query = query.orderBy(order.field, descending: order.descending);
    }

    if (limit != null) query = query.limit(limit);
    return query.snapshots();
  }

  /// Add subcollection document
  Future<DocumentReference<Map<String, dynamic>>> addSubdocument(
    String collection,
    String docId,
    String subcollection,
    Map<String, dynamic> data,
  ) async {
    return await _db
        .collection(collection)
        .doc(docId)
        .collection(subcollection)
        .add(data);
  }
}

// --- Query helpers ---
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic arrayContains;

  const QueryFilter.equalTo(this.field, this.isEqualTo)
      : isGreaterThan = null, arrayContains = null;
  const QueryFilter.greaterThan(this.field, this.isGreaterThan)
      : isEqualTo = null, arrayContains = null;
  const QueryFilter.arrayContainsFilter(this.field, this.arrayContains)
      : isEqualTo = null, isGreaterThan = null;
}

class QueryOrder {
  final String field;
  final bool descending;

  const QueryOrder(this.field, {this.descending = false});
}

// --- Batch operation ---
enum BatchOperationType { set, update, delete }

class BatchOperation {
  final String collection;
  final String id;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  final bool merge;

  const BatchOperation.set(this.collection, this.id, this.data, {this.merge = false})
      : type = BatchOperationType.set;
  const BatchOperation.update(this.collection, this.id, this.data)
      : type = BatchOperationType.update, merge = false;
  const BatchOperation.delete(this.collection, this.id)
      : type = BatchOperationType.delete, data = null, merge = false;
}

/// Riverpod provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.read(firestoreProvider));
});
