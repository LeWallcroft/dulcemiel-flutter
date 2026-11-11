import 'package:flutter/foundation.dart';

import '../models/sesion_usuario.dart';
import '../models/ui_state.dart';
import '../repositories/autenticacion_repository.dart';

class AccesoViewModel extends ChangeNotifier {
  AccesoViewModel(this._repository);

  final AutenticacionRepository _repository;
  UiState<SesionUsuario?> state = UiState.initial();
  UiState<String> actionState = UiState.initial();

  bool get ocupado => state.isLoading || actionState.isLoading;
  SesionUsuario? get sesion => state.data;
  String? get error => actionState.hasError
      ? actionState.message
      : state.hasError
      ? state.message
      : null;
  String? get mensaje =>
      actionState.isSuccess ? actionState.message ?? actionState.data : null;

  Future<void> restaurar() async {
    state = UiState.loading(previous: state.data);
    notifyListeners();
    try {
      final restored = await _repository.restaurarSesion();
      state = restored == null
          ? UiState.empty(null)
          : UiState.success(restored);
    } catch (error) {
      state = UiState.error(mensajeErrorAutenticacion(error));
    } finally {
      notifyListeners();
    }
  }

  Future<void> iniciarSesion(String email, String password) async {
    await _ejecutar(
      () => _repository.iniciarSesion(email: email, password: password),
    );
  }

  Future<void> registrar(String nombre, String email, String password) async {
    await _ejecutar(
      () => _repository.registrar(
        nombre: nombre,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> restablecerContrasena(String email) async {
    actionState = UiState.loading(previous: actionState.data);
    notifyListeners();
    try {
      await _repository.restablecerContrasena(email);
      actionState = UiState.success(
        'Si el correo está registrado, Firebase enviará un enlace para restablecer la contraseña.',
      );
    } catch (error) {
      actionState = UiState.error(mensajeErrorAutenticacion(error));
    } finally {
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    actionState = UiState.loading(previous: actionState.data);
    notifyListeners();
    try {
      await _repository.cerrarSesion();
      state = UiState.empty(null);
      actionState = UiState.success('Se cerró la sesión.');
    } catch (error) {
      actionState = UiState.error(mensajeErrorAutenticacion(error));
    } finally {
      notifyListeners();
    }
  }

  Future<void> _ejecutar(Future<SesionUsuario> Function() accion) async {
    if (ocupado) return;
    actionState = UiState.loading();
    notifyListeners();
    try {
      state = UiState.success(await accion());
      actionState = UiState.success('Sesión iniciada correctamente.');
    } catch (error) {
      actionState = UiState.error(mensajeErrorAutenticacion(error));
    } finally {
      notifyListeners();
    }
  }
}
