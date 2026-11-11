import 'package:flutter/foundation.dart';

import '../models/perfil_usuario.dart';
import '../models/ui_state.dart';
import '../network/api_service.dart';
import '../repositories/perfil_repository.dart';

class PerfilViewModel extends ChangeNotifier {
  PerfilViewModel(this._repository);
  final PerfilRepository _repository;
  UiState<PerfilUsuario> state = UiState.initial();
  PerfilUsuario? get perfil => state.data;
  bool get cargando => state.isLoading;
  String? get error => state.hasError ? state.message : null;

  Future<void> cargar() async {
    if (cargando) return;
    state = UiState.loading(previous: perfil);
    notifyListeners();
    try {
      state = UiState.success(await _repository.cargar());
    } catch (e) {
      state = UiState.error(
        e is ApiException ? e.message : 'No se pudo cargar tu perfil.',
        previous: perfil,
      );
    } finally {
      notifyListeners();
    }
  }
}
