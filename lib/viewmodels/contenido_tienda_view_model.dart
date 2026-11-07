import 'package:flutter/foundation.dart';

import '../models/contenido_tienda.dart';
import '../network/api_service.dart';
import '../repositories/contenido_tienda_repository.dart';

class ContenidoTiendaViewModel extends ChangeNotifier {
  ContenidoTiendaViewModel(this._repository);
  final ContenidoTiendaRepository _repository;
  ContenidoTienda? contenido;
  String? error;
  bool cargando = false;

  Future<void> cargar() async {
    if (cargando) return;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      contenido = await _repository.cargar();
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'No se pudo cargar el contenido de la tienda.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
