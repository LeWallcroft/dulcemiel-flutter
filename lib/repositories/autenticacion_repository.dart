import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firebase_auth_manager.dart';
import '../firebase/perfil_firestore_repository.dart';
import '../models/sesion_usuario.dart';
import '../network/api_service.dart';
import 'sesion_repository.dart';

class AutenticacionRepository {
  AutenticacionRepository({
    required this._autenticacion,
    required this._perfiles,
    required this._api,
    required this._sesiones,
  });

  final FirebaseAuthManager _autenticacion;
  final PerfilFirestoreRepository _perfiles;
  final ApiService _api;
  final SesionRepository _sesiones;

  Future<SesionUsuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final user = await _autenticacion.iniciarSesion(
      email: email,
      password: password,
    );
    return _intercambiar(user);
  }

  Future<SesionUsuario> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final normalizedName = nombre.trim();
    if (normalizedName.isEmpty || normalizedName.length > 100) {
      throw const FormatException(
        'El nombre debe tener entre 1 y 100 caracteres.',
      );
    }
    if (password.length < 6) {
      throw const FormatException(
        'La contraseña debe tener al menos 6 caracteres.',
      );
    }
    final user = await _autenticacion.registrar(
      nombre: normalizedName,
      email: email,
      password: password,
    );
    return _intercambiar(user, nombre: normalizedName);
  }

  Future<void> restablecerContrasena(String email) async {
    if (!email.contains('@') || email.trim().isEmpty) {
      throw const FormatException('Escribe un correo válido.');
    }
    await _autenticacion.enviarRestablecimiento(email);
  }

  Future<SesionUsuario?> restaurarSesion() async {
    final user = _autenticacion.usuario;
    if (user == null || user.isAnonymous) {
      await _sesiones.borrar();
      return null;
    }
    return _intercambiar(user, nombre: user.displayName);
  }

  Future<void> cerrarSesion() async {
    await _autenticacion.cerrarSesion();
    await _sesiones.borrar();
  }

  Future<Map<String, dynamic>> consultarPerfil() async {
    final sesionActual = await _sesiones.leer();
    if (sesionActual == null) {
      throw const ApiException('Inicia sesión para consultar tu perfil.');
    }
    final response = await _api.consultarPerfil();
    final usuario = response['usuario'];
    if (response['success'] != true || usuario is! Map<String, dynamic>) {
      throw ApiException(
        response['message']?.toString() ?? 'No se pudo cargar tu perfil.',
      );
    }
    final sesionActualizada = SesionUsuario.fromApi(
      token: sesionActual.tokenApi,
      usuario: usuario,
    );
    await _sesiones.guardar(sesionActualizada);
    return usuario;
  }

  Future<SesionUsuario> _intercambiar(User user, {String? nombre}) async {
    await _perfiles.asegurarPerfil(user, nombrePreferido: nombre);
    final idToken = await _autenticacion.obtenerIdToken(user);
    final response = await _api.intercambiarTokenFirebase(
      idToken: idToken,
      nombre: nombre ?? user.displayName,
    );
    final token = response['token']?.toString();
    final userData = response['usuario'];
    if (response['success'] != true || token == null || token.isEmpty) {
      throw ApiException(
        response['message']?.toString() ?? 'El servidor no confirmó la sesión.',
      );
    }
    if (userData is! Map<String, dynamic>) {
      throw const ApiException(
        'El servidor no devolvió el perfil de Dulce Miel.',
      );
    }
    final sesion = SesionUsuario.fromApi(token: token, usuario: userData);
    await _sesiones.guardar(sesion);
    return sesion;
  }
}

String mensajeErrorAutenticacion(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Este correo ya está registrado. Inicia sesión o restablece tu contraseña.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'invalid-email' => 'Escribe un correo válido.',
      'too-many-requests' => 'Se realizaron demasiados intentos. Espera un momento e inténtalo nuevamente.',
      'network-request-failed' =>
        'No hay conexión con Firebase. Revisa tu red.',
      _ => 'No se pudo completar la autenticación. Revisa los datos e inténtalo nuevamente.',
    };
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Firestore rechazó el perfil. Revisa las reglas de la colección usuarios.';
    }
    if (error.code == 'unavailable') {
      return 'Firestore no está disponible. Revisa tu conexión e inténtalo nuevamente.';
    }
    return 'No se pudo completar la operación en Firebase.';
  }
  if (error is ApiException) return error.message;
  if (error is FormatException || error is StateError) return error.toString();
  return 'No se pudo iniciar sesión. Revisa la conexión e inténtalo nuevamente.';
}
