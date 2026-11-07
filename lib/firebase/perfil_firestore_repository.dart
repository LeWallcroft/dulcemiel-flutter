import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilFirestoreRepository {
  PerfilFirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> asegurarPerfil(User user, {String? nombrePreferido}) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw StateError('Firebase no devolvió el correo de la cuenta.');
    }
    final nombre =
        (nombrePreferido ?? user.displayName)?.trim().isNotEmpty == true
        ? (nombrePreferido ?? user.displayName)!.trim()
        : email.split('@').first;
    if (nombre.length > 100) {
      throw const FormatException(
        'El nombre no puede superar los 100 caracteres.',
      );
    }

    final ref = _firestore.collection('usuarios').doc(user.uid);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.update({
        'nombre': nombre,
        'email': email,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'uid': user.uid,
        'nombre': nombre,
        'email': email,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    }
  }
}
