import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Returns a fresh v4 UUID string suitable for use as a Firestore
/// document id and as the stable `firestoreId` column on every
/// syncable Drift row.
///
/// Centralized so tests can mock the generator if needed.
String newFirestoreId() => _uuid.v4();
