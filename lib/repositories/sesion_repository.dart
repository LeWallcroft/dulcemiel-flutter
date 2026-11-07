import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/sesion_usuario.dart';

class SesionRepository {
  SesionRepository(this._secureStorage);

  static const _key = 'dulce_miel_api_session';
  final FlutterSecureStorage _secureStorage;

  Future<SesionUsuario?> leer() async {
    final encoded = await _secureStorage.read(key: _key);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) throw const FormatException();
      return SesionUsuario.fromJson(json);
    } on FormatException {
      await borrar();
      return null;
    } on TypeError {
      await borrar();
      return null;
    }
  }

  Future<void> guardar(SesionUsuario sesion) =>
      _secureStorage.write(key: _key, value: jsonEncode(sesion.toJson()));

  Future<void> borrar() => _secureStorage.delete(key: _key);
}
