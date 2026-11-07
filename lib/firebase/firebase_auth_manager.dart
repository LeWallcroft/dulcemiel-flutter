import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthManager {
  FirebaseAuthManager({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get usuario => _auth.currentUser;

  Future<User> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase no devolvió el usuario autenticado.');
    }
    return user;
  }

  Future<User> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase no devolvió la cuenta creada.');
    }
    await user.updateDisplayName(nombre.trim());
    await user.reload();
    return _auth.currentUser ?? user;
  }

  Future<void> enviarRestablecimiento(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<String> obtenerIdToken(User user) async {
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase no devolvió un token de identidad.');
    }
    return token;
  }

  Future<void> cerrarSesion() => _auth.signOut();

  Future<String> obtenerUidAnonimo() async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null) return currentUid;

    final credential = await _auth.signInAnonymously();
    final uid = credential.user?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Firebase no creó una sesión anónima.',
      );
    }
    return uid;
  }
}
