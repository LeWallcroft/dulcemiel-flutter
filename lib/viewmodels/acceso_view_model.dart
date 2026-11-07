import 'package:flutter/foundation.dart';

import '../models/sesion_usuario.dart';
import '../repositories/autenticacion_repository.dart';

class AccesoViewModel extends ChangeNotifier {
  AccesoViewModel(this._repository);

  final AutenticacionRepository _repository;
  bool _ocupado = false;
  SesionUsuario? _sesion;
  String? _error;
  String? _mensaje;

  bool get ocupado => _ocupado;
  SesionUsuario? get sesion => _sesion;
  String? get error => _error;
  String? get mensaje => _mensaje;

  Future<void> restaurar() async {
    _ocupado = true;
    notifyListeners();
    try {
      _sesion = await _repository.restaurarSesion();
      _error = null;
    } catch (error) {
      _sesion = null;
      _error = mensajeErrorAutenticacion(error);
    } finally {
      _ocupado = false;
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
    _ocupado = true;
    _error = null;
    _mensaje = null;
    notifyListeners();
    try {
      await _repository.restablecerContrasena(email);
      _mensaje = 'Si el correo está registrado, Firebase enviará un enlace para restablecer la contraseña.';
    } catch (error) {
      _error = mensajeErrorAutenticacion(error);
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    _ocupado = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.cerrarSesion();
      _sesion = null;
      _mensaje = 'Se cerró la sesión.';
    } catch (error) {
      _error = mensajeErrorAutenticacion(error);
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  Future<void> _ejecutar(Future<SesionUsuario> Function() accion) async {
    if (_ocupado) return;
    _ocupado = true;
    _error = null;
    _mensaje = null;
    notifyListeners();
    try {
      _sesion = await accion();
      _mensaje = 'Sesión iniciada correctamente.';
    } catch (error) {
      _error = mensajeErrorAutenticacion(error);
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }
}
