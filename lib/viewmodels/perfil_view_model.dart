import 'package:flutter/foundation.dart';

import '../models/perfil_usuario.dart';
import '../network/api_service.dart';
import '../repositories/perfil_repository.dart';

class PerfilViewModel extends ChangeNotifier {
  PerfilViewModel(this._repository);
  final PerfilRepository _repository;
  PerfilUsuario? perfil;
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    if (cargando) return;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      perfil = await _repository.cargar();
    } catch (e) {
      error = e is ApiException ? e.message : 'No se pudo cargar tu perfil.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
