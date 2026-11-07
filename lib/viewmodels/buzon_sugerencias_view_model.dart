import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/sugerencias_repository.dart';

class BuzonSugerenciasViewModel extends ChangeNotifier {
  BuzonSugerenciasViewModel(this._repository);

  final SugerenciasRepository _repository;
  bool _enviando = false;
  String? _confirmacion;
  String? _error;

  bool get enviando => _enviando;
  String? get confirmacion => _confirmacion;
  String? get error => _error;

  Future<void> enviar({
    required String mensaje,
    required String categoria,
  }) async {
    if (_enviando) return;
    _enviando = true;
    _error = null;
    _confirmacion = null;
    notifyListeners();

    try {
      await _repository.enviar(mensaje: mensaje, categoria: categoria);
      _confirmacion = 'Tu sugerencia se guardó correctamente.';
    } on FormatException catch (exception) {
      _error = exception.message;
    } on FirebaseAuthException catch (exception) {
      _error = switch (exception.code) {
        'operation-not-allowed' || 'configuration-not-found' =>
          'El acceso anónimo no está habilitado en Firebase Authentication.',
        _ => 'No se pudo iniciar la sesión para enviar la sugerencia.',
      };
    } on FirebaseException catch (exception) {
      _error = switch (exception.code) {
        'permission-denied' => 'Firebase rechazó la sugerencia. Revisa la configuración de acceso y las reglas.',
        'unavailable' => 'Firestore no está disponible. Revisa la conexión e inténtalo de nuevo.',
        _ => 'No se pudo guardar la sugerencia en Firebase.',
      };
    } catch (_) {
      _error = 'No se pudo enviar la sugerencia. Inténtalo nuevamente.';
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }
}
