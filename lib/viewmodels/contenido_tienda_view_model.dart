import 'package:flutter/foundation.dart';

import '../models/contenido_tienda.dart';
import '../models/ui_state.dart';
import '../network/api_service.dart';
import '../repositories/contenido_tienda_repository.dart';

class ContenidoTiendaViewModel extends ChangeNotifier {
  ContenidoTiendaViewModel(this._repository);
  final ContenidoTiendaRepository _repository;
  UiState<ContenidoTienda> state = UiState.initial();
  bool desdeCache = false;
  ContenidoTienda? get contenido => state.data;
  String? get error => state.hasError ? state.message : null;
  bool get cargando => state.isLoading;

  Future<void> cargar() async {
    if (cargando) return;
    state = UiState.loading(previous: contenido);
    notifyListeners();
    try {
      final resultado = await _repository.cargar();
      desdeCache = resultado.desdeCache;
      state = UiState.success(resultado.contenido);
    } catch (e) {
      state = UiState.error(
        e is ApiException
            ? e.message
            : 'No se pudo cargar el contenido de la tienda.',
        previous: contenido,
      );
    } finally {
      notifyListeners();
    }
  }
}
