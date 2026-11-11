import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../models/ui_state.dart';
import '../network/api_service.dart';
import '../repositories/catalogo_repository.dart';

class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel(CatalogoRepository repository) : _repository = repository;

  final CatalogoRepository _repository;
  UiState<List<Producto>> state = UiState.initial();
  bool desdeCache = false;

  List<Producto> get productos => state.data ?? const [];
  bool get cargando => state.isLoading;
  bool get cargado => state.isSuccess || state.isEmpty;
  String? get error => state.hasError ? state.message : null;

  Future<void> cargar() async {
    if (state.isLoading) return;
    state = UiState.loading(previous: state.data);
    notifyListeners();
    try {
      final resultado = await _repository.cargarProductos();
      desdeCache = resultado.desdeCache;
      state = resultado.productos.isEmpty
          ? UiState.empty(resultado.productos)
          : UiState.success(resultado.productos);
    } on ApiException catch (exception) {
      state = UiState.error(exception.message, previous: state.data);
    } catch (_) {
      state = UiState.error(
        'No se pudo cargar el catálogo. Revisa la conexión y reintenta.',
        previous: state.data,
      );
    } finally {
      notifyListeners();
    }
  }
}
