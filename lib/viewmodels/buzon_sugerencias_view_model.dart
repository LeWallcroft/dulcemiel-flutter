import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ui_state.dart';
import '../repositories/sugerencias_repository.dart';

class BuzonSugerenciasViewModel extends ChangeNotifier {
  BuzonSugerenciasViewModel(this._repository);

  final SugerenciasRepository _repository;
  UiState<String> state = UiState.initial();

  bool get enviando => state.isLoading;
  String? get confirmacion => state.isSuccess ? state.data : null;
  String? get error => state.hasError ? state.message : null;

  Future<void> enviar({
    required String mensaje,
    required String categoria,
  }) async {
    if (enviando) return;
    state = UiState.loading(previous: state.data);
    notifyListeners();

    try {
      await _repository.enviar(mensaje: mensaje, categoria: categoria);
      state = UiState.success('Tu sugerencia se guardó correctamente.');
    } on FormatException catch (exception) {
      state = UiState.error(exception.message);
    } on FirebaseAuthException catch (exception) {
      state = UiState.error(switch (exception.code) {
        'operation-not-allowed' || 'configuration-not-found' =>
          'El acceso anónimo no está habilitado en Firebase Authentication.',
        _ => 'No se pudo iniciar la sesión para enviar la sugerencia.',
      });
    } on FirebaseException catch (exception) {
      state = UiState.error(switch (exception.code) {
        'permission-denied' => 'Firebase rechazó la sugerencia. Revisa la configuración de acceso y las reglas.',
        'unavailable' => 'Firestore no está disponible. Revisa la conexión e inténtalo de nuevo.',
        _ => 'No se pudo guardar la sugerencia en Firebase.',
      });
    } catch (_) {
      state = UiState.error(
        'No se pudo enviar la sugerencia. Inténtalo nuevamente.',
      );
    } finally {
      notifyListeners();
    }
  }
}
