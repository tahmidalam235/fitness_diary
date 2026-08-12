import 'package:firebase_auth/firebase_auth.dart';

/// Returns the currently-signed-in Firebase user's uid, or `null` if
/// nobody is signed in. All Firestore paths are scoped to this uid so
/// the same code is correct regardless of where it's called from.
String? currentFirestoreUid() => FirebaseAuth.instance.currentUser?.uid;
