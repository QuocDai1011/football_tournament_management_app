import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final db = FirebaseFirestore.instance;
  // Enable offline persistence
  db.settings = const Settings(
      persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  return db;
});

/// Firestore Service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.read(firestoreProvider));
});
