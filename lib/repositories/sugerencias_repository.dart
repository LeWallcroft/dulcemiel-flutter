import '../firebase/firebase_auth_manager.dart';
import '../firebase/firestore_repository.dart';

class SugerenciasRepository {
  SugerenciasRepository({
    required this._autenticacion,
    required this._firestore,
  });

  static const categorias = ['producto', 'servicio', 'app', 'otro'];

  final FirebaseAuthManager _autenticacion;
  final FirestoreRepository _firestore;

  Future<void> enviar({
    required String mensaje,
    required String categoria,
  }) async {
    final texto = mensaje.trim();
    if (texto.length < 10 || texto.length > 1000) {
      throw const FormatException(
        'La sugerencia debe tener entre 10 y 1000 caracteres.',
      );
    }
    if (!categorias.contains(categoria)) {
      throw const FormatException('Selecciona una categoría válida.');
    }

    final uid = await _autenticacion.obtenerUidAnonimo();
    await _firestore.crearSugerencia(
      mensaje: texto,
      categoria: categoria,
      uid: uid,
    );
  }
}
