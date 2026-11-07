import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> crearSugerencia({
    required String mensaje,
    required String categoria,
    required String uid,
  }) async {
    await _firestore.collection('buzon_sugerencias').add({
      'mensaje': mensaje,
      'categoria': categoria,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'uid': uid,
    });
  }
}
